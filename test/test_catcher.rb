require 'test_helper'
require 'action_controller'
require 'net/http'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

class TestCatchingExceptions < ActionController::TestCase

  class CatchingExceptionsController < ActionController::Base
    CatchingExceptionsController.consider_all_requests_local = false

    def action_with_exception
      raise "Exception from #{self.class.name}"
    end

    ExceptionsBegone::Catcher.catch_exceptions
  end
    
  tests CatchingExceptionsController
  def setup
    @request.remote_addr = '1.2.3.4'
    @request.host = 'example.com'
  end
  
  def test_should_catch_all_exceptions_from_controller
    CatchingExceptionsController.any_instance.expects(:rescue_action_in_public)

    get :action_with_exception
  end  
  
  def test_should_send_the_exception
    ExceptionsBegone::Sender.expects(:send_generic).with("exception", anything, anything)
    CatchingExceptionsController.any_instance.expects(:rescue_action_in_public_without_catcher)
    
    get :action_with_exception
  end
end

class TestConfiguringCatcher < ActionController::TestCase
  class ConfiguringExceptionsController < ActionController::Base
    ConfiguringExceptionsController.consider_all_requests_local = false

    def action_with_exception
      raise "Exception from #{self.class.name}"
    end

    ExceptionsBegone::Catcher.catch_exceptions do |catcher|
      catcher.project = "test_configuration_project"
      catcher.host = "my_host"
      catcher.port = 987
    end
  end
  
  tests ConfiguringExceptionsController
  def test_should_send_exceptions_to_chosen_service
    ExceptionsBegone::Sender.stubs(:log)
    @request.remote_addr = '1.2.3.4'
    @request.host = 'my_host'
    
    notification = {:status => "ok"}
    parameters = {:port => 987, :host => "my_host", :project => "test_configuration_project"}
    net_http = Net::HTTP.new(parameters[:host], parameters[:port])
    
    Net::HTTP.expects(:new).with(parameters[:host], parameters[:port]).returns(net_http)
    Net::HTTP.any_instance.expects(:post).with("/projects/#{parameters[:project]}/notifications", anything, anything)
    ConfiguringExceptionsController.any_instance.expects(:rescue_action_in_public_without_catcher)
    
    get :action_with_exception
  end
end
  