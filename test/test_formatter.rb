require 'test_helper'
require 'action_controller'

class TestFormatter < Test::Unit::TestCase
  def test_serialize_data
    object = Object.new
    nested_object = Object.new
    object_in_array = Object.new
    notification = {:string => "", :hash => {}, :array => [object_in_array], :object => object, :nested => {:nested_object => nested_object}}
      
    object.expects(:to_s).returns("object")
    nested_object.expects(:to_s).returns("nested_object")
    object_in_array.expects(:to_s).returns("object_in_array")
    
    serialize_data = ExceptionsBegone::Formatter.serialize_data(notification)
    assert_equal "object", serialize_data[:object]
    assert_equal "nested_object", serialize_data[:nested][:nested_object]
    assert_equal ["object_in_array"], serialize_data[:array]
  end
  
  def test_all_data_should_be_serialized
    ExceptionsBegone::Formatter.expects(:serialize_data).returns("")
        
    ExceptionsBegone::Formatter.format_data("test_category", :payload => {})
  end
end 

class TestFormattingExceptionsData < Test::Unit::TestCase
  
  def setup
    @exception = Exception.new("some exception")
    @controller = ActionController::Base.new
    request = stub(:parameters => "", 
                          :url => "http://www.example.com", 
                           :ip => "127.0.0.1",
                          :env => ENV.to_hash,
                      :session => "")
    @controller.stubs(:request).returns(request)
  end
  
  def test_generate_identifier
    assert_equal "#{@controller.controller_name}##{@controller.action_name} (#{@exception.class}) #{@exception.message.inspect}", ExceptionsBegone::Formatter.generate_identifier(@controller, @exception)
  end
  
  def test_format_exception_data_should_automatically_set_identifier
    identifier = ExceptionsBegone::Formatter.format_exception_data(@exception, @controller, @controller.request)[:identifier]
    
    assert_match(/#{@controller.controller_name}/, identifier)
    assert_match(/#{@controller.action_name}/, identifier)
    assert_match(/#{@exception.class}/, identifier)
    assert_match(/#{@exception.message.inspect}/, identifier)
  end
  
  def test_format_exception_data_should_automatically_set_payload
    payload = ExceptionsBegone::Formatter.format_exception_data(@exception, @controller, @controller.request)[:payload]

    assert_equal(@controller.request.session, payload[:session])
    assert_equal(@exception.backtrace, payload[:backtrace])
    assert_equal(ENV.to_hash, payload[:environment])
  end
  
  def test_should_filter_parameters_as_specified
    parameters = {:login => "login", :password => "secret"}
    ExceptionsBegone::ConnectionConfigurator.global_connection.filters = [:password]
    request = stub_everything(:parameters => parameters)
    
    filtered_parameters = ExceptionsBegone::Formatter.format_exception_data(Exception.new, ActionController::Base.new, request)[:payload][:parameters]
    assert_equal parameters[:login], filtered_parameters[:login]
    assert_not_equal parameters[:password], filtered_parameters[:password]
  end
end
