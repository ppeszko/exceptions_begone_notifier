module ExceptionsBegone
  class Formatter
    class << self
      def format_data(category, notification)
        notification.symbolize_keys!
        notification.merge!(:category => category)
        serialized_notification = serialize_data(notification)
        to_json(serialized_notification)
      end
      
      def format_exception_data(exception, controller, request)
        { :identifier => generate_identifier(controller, exception),
          :payload => {
            :parameters => filter_parameters(request.parameters), 
            :url => request.url,
            :ip => request.ip,
            :request_environment => request.env,
            :session => request.session, 
            :environment => ENV.to_hash,
            :backtrace => exception.backtrace 
          }
        }
      end
      
      def filter_parameters(parameters = {})
        parameters = parameters.dup
        ConnectionConfigurator.global_connection.filters.each do |filter|
          parameters[filter] = "[FILTERED]"
        end
        parameters
      end
      
      def generate_identifier(controller, exception)
        "#{controller.controller_name}##{controller.action_name} (#{exception.class}) #{exception.message.inspect}"
      end
  
      def serialize_data(data)
        case data
        when String
          data
        when Hash
          data.inject({}) do |result, (key, value)|
            result.update(key => serialize_data(value))
          end
        when Array
          data.map do |elem|
            serialize_data(elem)
          end
        else
          data.to_s
        end
      end
  
      def to_json(attributes)
        ActiveSupport::JSON.encode(:notification => attributes)
      end
    end
  end
end