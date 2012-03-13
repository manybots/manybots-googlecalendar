module ManybotsGooglecalendar
  class CalendarController < ApplicationController
    require 'oauth2'
    
    before_filter :authenticate_user!
    layout 'shared/application'
    
    def index
      @calendars = current_user.oauth_accounts.where(:client_application_id => current_app.id)
      @schedules = ManybotsServer.queue.get_schedules
    end
    
    def new
      consumer = get_consumer
      # redirect_to consumer.authorization.authorization_uri.to_s
      redirect_to consumer.auth_code.authorize_url(:redirect_uri => callback_calendar_index_url,
      :scope => 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/calendar.readonly')
    end
    
    def import
      calendar = current_user.oauth_accounts.find(params[:id])
      
      schedule_name = "import_manybots_googlecalendar_events_#{calendar.id}"
      schedules = ManybotsServer.queue.get_schedules
      
      message = 'Please try again.'
      
      if schedules and schedules.keys.include?(schedule_name)
        ManybotsServer.queue.remove_schedule schedule_name
        calendar.status = 'off'
        message = 'Stopped importing.'
      else 
        calendar.status = 'on'
        message = 'Started importing.'
        
        ManybotsServer.queue.add_schedule schedule_name, {
          :every => '3h',
          :class => "GoogleCalendarWorker",
          :queue => "observers",
          :args => calendar.id,
          :description => "Update events every 3 hours for OauthAccount ##{calendar.id}"
        }
        
        ManybotsServer.queue.enqueue(GoogleCalendarWorker, calendar.id)
      end
      calendar.save
      
      redirect_to root_path, :notice => message
    end
    
    def callback
      consumer = get_consumer
      token = consumer.auth_code.get_token(params[:code], :redirect_uri => callback_calendar_index_url)
      
      profile_params = token.get('https://www.googleapis.com/userinfo/email?alt=json').body
      profile = JSON.parse profile_params
      
      # profile_params = access_token.get('https://www.googleapis.com/userinfo/email').body
      # profile = Rack::Utils.parse_query(profile_params).with_indifferent_access
      
      
      # consumer = get_consumer
      # consumer.authorization.code = params[:code]
      # consumer.authorization.fetch_access_token!
      
      # @calendar = consumer.discovered_api('calendar', 'v3')
      # profile = consumer.execute(@calendar.events.list, {'calendarId' => 'primary'})
      # puts profile.inspect

      calendar = current_user.oauth_accounts.find_or_create_by_client_application_id_and_remote_account_id(current_app.id, profile['data']['email'])
      calendar.token = token.token
      # calendar.token = consumer.authorization.access_token
      # calendar.payload[:refresh_token] = consumer.authorization.refresh_token
      # calendar.payload[:expires_in] = consumer.authorization.expires_in
      # calendar.payload[:issued_at] = consumer.authorization.issued_at
      calendar.save
      
      redirect_to calendar_index_path, :notice => "Google Calendar account '#{calendar.remote_account_id}' registered."
    end
    
    
    def destroy
      calendar = current_user.oauth_accounts.find(params[:id])
      schedule_name = "import_manybots_googlecalendar_events_#{calendar.id}"
      ManybotsServer.queue.remove_schedule schedule_name
      calendar.destroy
      # ManybotsGooglecalendar::Event.where(:oauth_account_id => calendar.id).destroy_all
      redirect_to calendar_index_path, :notice => 'Account deleted.'
    end
    
    private
    
    def current_app
      @manybots_googlecalendar_app ||= ManybotsGooglecalendar.app
    end
    
    def get_consumer
      @consumer ||= OAuth2::Client.new(ManybotsGooglecalendar.google_app_id, ManybotsGooglecalendar.google_app_secret, 
        :site => "https://accounts.google.com",
        :authorize_url => "/o/oauth2/auth",
        :token_url => "/o/oauth2/token"
      )  
    end
    
  end
end

