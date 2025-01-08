# frozen_string_literal: true

module RailsOutbox
  class EmissionConfig
    attr_reader :column, :events, :event_names

    def self.from_args(*args)
      new(parse_configuration(args))
    end

    def self.parse_configuration(args)
      return parse_hash_config(args.first) if args.first.is_a?(Hash)

      { events: args.flatten }
    end

    def self.parse_hash_config(hash_config)
      if single_column_with_events?(hash_config)
        parse_column_events(*hash_config.first)
      elsif all_values_are_event_names?(hash_config)
        parse_custom_event_names(hash_config)
      else
        hash_config
      end
    end

    def self.single_column_with_events?(hash_config)
      (hash_config.size == 1 &&
        hash_config.values.first.is_a?(Array)) ||
        (hash_config.values.first.is_a?(Hash) && hash_config.keys.first.is_a?(Symbol))
    end

    def self.all_values_are_event_names?(hash_config)
      hash_config.all? { |k, v| v.is_a?(String) || v.is_a?(Symbol) }
    end

    def self.parse_column_events(column, events)
      { column: column, events: events }
    end

    def self.parse_custom_event_names(hash_config)
      { events: hash_config }
    end

    def initialize(config)
      @column = config[:column]
      @events = validate_events(config[:events])
      @event_names = build_event_names
    end

    private

    def validate_events(events)
      events = Constants::VALID_EVENTS.keys if events.nil?

      if events.is_a?(Hash)
        validate_event_hash(events)
        events
      else
        Array(events).each do |event|
          validate_event_name!(event)
        end
        events
      end
    end

    def validate_event_hash(events_hash)
      events_hash.each_key do |event_name|
        validate_event_name!(event_name)
      end
    end

    def validate_event_name!(event_name)
      event_name = extract_event_name(event_name)
      return if Constants::VALID_EVENTS.key?(event_name)

      valid_events = Constants::VALID_EVENTS.keys.join(', ')
      raise ArgumentError, "Invalid event: #{event_name}. Valid events are: #{valid_events}"
    end

    def extract_event_name(event)
      event.is_a?(Hash) ? event.keys.first : event
    end

    def build_event_names
      return build_custom_event_names if @events.is_a?(Hash)

      event_names = {}
      Array(@events).each do |event|
        if event.is_a?(Hash)
          event.each do |action, name|
            event_names[action] = name.to_s.upcase
          end
        else
          event_names[event] = nil # Use default naming
        end
      end
      event_names
    end

    def build_custom_event_names
      @events.transform_values { |name| name.to_s.upcase }
    end
  end
end
