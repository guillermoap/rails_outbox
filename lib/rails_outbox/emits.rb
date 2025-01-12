require 'rails_outbox/constants'

module RailsOutbox
  module Emits
    def self.extended(base)
      base.include InstanceMethods
    end

    module InstanceMethods
      def has_event_config?(event)
        self.class.instance_variable_get(:@outbox_events)&.[](event).present?
      end
    end

    def emits_on(*attributes)
      @outbox_events ||= {}
      validate_attributes!(attributes)
      merge_configurations
    end

    private

    def validate_attributes!(attributes)
      @custom_events = attributes.extract_options!.dup || {}
      @default_events = attributes & valid_events
      validate_event_presence!(attributes)
      validate_event_support!(attributes)
    end

    def validate_event_presence!(attributes)
      return if attributes.present? || @default_events.present? || @custom_events.present?

      raise ArgumentError, 'You need to supply at least one event'
    end

    def validate_event_support!(attributes)
      unsupported_events = (attributes - valid_events).any?
      return unless unsupported_events

      raise ArgumentError, "You need to provide supported events: #{valid_events.join(', ')}"
    end

    def valid_events
      RailsOutbox::Constants::VALID_EVENTS.keys
    end

    def merge_configurations
      merge_default_events
      merge_custom_events
      @outbox_events
    end

    def merge_default_events
      @default_events.each do |event|
        existing = @outbox_events[event]
        if existing.nil?
          @outbox_events[event] = { event: :default }
        elsif existing[:column] && existing[:column][:event] == :default
          # Don't add default event if we already track this column with default event
          next
        elsif existing[:column] && existing[:column][:event] != :default
          # Add default event alongside custom column event
          @outbox_events[event] = {
            event: :default,
            column: existing[:column]
          }
        end
      end
    end

    def merge_custom_events
      @custom_events.each do |event, config|
        next unless valid_events.include?(event)

        @outbox_events[event] = normalize_config(config)
      end
    end

    def normalize_config(config)
      if config[:column]
        if config[:column].is_a?(Symbol) || config[:column].is_a?(String)
          { column: { name: config[:column], event: :default } }
        else
          { column: { name: config[:column][:name], event: config[:column][:event] } }
        end
      else
        { event: config[:event] || :default }
      end
    end
  end
end
