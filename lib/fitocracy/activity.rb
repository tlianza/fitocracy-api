module Fitocracy
  class Activity
    def initialize(hash={})
      @id            = hash[:id]
      @user          = hash[:user]
      @agent         = hash[:agent]
      @activity_name = hash[:activity_name]
    end

    def get_all_activities_for_user
      @activities ||= @agent.get(Paths.activities_uri(@user.x_fitocracy_user))
    end

    def get_activity_data
      @activity = JSON.parse(@activities.body) \
                      .detect {|activity| activity["name"] == @activity_name}

      @id = @activity['id']
      @activity
    end

    def activity_log
      if @id.nil?
        get_all_activities_for_user
        get_activity_data
      end

      @agent.get(::Fitocracy::Paths.activity_history_uri(@id))
    end
  end
end