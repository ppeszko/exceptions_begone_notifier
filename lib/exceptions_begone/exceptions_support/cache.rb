require 'digest/md5'

module ExceptionsBegone::Cache
  
  HOURLY_SEND_LIMIT = 500
  TTL = 60
  
  def self.extended(target)
    target.instance_eval do
      class << self 
        alias_method :send_exception_without_cache, :send_exception
        alias_method :send_exception, :send_exception_with_cache
      end
    end
  end

  def send_exception_with_cache(exception, controller, request, connection_options = {})
    exception_signature = Digest::MD5.hexdigest(exception.backtrace.join.to_s)
    return if skip_sending?(exception_signature)

    save_signature_in_cache(exception_signature)
    send_exception_without_cache(exception, controller, request, connection_options = {})
  end

  def skip_sending?(exception_signature)
     signature_equal?(exception_signature) || hourly_send_limit_reached?    
  end

  def signature_equal?(exception_signature)
    Rails.cache.read('last_exception_signature', :raw => true) == exception_signature
  end

  def hourly_send_limit_reached?
    key = "exceptions_sent_in_last_hour.#{Time.now.hour}"
    sent_number = Rails.cache.fetch(key, :expires_in => 1.hour, :raw => true) do
      0
    end
    Rails.cache.increment(key) > HOURLY_SEND_LIMIT
  end

  def save_signature_in_cache(exception_signature)
    Rails.cache.write('last_exception_signature', exception_signature, :expires_in => TTL, :raw => true)
  end
end