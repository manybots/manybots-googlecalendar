class GoogleCalendarWorker
  require 'google/api_client'
  @queue = :observers
  
  attr_accessor :client, :account
  
  def initialize(oauth_account_id)
    @account = OauthAccount.find(oauth_account_id)
    @client = Google::APIClient.new
    @client.authorization.client_id = ManybotsGooglecalendar.google_app_id
    @client.authorization.client_secret = ManybotsGooglecalendar.google_app_secret
    @client.authorization.scope = 'https://www.googleapis.com/auth/calendar.readonly'
    @client.authorization.refresh_token = @account.payload[:refresh_token]
    @client.authorization.access_token =  @account.token
    @client.authorization.redirect_uri = 'http://localhost:5000/manybots-googlecalendar/calendar/callback'
    if @client.authorization.refresh_token && @client.authorization.expired?
      @client.authorization.fetch_access_token!
    end
    
    @account.token = @client.authorization.access_token
    @account.payload[:refresh_token] = @client.authorization.refresh_token
    @account.payload[:expires_in] = @client.authorization.expires_in
    @account.payload[:issued_at] = @client.authorization.issued_at
    @account.save
    
    @client
  end
  
  def self.perform(oauth_account_id)
    worker = self.new(oauth_account_id)
    service = worker.client.discovered_api('calendar', 'v3')
    page_token = nil
    result = result = worker.client.execute(:api_method => service.events.list, :parameters => {'calendarId' => 'primary'})
    puts result.data.items.length
    loop do
      events = result.data.items
      events.each do |e|
        if e and not ManybotsGooglecalendar::Event.exists?(oauth_account_id: worker.account.id, remote_id: e.id)
          event = ManybotsGooglecalendar::Event.new_from_google_event(e, worker.account.id)
          event.save
          begin
            event.post_to_manybots!
          rescue => e
            puts "Error posting to Manybots: #{e}"
          end
        end
      end
      if !(page_token = result.data.next_page_token)
        break
      end
      result = result = client.execute(:api_method => service.events.list,
                                       :parameters => {'calendarId' => 'primary', 'pageToken' => page_token})
    end
  end
  
end


