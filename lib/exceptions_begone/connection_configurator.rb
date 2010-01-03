module ExceptionsBegone
  class ConnectionConfigurator
    @@defaults = {
      :project => "production",
      :port => 80,
      :open_timeout => 5,
      :read_timeout => 5,
      :host => "127.0.0.1",
      :filters => []
    }
    
    class << self
      attr_writer :global_connection
      
      def global_connection
        @global_connection ||= ConnectionConfigurator.new
      end
      
      def global_parameters=(parameters = {})
        parameters = parameters.marshal_dump if parameters.respond_to?(:marshal_dump)
        self.global_connection = ConnectionConfigurator.build(parameters)
      end
      
      def build(parameters = {})
        parameters.blank? ? self.global_connection : new(parameters)
      end
      
    end
    
    def initialize(parameters = {})
      parameters.each do |method_name, key|
        self.__send__("#{method_name}=", key)
      end
    end
    
    def path
      "/projects/#{project}/notifications"
    end
    
    def method_missing(method_id, *args, &block)
      method_id.to_s =~ /(\w*)(=)?/
      name, setter = $1, $2
      
      super unless @@defaults.include?(name.to_sym)
      
      if setter
        instance_variable_set("@#{name}", *args)
      else
        instance_variable_get("@#{name}") || @@defaults[method_id]
      end
    end
  end
end