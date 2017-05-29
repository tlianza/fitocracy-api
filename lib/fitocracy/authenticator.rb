module Fitocracy
  class Authenticator

    def initialize(user)
      @user = user
    end

    def auth()
      login_model     = ::PageModels::Login.new(@user.agent, @user)
      login_response  = login_model.login
      login_json      = JSON.parse(login_response.body)

      unless login_json['success']
        @user.error = login_json['error']
        return @user
      end

      @user.x_fitocracy_user  = login_response["X-Fitocracy-User"]
      return @user
    end
  end
end