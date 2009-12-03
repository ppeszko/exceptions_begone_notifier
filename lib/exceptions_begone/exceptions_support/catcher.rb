module ExceptionsBegone
  module Catcher
    def catch_exceptions(&block)
      ActionController::Base.__send__(:include, InstanceMethods)
      parameters = OpenStruct.new
      block.call(parameters) if block_given?
      ConnectionConfigurator.global_parameters = parameters
    end
    module_function :catch_exceptions
        
    module InstanceMethods
      def self.included(target)
        target.send(:alias_method, :rescue_action_in_public_without_catcher, :rescue_action_in_public)
        target.send(:alias_method, :rescue_action_in_public, :rescue_action_in_public_with_catcher)
      end

      def rescue_action_in_public_with_catcher(exception)
        Sender.send_exception(exception, self, request)
        rescue_action_in_public_without_catcher(exception)
      end
    end
  end
end