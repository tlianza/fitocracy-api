require 'sinatra'
require 'mechanize'
require 'json'
require 'pry'
require 'csv'
require_relative 'models/user'
require_relative 'page_models/login'
require_relative 'lib/fitocracy/activity'

set :sessions, true
set :session_secret, 'change_me'

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
  @user  = User.new({ agent: @agent, username:session[:username], password:session[:password]})

  halt(401, @user.error) if @user.error

  login_model     = ::PageModels::Login.new(@agent, @user)
  login_response  = login_model.login
  login_json      = JSON.parse(login_response.body)

  halt(401, login_json['error']) unless login_json['success']

  @user.x_fitocracy_user  = login_response["X-Fitocracy-User"]
  #logger.info("x_fitocracy_user: #{@user.x_fitocracy_user}")
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

get '/charts' do
  File.read(File.join('public', 'charts.html'))
end