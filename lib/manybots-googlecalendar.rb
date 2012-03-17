require "manybots-googlecalendar/engine"

module ManybotsGooglecalendar
  # Google App Id for OAuth2
  mattr_accessor :google_app_id
  @@google_app_id = nil

  # Google App Secret for OAuth2
  mattr_accessor :google_app_secret
  @@google_app_secret = nil
  
  mattr_accessor :app
  @@app = nil
  
  mattr_accessor :nickname
  @@nickname = nil
  
  
  def self.setup
    yield self
  end
end
