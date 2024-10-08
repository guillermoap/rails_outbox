# frozen_string_literal: true

class RailsOutboxCreate<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :<%= table_name %> do |t|
      t.<%= RailsOutbox::AdapterHelper.uuid_type %> :identifier, null: false, index: { unique: true }
      t.string :event, null: false
      t.<%= RailsOutbox::AdapterHelper.json_type %> :payload
      t.string :aggregate, null: false
      t.<%= aggregate_identifier_type %> :aggregate_identifier, null: false, index: true

      t.timestamps
    end
  end
end
