# frozen_string_literal: true

module RailsOutbox
  module Constants
    VALID_EVENTS = {
      create: 'CREATED',
      update: 'UPDATED',
      destroy: 'DESTROYED',
      save: 'SAVED',
      commit: 'COMMITTED',
      rollback: 'ROLLED_BACK',
      touch: 'TOUCHED'
    }.freeze

    SAVE_EVENTS = %i[create update].freeze
  end
end
