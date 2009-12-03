require 'test_helper'
require 'net/http'

class TestSendingNotifications < Test::Unit::TestCase

  def setup
    ExceptionsBegone::Sender.stubs(:log)
    @notification = { :identifier => "NotificationName", :payload => "payload" }
    @parameters = {:port => 987, :host => "my_host", :project => "my_project"}
  end
  
  def test_should_be_possible_to_send_notification
    Net::HTTP.any_instance.expects(:post).with("/projects/production/notifications", anything, anything)
    
    ExceptionsBegone::Sender.send_notification({:status => "ok"}, :host => "my_host")
  end
  
  def test_should_be_possible_to_specify_parameters_connection_parameters
    @notification = {:status => "ok"}
    @parameters = {:port => 987, :host => "my_host", :project => "my_project"}
    net_http = Net::HTTP.new(@parameters[:host], @parameters[:port])
    
    Net::HTTP.expects(:new).with(@parameters[:host], @parameters[:port]).returns(net_http)
    Net::HTTP.any_instance.expects(:post).with("/projects/#{@parameters[:project]}/notifications", anything, anything)
    
    ExceptionsBegone::Sender.send_notification(@notification, @parameters)
  end
  
  def test_deliver_notfications_as_json
    Net::HTTP.any_instance.expects(:post).with("/projects/#{@parameters[:project]}/notifications", @notification, 'Content-type' => 'application/json', 'Accept' => 'application/json')
    
    ExceptionsBegone::Sender.post(@notification, @parameters)
  end
  
  def test_should_handle_timeouts
    Net::HTTP.any_instance.expects(:post).with("/projects/#{@parameters[:project]}/notifications", @notification, 'Content-type' => 'application/json', 'Accept' => 'application/json').raises(TimeoutError)
    
    assert_nothing_raised do
      ExceptionsBegone::Sender.post(@notification, @parameters)
    end
  end
  
  def test_category_should_be_automatically_generated_from_method_name
    encoded_notification = ActiveSupport::JSON.encode(:notification => {:category => 'warning'}.merge(@notification))
    Net::HTTP.any_instance.expects(:post).with("/projects/#{@parameters[:project]}/notifications", encoded_notification, "Content-type" => "application/json", "Accept" => "application/json")
    
    ExceptionsBegone::Sender.send_warning(@notification, @parameters)
  end  
end