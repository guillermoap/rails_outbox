# frozen_string_literal: true

module RailsOutbox
  module OutboxPersistence
    def create_outbox!(action, event_name)
      outbox = outbox_model.new(
        aggregate: self.class.name,
        aggregate_identifier: send(self.class.primary_key),
        event: @outbox_event || event_name,
        payload: formatted_payload(action)
      )
      @outbox_event = nil
      handle_outbox_errors(outbox) if outbox.invalid?
      outbox.save!
    end

    def outbox_model
      module_parent = self.class.module_parent
      unless module_parent.const_defined?('OUTBOX_MODEL', false)
        outbox_model = outbox_model_name!.safe_constantize
        module_parent.const_set('OUTBOX_MODEL', outbox_model)
      end
      module_parent.const_get('OUTBOX_MODEL')
    end

    def outbox_model_name!
      namespace_outbox_mapping || default_outbox_mapping || raise(OutboxClassNotFoundError)
    end

    private

    def namespace_outbox_mapping
      namespace = self.class.module_parent.name.underscore
      RailsOutbox.config.outbox_mapping[namespace]
    end

    def default_outbox_mapping
      RailsOutbox.config.outbox_mapping['default']
    end

    def handle_outbox_errors(outbox)
      outbox.errors.each do |error|
        errors.import(error, attribute: "outbox.#{error.attribute}")
      end
    end

    def formatted_payload(action)
      payload = construct_payload(action)
      AdapterHelper.postgres? ? payload : payload.to_json
    end

    def construct_payload(action)
      case action
      when :create
        { before: nil, after: as_json }
      when :update, :save, :commit, :touch
        changes = previous_changes.transform_values(&:first)
        { before: as_json.merge(changes), after: as_json }
      when :touch
        changes = previous_changes.transform_values(&:first)
        { before: as_json.merge(changes), after: as_json }
      when :destroy
        { before: as_json, after: nil }
      when :rollback
        { before: as_json, after: as_json }
      else
        raise ActiveRecord::RecordNotSaved.new(
          "Failed to create Outbox payload for #{self.class.name}: #{send(self.class.primary_key)}",
          self
        )
      end
    end
  end
end
