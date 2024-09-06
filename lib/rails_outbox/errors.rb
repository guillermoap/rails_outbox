# frozen_string_literal: true

module RailsOutbox
  class OutboxConfigurationError < StandardError; end

  class OutboxClassNotFoundError < OutboxConfigurationError
    def message
      <<~MESSAGE
        Missing Outbox class definition. Configure mapping in `config/initializers/rails_outbox.rb`:

        Rails.application.reloader.to_prepare do
          RailsOutbox.configure do |config|
            config.outbox_mapping = {
              'default' => <outbox model name>
            }
          end
        end
      MESSAGE
    end
  end
end
