module ManybotsGooglecalendar
  class Event < ActiveRecord::Base
    belongs_to :oauth_account
    has_one :user, :through => :oauth_account
    
    serialize :payload
    
    def self.new_from_google_event(google_event, oauth_account_id)
      event = self.new
      event.oauth_account_id = oauth_account_id
      event.remote_id = google_event.id
      event.remote_created_at = google_event.created
      event.remote_updated_at = google_event.updated
      event.payload = google_event.to_hash
      event
    end
    
    def start_date
      if self.payload[:start.to_s][:date.to_s].present?
        a = Date.parse self.payload[:start.to_s][:date.to_s]
      else
        a = Time.parse self.payload[:start.to_s][:dateTime.to_s]
      end
      a
    end
    
    def end_date
      if self.payload[:end.to_s][:date.to_s].present?
        a = Date.parse self.payload[:end.to_s][:date.to_s]
      else
        a = Time.parse self.payload[:end.to_s][:dateTime.to_s]
      end
      a

    end
    
    def slug
      if self.payload[:start.to_s][:date.to_s].present?
        self.payload[:start.to_s][:date.to_s].gsub('-','/')
      else
        Time.parse(self.payload[:start.to_s][:dateTime.to_s]).strftime('%Y/%m/%d')
      end
    end
    
    def is_notification?
      self.payload[:organizer.to_s][:email.to_s] != self.oauth_account.remote_account_id
    end
    
    def as_activity
      # alex scheduled Quarterly Meeting with Blah and Bluh at Location
      # alex attended Quarterly Meeting with Blah and Bluh at Location
      # Sergio invited you (TARGET) to Quarterly Meeting with Bluh at Location
      activity = {}
      activity.merge! self.as_prediction
      activity[:actor] = {
        :objectType => 'person',
        :displayName => self.payload[:organizer.to_s][:displayName.to_s] || self.payload[:organizer.to_s][:email.to_s],
        :id => "#{ManybotsServer.url}/manybots-googlecalendar/people/#{self.payload[:organizer.to_s][:email.to_s]}",
        :url => "#{ManybotsServer.url}/manybots-googlecalendar/people/#{self.payload[:organizer.to_s][:email.to_s]}",
        :email => self.payload[:organizer.to_s][:email.to_s],
        :image => {
          :url => ''
        }
      }
      
      if self.is_notification?
        # this prediction was made by someone else
        activity[:title] = "ACTOR invited you to <a href='#{self.payload[:htmlLink.to_s]}'>#{self.payload[:summary.to_s]}</a> on TARGET"
        activity[:auto_title] = true
        activity[:notification] = {}
        activity[:notification][:type] = "Notification"
        activity[:notification][:level] = "Alert"
      else
        activity[:title] = "ACTOR scheduled <a href='#{self.payload[:htmlLink.to_s]}'>#{self.payload[:summary.to_s]}</a> on TARGET"
        activity[:auto_title] = true
      end
      
      activity
    end
    
    def as_json
      self.as_activity
    end
    
    def as_prediction
      activity = {
        :published => self.remote_created_at,
        :provider => {
          :displayName => 'Google Calendar',
          :url => 'https://calendar.google.com',
          :image => {
            :url => "#{ManybotsServer.url}/assets/manybots-googlecalendar/icon.png"
          }
        },
        :generator => {
          :displayName => 'Google Calendar Observer',
          :url => "#{ManybotsServer.url}/manybots-googlecalendar",
          :image => {
            :url => "#{ManybotsServer.url}/assets/manybots-googlecalendar/icon.png"
          }
        }
      }
      activity[:verb] = 'predict'
      activity[:object] = self.as_event_activity
      activity[:target] = {}
      activity[:target][:displayName] = self.start_date
      activity[:target][:objectType] = 'date'
      activity[:target][:id] = "#{ManybotsServer.url}/calendar/day/" + self.slug
      activity[:target][:url] = "#{ManybotsServer.url}/calendar/day/" + self.slug
      
      activity
    end
        
    def as_event_activity
      # start with common parts
      activity = {
        :id => "#{ManybotsServer.url}/manybots-googlecalendar/events/#{self.id}/activity",
        :url => "#{ManybotsServer.url}/manybots-googlecalendar/events/#{self.id}/activity",
        :objectType => 'activity',
        :published => self.start_date,
        :summary => self.payload[:description.to_s],
        :content => self.payload[:description.to_s],
        :icon => {
          :url => "#{ManybotsServer.url}/assets/manybots-googlecalendar/icon.png"
        },
        :title => "ACTOR attended OBJECT",
        :auto_title => true,
        :verb => 'attend',
        :provider => {
          :displayName => 'Google Calendar',
          :url => 'https://calendar.google.com',
          :image => {
            :url => "#{ManybotsServer.url}/assets/manybots-googlecalendar/icon.png"
          }
        },
        :generator => {
          :displayName => 'Google Calendar Observer',
          :url => "#{ManybotsServer.url}/manybots-googlecalendar",
          :image => {
            :url => "#{ManybotsServer.url}/assets/manybots-googlecalendar/icon.png"
          }
        }
      }
      # add the object (attachments will be added later)
      activity[:object] = {}
      activity[:object][:objectType] = 'event'
      activity[:object][:id] = self.payload[:htmlLink.to_s]
      activity[:object][:url] = self.payload[:htmlLink.to_s]
      activity[:object][:displayName] = self.payload[:summary.to_s]
      [:location, :organizer, :owner, :attendees, :start, :end].each do |what|
        activity[:object][what] = self.payload[what.to_s] if self.payload[what.to_s].present?
      end
      
      activity[:actor] = {
        :displayName => self.oauth_account.remote_account_id,
        :objectType => 'person',
        :email => self.oauth_account.remote_account_id,
        :id => "#{ManybotsServer.url}/manybots-googlecalendar/people/#{self.oauth_account.remote_account_id}",
        :url => "#{ManybotsServer.url}/manybots-googlecalendar/people/#{self.oauth_account.remote_account_id}",
        :image => {
          :url => self.user.avatar_url
        }
        
      }
      activity
    end
    
    def post_to_manybots!
      what = self.is_notification? ? 'notifications' : 'activities'
      
      RestClient.post("#{ManybotsServer.url}/#{what}.json", 
        {
          :activity => self.as_activity, 
          :client_application_id => ManybotsGooglecalendar.app.id,
          :version => '1.0', 
          :auth_token => self.user.authentication_token
        }.to_json, 
        :content_type => :json, 
        :accept => :json
      )
    end    
    
    
  end
end
