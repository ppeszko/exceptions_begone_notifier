module ExceptionsBegone
  class Sender
    class << self
      # ugly
      attr_accessor :mailer
      
      def post(data, connection_options = {})
        conn_conf = ConnectionConfigurator.build(connection_options)

        http = Net::HTTP.new(conn_conf.host, conn_conf.port)
        http.read_timeout = conn_conf.read_timeout
        http.open_timeout = conn_conf.open_timeout
      
        log(data)
        http.post(conn_conf.path, data, "Content-type" => "application/json", "Accept" => "application/json")
      rescue TimeoutError, Errno::ECONNREFUSED => e
        log(e.inspect)
        log(data)
        mailer.deliver_error(e.message, "#{e.inspect} #{data}") if mailer
      end
    
      def send_exception(exception, controller, request, connection_options = {})
        notification = Formatter.format_exception_data(exception, controller, request)
        send_generic("exception", notification, connection_options = {})    
      end
          
      def send_generic(category, notification, connection_options = {})
        data = Formatter.format_data(category, notification)
        post(data, connection_options)
      end
      
      def log(message)
        Rails.logger.error("[EXCEPTIONS_BEGONE]: #{message}")
      end
      
      def method_missing(method_name, *args)
        if method_name.to_s =~ /^send_(.*)/
          Sender.__send__(:send_generic, "#{$1}", *args)
        else
          super(method_name, *args)
        end
      end
    end
  end
end