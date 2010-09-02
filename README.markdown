Twilio Contactable
=====

Twilio makes voice and SMS interactions easy. But if you want to ensure that your user's phone numbers really belong
to them there's a lot of buggy code you'll have to add in your Ruby app. Unless you use this gem.

Don't Write Twilio Ruby Code Like It's PHP
==

You don't want to be passing strings around between multiple web requests and writing procedural code in your Ruby app. Not for such a simple feature. This gem lets you ask for a phone number from your users (or any ActiveRecord-like Ruby class), confirm their ownership of it via SMS or Voice (or both), and automatically handle number invalidation.


Install It
==

Install TwilioContactable as a gem:

    $ gem install twilio_contactable
    
    # For Rails add it in environment.rb:
    config.gem 'twilio_contactable'

    # then edit your .gems file or run
    $ rake gems:unpack
    # to unpack the gem into your vendor/gems directory

Or as a Plugin:

    ruby script/plugin install git://github.com/JackDanger/twilio_contactable.git


Connect This Code To Your App
==


Include Twilio::Contactable into your User class or whatever you're using to represent an entity with a contactable phone number.

    class User < ActiveRecord::Base

      include TwilioContactable::Contactable

      twilio_contactable

    end

If you're using custom column names you can easily overwrite any of them by passing in a configuration block:

    class User < ActiveRecord::Base

      include TwilioContactable::Contactable

      twilio_contactable do |config|
        config.phone_number_column                  = :mobile_number
        config.formatted_phone_number_column        = :formatted_mobile_number
        config.sms_blocked_column                   = :should_we_not_txt_this_user
        config.sms_confirmation_code_column         = :the_sms_confirmation_code
        config.sms_confirmation_attempted_column    = :when_was_the_sms_confirmation_attempted
        config.sms_confirmed_phone_number_column    = :the_mobile_number_thats_been_confirmed_for_sms
        config.voice_blocked_column                 = :should_we_not_call_this_user
        config.voice_confirmation_code_column       = :the_voice_confirmation_code
        config.voice_confirmation_attempted_column  = :when_was_the_voice_confirmation_attempted
        config.voice_confirmed_phone_number_column  = :the_mobile_number_thats_been_confirmed_for_voice
        # Defaults to the name on the left (minus the '_column' at the end)
        # e.g., the sms_blocked_column is 'sms_blocked'
        #
        # You don't need all those columns, omit any that you're sure you won't want.
      end
    end


You'll need to add those columns to your database table using a migration that looks something like this:

    change_table :users do |t|
      t.string    :phone_number
      t.string    :formatted_phone_number
      t.boolean   :sms_blocked, :default => false, :null => false
      t.string    :sms_confirmation_code
      t.datetime  :sms_confirmation_attempted
      t.string    :sms_confirmed_phone_number
      t.boolean   :voice_blocked, :default => false, :null => false
      t.string    :voice_confirmation_code
      t.datetime  :voice_confirmation_attempted
      t.string    :voice_confirmed_phone_number
    end

You don't necessarily need all those columns though. Say you have users that want to use SMS and business locations that
just need to have their retail phone number to confirm their identity:

    change_table :users do |t|
      t.string    :phone_number
      t.string    :formatted_phone_number
      t.boolean   :sms_blocked, :default => false, :null => false
      t.string    :sms_confirmation_code
      t.datetime  :sms_confirmation_attempted
      t.string    :sms_confirmed_phone_number
    end
    change_table :business_locations do |t|
      t.string    :phone_number
      t.string    :formatted_phone_number
      t.boolean   :voice_blocked, :default => false, :null => false
      t.string    :voice_confirmation_code
      t.datetime  :voice_confirmation_attempted
      t.string    :voice_confirmed_phone_number
    end

Both the User and the BusinessLocation models are now prepared for SMS and Voice confirmation, respectively.

You'll also need to create a controller that is capable of receiving connections from Twilio.com. You can reuse an existing controller or
create a new one just for this task. TwilioContactable will guess the path from the controller name, so if you include it into a class called CheckPhoneNumbersController:

    # app/controllers/check_phone_numbers_controller.rb
    class CheckPhoneNumbersController < ActionController::Base
      include TwilioContactable::Controller

      # any models that you want to have phone numbers confirmed for:
      twilio_contactable User, BusinessLocation
    end

