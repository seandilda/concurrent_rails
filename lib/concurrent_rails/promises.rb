# frozen_string_literal: true

require 'concurrent_rails/adapters/future'
require 'concurrent_rails/adapters/delay'

module ConcurrentRails
  class Promises
    include Concurrent::Promises::FactoryMethods
    include ConcurrentRails::Adapters::Delay
    include ConcurrentRails::Adapters::Future

    def initialize(executor)
      @executor = executor
    end

    %i[value value!].each do |method_name|
      define_method(method_name) do |timeout = nil, timeout_value = nil|
        permit_concurrent_loads do
          instance.__send__(method_name, timeout, timeout_value)
        end
      end
    end

    %i[then chain].each do |chainable|
      define_method(chainable) do |*args, &task|
        method = "#{chainable}_on"
        @instance = rails_wrapped do
          instance.__send__(method, executor, *args, &task)
        end

        self
      end
    end

    %i[on_fulfillment on_rejection on_resolution].each do |method|
      define_method(method) do |*args, &callback_task|
        rails_wrapped do
          @instance = instance.__send__("#{method}_using", executor, *args, &callback_task)
        end

        self
      end

      define_method("#{method}!") do |*args, &callback_task|
        rails_wrapped do
          @instance = instance.__send__(:add_callback, "callback_#{method}", args, callback_task)
        end

        self
      end
    end

    delegate :state, :reason, :rejected?, :resolved?, :fulfilled?, :wait,
             to: :instance

    private

    def rails_wrapped(&block)
      Rails.application.executor.wrap(&block)
    end

    def permit_concurrent_loads(&block)
      rails_wrapped do
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads(&block)
      end
    end

    attr_reader :executor, :instance
  end
end
