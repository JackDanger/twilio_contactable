4info
=====

Connect to the 4info SMS gateway

If you're using 4info.com as your SMS gateway this gem will give you a painless API.

USAGE
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

      # Defaults to the name on the left (minus the word '_column')
    end

You can manage the user's SMS state like so:

    @user = User.create(:sms_phone_number => '5552223333')
    @user.confirm_sms!
    # then ask the user for the confirmation code and
    # compare it to @user.sms_confirmation_code
    # if they're the same, call
    @user.sms_confirmed!
    @user.update_attributes(:sms_confirmed_phone_number => @user.sms_phone_number)
    @user.send_sms!("Hi! This is a text message.")
    # Then maybe the user will reply with 'BLOCK' by accident
    @user.unblock_sms!


There's also a controller module that allows you to super-easily create a controller
that receives data from 4info.com

    class SMSController < ApplicationController
      include FourInfo::Controller

      sms_contactable User # or whichever class you included FourInfo::Contactable into
    end

Now anything posted to the index (or create, if you've hooked this up RESTfully) action
will automatically work. If a user sends 4info.com a message their user record on your site
will (if User has a 'receive_sms' method defined) receive the message directly.

That's it. Patches welcome, forks celebrated.

Copyright (c) 2010 Jack Danger Canty (http://jåck.com/), released under the MIT license