then Twilio.com would try to contact your site at '/check_phone_numbers'. As long as that route works then you don't need to configure anything else.

Configure It With Your Twilio Account Info
==

Because it can be expensive to send TXTs or make calls accidentally, it's required that you manually set TwilioContactable.mode in your app. Put this line in config/environments/production.rb or anything that loads _only_ in your production environment:

    TwilioContactable.mode = :live

Skipping this step (or adding any other value) will prevent TXTs or phone calls from actually being sent.

You'll need to add a few pieces of important information. Create a file like the following in config/initializers/

    # config/initializers/twilio_contactable.rb
    TwilioContactable.configure do |config|

      # Your Twilio Account Number
      config.client_id  = 12345
      # Your Twilio Account Secret Code
      config.client_key = 'ABC123'
      # Twilio.com needs to be able to find your site. Add your
      # complete Ruby app internet address here:
      config.website_address = 'http://myrubyapp.com'
      # And, finally, the Twilio-hosted phone number
      # that you'd like all your calls/txts to come from:
      config.default_from_phone_number = '(206) 555-1234'

    end

Confirming Phone Number For SMS And Sending TXTs
==

When your users first hand you their number it will be unconfirmed:

    @user = User.create(:phone_number => '555-222-3333')
    @user.send_sms_confirmation! # fires off a TXT to the user with a generated confirmation code
    @user.sms_confirmed?         # => false, because we've only started the process

The user will read the SMS confirmation code off of their phone and type it into a form on your site (you'll need to build this). When they submit that code to a controller you should pass it in to the user record's sms_confirm_with method:

    # params[:code] => '123XYZ'
    @user.sms_confirm_with(params[:code])

If the code is correct then the user's current phone number will be automatically marked as confirmed. You can check this at any time with:

    @user.sms_confirmed? # => true
    @user.send_sms!("Hi! This is a text message.")

If the code is wrong then the user's current phone number will stay unconfirmed.

    @user.sms_confirmed? # => false
    @user.send_sms!("Hi! This is a text message.") # sends nothing


Confirming Phone Number For Voice
==

Confirming for Voice is different from confirming for SMS because the user will read the code off your site and enter their Voice confirmation code into the keypad of their phone.

    @user = User.create(:phone_number => '555-222-3333')
    @user.send_voice_confirmation! # Initiates phone call to user
    @user.voice_confirmed?         # false

Right after send_voice_confirmation! is called you'll want to display the confirmation code to the user. It's up to you how to do this but you'll probably want to have a screen that shows something like this:

    <h1>We're calling you on the phone right now!</h1>
    <p>
      When you answer the phone, please type in these numbers:
      <%= @user.voice_confirmation_code %>
    <p>
    <%= link_to "Okay, I've finished the phone call", '/' %>

While you display this screen the user will have inputted their voice_confirmation_code to their phone, Twilio.com will have posted that code to your server (defined in config.website_address), and your user will have been updated so that @user.voice_confirmed? is now true!
If the code is entered incorrectly then the user's current phone number will stay unconfirmed. You'll need to start over and have them enter the code again.

Receiving TXTs and Voice calls
====

You can also receive data posted to you from Twilio. This is how you'll receive messages, txts and notices that users have been blocked.
All you need is to create a bare controller and include TwilioContactable::Controller into it. Then specify which Ruby class you're using as a contactable user model (likely User)


    class TwilioContactableController < ApplicationController

      include TwilioContactable::Controller

      twilio_contactable User # or whichever class you included TwilioContactable::Contactable into
    end

Make sure Twilio.com knows to POST all SMS messages and block notices to you at:

    http://myrubyapp.com/twilio_contactable/receive_sms_message

This gem will handle all those incoming messages automatically. Now if your users reply to an SMS with 'STOP' or 'BLOCK' the appropriate record in your database will be updated so that sms messages no longer can be sent to them (i.e.: @user.sms_blocked? will be true)

All other incoming TXTs (besides 'BLOCK' and 'STOP') from a user will automatically be sent to that user's record:

   # If "I love you!" is sent to you from a user with
   # the phone number "555-111-9999"
   # then the following will be executed:
   User.find_by_formatted_phone_number('+15551119999').receive_sms("I love you!")

It's up to you to implement the 'receive_sms' method on User.

That's it. Patches welcome, forks celebrated.

Copyright (c) 2010 [Jack Danger Canty](http://jåck.com/), released under the MIT license
