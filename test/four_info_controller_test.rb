require File.join(File.dirname(__FILE__), 'test_helper')
require 'action_pack'
require 'action_controller'
require 'shoulda/action_controller'
require 'shoulda/action_controller/macros'
require 'shoulda/action_controller/matchers'

class FourInfoController < ActionController::Base
  include FourInfo::Controller
end
ActionController::Routing::Routes.draw do |map|
  map.route '*:url', :controller => 'four_info', :action => :index
end

class FourInfoControllerTest < ActionController::TestCase
  include Shoulda::ActionController
  context "receiving BLOCK" do
    setup {
      post :index,
      "request"=>{"block"=>{"recipient"=>{"property"=>{"name"=>"CARRIER", "value"=>"3"}, "id"=>"+5553334444", "type"=>"5"}}}
    }
    should_respond_with :success
  end
end
