Twilo Contactable
=====

Twilo makes voice and SMS interactions easy. But if you want to be able to seamlessly validate your user's phone numbers for
both voice and text there's a lot of work you'll have to do in your Rails app. Unless you use this gem.

Why bother?
=====

Unless you're programming Ruby like it's PHP you don't enjoy passing strings around and writing all procedural code. This gem lets you
ask for a phone number from your users, confirm their ownership of it via SMS or Voice or both, and keep track of whether the number is
still validated when they edit it.


Setting Up Your Model
=====

Include Twilio::Contactable into your User class or whatever you're using to represent an entity with a phone number. 

    class User < ActiveRecord::Base
      twilio_contactable
    end

You can also specify which attributes you'd like to use instead of the defaults

    class User < ActiveRecord::Base
      twilio_contactable do |config|
        config.phone_number_column                  :mobile_number
        config.formatted_phone_number_column        :formatted_mobile_number
        config.sms_blocked_column                   :should_we_not_txt_this_user
        config.sms_confirmation_code_column         :the_sms_confirmation_code
        config.sms_confirmation_attempted_column    :when_was_the_sms_confirmation_attempted
        config.sms_confirmed_phone_number_column    :the_mobile_number_thats_been_confirmed_for_sms
        config.voice_blocked_column                 :should_we_not_call_this_user
        config.voice_confirmation_code_column       :the_voice_confirmation_code
        config.voice_confirmation_attempted_column  :when_was_the_voice_confirmation_attempted
        config.voice_confirmed_phone_number_column  :the_mobile_number_thats_been_confirmed_for_voice

      # Defaults to the name on the left (minus the '_column' at the end)
      # e.g., the sms_blocked_column is 'sms_blocked'
      #
      # You don't need all those columns, omit any that you're sure you won't want.
    end

Turning the thing on
---

Because it can be expensive to send TXTs or make calls accidentally, it's required that you manually configure TwilioContactable in your app. Put this line in config/environments/production.rb or anything that loads _only_ in your production environment:

    TwilioContactable.mode = :live

Skipping this step (or adding any other value) will prevent TXTs from actually being sent.

You'll also want to configure your setup with your client_id and client_key. Put this in the same file as above or in a separate initializer if you wish:

    TwilioContactable.configure do |config|
      # these three are required:
      # (replace them with your actual account info)
      config.client_id = 12345
      config.client_key = 'ABC123'
      config.website_address = 'http://myrubyapp.com' # <- Twilio.com needs to be able to find this

      # the rest are optional:
      config.short_code     = 00001 # if you have a custom short code
      config.proxy_address  = 'my.proxy.com'
      config.proxy_port     = '80'
      config.proxy_username = 'user'
      config.proxy_password = 'password'
    end

Phone number formatting
---

Whatever is stored in the phone_number_column will be subject to normalized formatting:

    user = User.create :phone_number => '(206) 555-1234'
    user.phone_number # => (206) 555-1234
    user.formatted_phone_number # => 12065551234 (defaults to US country code)

If you want to preserve the format of the number exactly as the user entered it you'll want
to save that in a different attribute.


Confirming Phone Number And Sending Messages
====

When your users first hand you their number it will be unconfirmed:

    @user = User.create(:phone_number => '555-222-3333')
    @user.send_sms_confirmation! # fires off a TXT to the user with a generated confirmation code
    @user.sms_confirmed?         # => false, because we've only started the process

then ask the user for the confirmation code off their phone and pass it in to sms_confirm_with:

    @user.sms_confirm_with('123XYZ')

If the code is right then the user's current phone number will be automatically marked as confirmed. You can check this at any time with:

    @user.sms_confirmed? # => true
    @user.send_sms!("Hi! This is a text message.")

If the code is wrong then the user's current phone number will stay unconfirmed.

    @user.sms_confirmed? # => false
    @user.send_sms!("Hi! This is a text message.") # sends nothing


Receiving TXTs and Voice calls
====

You can also receive data posted to you from Twilio. This is how you'll receive messages, txts and notices that users have been blocked.
All you need is to create a bare controller and include TwilioContactable::Controller into it. Then specify which Ruby class you're using as a contactable user model (likely User)


    class SMSController < ApplicationController
      include TwilioContactable::Controller

      sms_contactable User # or whichever class you included TwilioContactable::Contactable into
    end

And hook this up in your routes.rb file like so:

    ActionController::Routing::Routes.draw do |map|
      map.route 'twilio', :controller => 'twilio_contactable', :action => :index
    end

Now just tell Twilio to POST messages and block notices to you at:

    http://myrubyapp.com/twilio

Now if your users reply to an SMS with 'STOP' or 'BLOCK' your database will be automatically updated to reflect this.

Incoming messages from a user will automatically be sent to that user's record:

   # If "I love you!" is sent to you from a user with
   # the phone number "555-111-9999"
   # then the following will be executed:
   User.find_by_phone_number('5551119999').receive_sms("I love you!")

It's up to you to implement the 'receive_sms' method on User.

That's it. Patches welcome, forks celebrated.

Copyright (c) 2010 [Jack Danger Canty](http://jåck.com/), released under the MIT license
