4info
=====

Connect to the 4info SMS gateway

If you're using 4info.com as your SMS gateway this gem will give you a painless API for both sending and receiving messages.

Setting Up Your Model
=====

Include FourInfo::Contactable into your User class or whatever you're using to represent an entity with a phone number. 

    class User < ActiveRecord::Base
      include FourInfo::Contactable
    end

You can also specify which attributes you'd like to use instead of the defaults

    class User < ActiveRecord::Base
      include FourInfo::Contactable

      sms_phone_number_column            :mobile_number
      sms_blocked_column                 :is_sms_blocked
      sms_confirmation_code_column       :the_sms_confirmation_code
      sms_confirmation_attempted_column  :when_was_the_sms_confirmation_attempted
      sms_confirmed_phone_number_column  :the_mobile_number_thats_been_confirmed

      # Defaults to the name on the left (minus the '_column' at the end)
    end


Confirming Phone Number And Sending Messages
====

You can manage the user's SMS state like so:

    @user = User.create(:sms_phone_number => '5552223333')
    @user.send_sms_confirmation!

then ask the user for the confirmation code off their phone and pass it in to sms_confirm_with:

    @user.sms_confirm_with(user_provided_code)

If the code is right then the user's current phone number will be automatically marked as confirmed. You can check this at any time with:

    @user.sms_confirmed? # => true
    @user.send_sms!("Hi! This is a text message.")

Then maybe the user will reply with 'BLOCK' by accident and @user.sms_blocked? will be true.
You can fix this by calling:

    @user.unblock_sms!


Receiving Messages From 4info.com
====

You can also receive data posted to you from 4info.com. This is how you'll receive messages and notices that users have been blocked.
All you need is to create a bare controller and include FourInfo::Controller into it. Then specify which Ruby class you're using as a contactable user model (likely User)


    class SMSController < ApplicationController
      include FourInfo::Controller

      sms_contactable User # or whichever class you included FourInfo::Contactable into
    end

And hook this up in your routes.rb file like so:

    ActionController::Routing::Routes.draw do |map|
      map.route '4info', :controller => 'four_info', :action => :index
    end

Now just tell 4info.com to POST messages and block notices to you at:

    http://myrubyapp.com/4info

Now if your users reply to an SMS with 'STOP' your database will be updated to reflect this.

Incoming messages from a user will automatically be sent to that user's record:

   # If "I love you!" is sent to you from a user with the phone
   # number "555-111-9999" then the following will be executed:
   User.find_by_sms_phone_number('5551119999').receive_sms("I love you!")

That's it. Patches welcome, forks celebrated.

Copyright (c) 2010 [Jack Danger Canty](http://jåck.com/), released under the MIT license
