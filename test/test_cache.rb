require 'test_helper'

module Rails
end

class TestCachingInterface < Test::Unit::TestCase

  class ExceptionsBegone::TestSender
    class << self
      def send_exception(exception, controller, request, connection_options = {})
      end
    end
  end

  ExceptionsBegone::TestSender.extend ExceptionsBegone::Cache
  
  def setup
    @cache = stub("cache")
    Rails.stubs(:cache).returns(@cache)
    @exception = Exception.new
    @exception.stubs(:backtrace).returns([])
    @hashed_backtrace = Digest::MD5.hexdigest(@exception.backtrace.join.to_s)
  end
    
  def test_cache_should_be_enabled_after_including
    ExceptionsBegone::TestSender.expects(:skip_sending?).returns(true)
    
    ExceptionsBegone::TestSender.send_exception(@exception, "controller", "request")
  end
  
  def test_should_send_exception_on_new_exception_if_the_hourly_limit_is_not_reached
    ExceptionsBegone::TestSender.expects(:signature_equal?).with(@hashed_backtrace).returns(false)
    ExceptionsBegone::TestSender.expects(:hourly_send_limit_reached?).returns(false)
    
    ExceptionsBegone::TestSender.expects(:save_signature_in_cache).with(@hashed_backtrace)
    ExceptionsBegone::TestSender.expects(:send_exception_without_cache).with(@exception, "controller", "request", {})
    ExceptionsBegone::TestSender.send_exception(@exception, "controller", "request")
  end
  
  def test_should_not_send_exception_on_new_exception_if_the_hourly_limit_is_reached
    ExceptionsBegone::TestSender.expects(:signature_equal?).with(@hashed_backtrace).returns(false)
    ExceptionsBegone::TestSender.expects(:hourly_send_limit_reached?).returns(true)
    
    ExceptionsBegone::TestSender.expects(:save_signature_in_cache).never
    ExceptionsBegone::TestSender.expects(:send_exception_without_cache).never
    ExceptionsBegone::TestSender.send_exception(@exception, "controller", "request")
  end
end