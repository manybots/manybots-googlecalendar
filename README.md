# Google Calendar Observer

manybots-googlecalendar is a Manybots Observer that allows you to import your events your Google Calendar events into your local Manybots.

Events in the future will be imported as Predictions, and events that other people invite you too are Notifications (that contain predictions).

## Installation instructions

### Setup the gem

You need the latest version of Manybots Local running on your system. Open your Terminal and `cd` into its' directory.

First, require the gem: edit your `Gemfile`, add the following, and run `bundle install`

```
gem 'manybots-googlecalendar', :git => 'git://github.com/manybots/manybots-googlecalendar.git'
gem 'google-api-client', :require => google/api_client'
```

Second, run the manybots-googlecalendar install generator (mind the underscore):

```
rails g manybots_googlecalendar:install
bundle exec rake db:migrate
```

### Register your Google Calendar Observer with Google

Your Google Calendar Observer uses OAuth to authorize you (and/or your other Manybots Local users) with Google. 

1. Go to this link: https://code.google.com/apis/console#access

2. Create a new project (ex: "My Manybots Google Calendar")

<img src="https://img.skitch.com/20120313-i643txn75c2ncjw4dtu4rhu9.png" />

3. Activate the Calendar API

<img src="https://img.skitch.com/20120313-j2dg3eir6xujcu3y3xkd4ydx2g.png" />

4. Create an Oauth 2 Client

<img src="https://img.skitch.com/20120313-x8yp2241bhthrwjtxege9abdpn.png"/>

<img src="https://img.skitch.com/20120322-x8x3ykic2cewjwttynxt368j7g.png"/>

<img src="https://img.skitch.com/20120313-re8enpenygw2d91tjqmcfqpsei.png" />

<img src="https://img.skitch.com/20120313-d2n5t653yy1ntt3tkn7uxu5cni.png" />

<img src="https://img.skitch.com/20120313-ey773pi16u72ictdg2pp72unkw.png" />


5. Copy the Client ID and Secret into `config/initializers/manybots-googlecalendar.rb`

```
  config.google_app_id = 'Client ID'
  config.google_app_secret = 'Secret'
```


### Restart and go!

Restart your server and you'll see the Google Calendar Observer in your `/apps` catalogue. Go to the app, sign-in to your Google account and start importing your events into Manybots.