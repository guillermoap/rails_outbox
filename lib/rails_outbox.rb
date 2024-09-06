# frozen_string_literal: true

require 'rails_outbox/adapter_helper'
require 'rails_outbox/errors'
require 'rails_outbox/outboxable'
require 'rails_outbox/railtie' if defined?(Rails::Railtie)
require 'dry-configurable'

module RailsOutbox
  extend Dry::Configurable

  setting :adapter, default: :sqlite
  setting :outbox_mapping, default: {}
end
