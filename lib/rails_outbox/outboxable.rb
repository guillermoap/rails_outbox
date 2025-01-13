# frozen_string_literal: true

require 'active_support/concern'
require_relative 'emits'
require_relative 'constants'
require_relative 'outbox_persistence'

module RailsOutbox
  module Outboxable
    extend ActiveSupport::Concern
    include OutboxPersistence

    included do
      extend Emits

      *namespace, klass = name.underscore.upcase.split('/')
      namespace = namespace.reverse.join('.')

      module_parent.const_set('RailsOutbox', Module.new) unless module_parent.const_defined?('RailsOutbox', false)
      unless module_parent::RailsOutbox.const_defined?('Events', false)
        module_parent::RailsOutbox.const_set('Events', Module.new)
      end

      Constants::VALID_EVENTS.each_key do |event|
        send(
          "after_#{event}", -> { process_emissions_for(event) },
          if: -> { has_event_config?(event) }
        )
      end
    end

    def save(**options, &block)
      assign_outbox_event(options)
      super(**options, &block)
    end

    def save!(**options, &block)
      assign_outbox_event(options)
      super(**options, &block)
    end

    private

    def assign_outbox_event(options)
      @outbox_event = options[:outbox_event].underscore.upcase if options[:outbox_event].present?
    end

    def should_emit?(action, config)
      # For column tracking, only emit if the column changed
      if config[:column]
        column_name = config[:column][:name].to_s
        return false unless previous_changes.key?(column_name)
      end

      true
    end

    def process_emissions_for(action)
      config = self.class.instance_variable_get(:@outbox_events)&.[](action)
      return unless config && should_emit?(action, config)

      event_name = if config[:column] && config[:column][:event] != :default
        config[:column][:event].to_s.upcase
      else
        determine_default_event_name(action)
      end

      create_outbox!(action, event_name)
    end

    def determine_default_event_name(action)
      *namespace, klass = self.class.name.underscore.upcase.split('/')
      namespace = namespace.reverse.join('.')
      event_suffix = Constants::VALID_EVENTS[action.to_sym]

      "#{klass}_#{event_suffix}#{namespace.blank? ? '' : '.'}#{namespace}"
    end
  end
end
