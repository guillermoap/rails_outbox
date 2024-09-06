# frozen_string_literal: true

RailsOutbox.configure do |config|
  config.outbox_mapping.merge!(
    'default' => 'Outbox',
    'uuid' => 'Uuid::Outbox'
  )
end
