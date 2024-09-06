# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  RailsOutbox.configure do |config|
    # To configure which Outbox class maps to which domain
    # See https://github.com/guillermoap/rails_outbox#advanced-usage for advanced examples
    config.outbox_mapping = {
      'default' => 'Outbox'
    }

    # Configure database adapter
    # config.adapter = :postgresql
  end
end
