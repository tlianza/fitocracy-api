require 'sinatra'
require 'mechanize'
require 'json'
require 'pry'
require 'csv'
require 'sinatra/sequel'
require_relative 'models/fitocracy_user'
require_relative 'page_models/login'
require_relative 'lib/fitocracy/activity'

require "sinatra/config_file"
config_file 'config.yml'

set :database, "sqlite://#{settings.db['path']}"
require_relative 'models/db'

set :sessions, true
set :session_secret, settings.session_secret

get '/' do
  erb :index
end

get '/login' do
  erb :login
end

post '/login' do
  session[:username] = request.POST['username']
  session[:password] = request.POST['password']
  redirect to("/user/activities")
end

get '/logout' do
  session[:username] = nil
  session[:password] = nil
  redirect to('/login')
end


before '/user/*' do
  @agent = Mechanize.new
  @user  = FitocracyUser.new({ agent: @agent, username:session[:username], password:session[:password]})

  halt(401, @user.error) if @user.error

  login_model     = ::PageModels::Login.new(@agent, @user)
  login_response  = login_model.login
  login_json      = JSON.parse(login_response.body)

  halt(401, login_json['error']) unless login_json['success']

  @user.x_fitocracy_user  = login_response["X-Fitocracy-User"]

  # Store the user info in our db, since they've auth'd
  @db_user = User.first(:username => @user.username)
  if @db_user.nil?
    id = database[:users].insert(:username => @user.username, :fitocracy_id => @user.x_fitocracy_user)
    @db_user = User[id]
  end

end

get '/user/activities' do
  activity = ::Fitocracy::Activity.new(user:  @user, agent: @agent)
  all_activites_data = activity.get_all_activities_for_user

  content_type :json
  JSON.pretty_generate(JSON.parse(all_activites_data.body))
end

get '/user/activity/:activity_name' do
  activity = ::Fitocracy::Activity.new(user:          @user,
                                       agent:         @agent,
                                       activity_name: params[:activity_name])

  activity_data = activity.activity_log

  content_type :json
  JSON.pretty_generate(JSON.parse(activity_data.body))
end

get '/user/activity/:activity_name/export' do
  activity = ::Fitocracy::Activity.new(user: @user, agent: @agent, activity_name: params[:activity_name])
  data = JSON.parse(activity.activity_log.body)

  csv_string = CSV.generate do |csv|
    data.each do |child|
      child['actions'].each do |action|
        csv << [params[:activity_name], child['date'], action['effort1'], action['effort1_unit']['abbr'], action['effort0'], action['effort0_unit']['abbr']]
      end
    end
  end

  content_type 'text/csv'
  csv_string
end

get '/user/activities/sync' do
  activity_call = ::Fitocracy::Activity.new(user:  @user, agent: @agent)
  all_activites_data = JSON.parse(activity_call.get_all_activities_for_user.body)

  updated = 0
  created = 0
  all_activites_data.each do |fitocracy_activity|
    activity_id = 0
    activity = Activity.first(:fitocracy_id => fitocracy_activity['id'])
    if activity.nil?
      activity_id = database[:activities].insert(:fitocracy_id => fitocracy_activity['id'], :name=>fitocracy_activity['name'])
      created += 1
    else
      activity_id = activity.id
    end

    activity_count = UserActivityCount.first(:user_id=>@db_user.id, :activity_id=>activity_id)
    if activity_count.nil?
      database[:user_activity_counts].insert(:user_id=>@db_user.id, :activity_id=>activity_id, :fitocracy_activity_id=>fitocracy_activity['id'], :count=>fitocracy_activity['count'])
      updated += 1
    end

  end

  "Created #{created} and updated #{updated} activities."
end

get '/user/activity_log/sync' do

  records = 0
  @db_user.user_activity_counts_dataset.each do |activity_count|
    logger.info(activity_count)
    fitocracy_activity = ::Fitocracy::Activity.new(user: @user, agent: @agent,  id: activity_count[:fitocracy_activity_id])
    data = JSON.parse(fitocracy_activity.activity_log.body)
    data.each do |child|
      child['actions'].each do |action|
        ua = UserActivity.first(:fitocracy_id=>action['id'])
        if ua.nil?
          database[:user_activities].insert(:user_id=>@db_user.id,
                                            :activity_id=>activity_count[:activity_id],
                                            :fitocracy_id=>action['id'],
                                            :fitocracy_group_id=>action['action_group_id'],
                                            :date=>action['actiontime'],
                                            :reps=>action['effort1'],
                                            :weight=>action['effort1'],
                                            :units=>(action['effort0_unit'].nil? ? nil : action['effort0_unit']['abbr'] )
          )
          records += 1
        end
      end
    end

  end


  "Inserted or updated #{records} records"
end


get '/charts' do
  File.read(File.join('public', 'charts.html'))
end