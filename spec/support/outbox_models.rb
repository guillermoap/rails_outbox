# frozen_string_literal: true

# NOTICE:
# Class definition ordering matters in this file. Do not change unless deemed necessary

Object.const_set('Uuid', Module.new)

Outbox = Class.new(ActiveRecord::Base) do
  def self.name
    'Outbox'
  end

  validates_presence_of :payload, :aggregate, :aggregate_identifier, :event
end

Uuid::Outbox = Class.new(ActiveRecord::Base) do
  def self.name
    'Uuid::Outbox'
  end

  def self.table_name
    'uuid_outboxes'
  end

  validates_presence_of :payload, :aggregate, :aggregate_identifier, :event

  before_validation -> { self.id = SecureRandom.uuid if id.nil? }
end

FakeEmitsModel = Class.new(ActiveRecord::Base) do
  def self.name
    'FakeEmitsModel'
  end

  def self.table_name
    'fake_models'
  end

  validates_presence_of :test_field

  extend RailsOutbox::Emits
end

FakeModel = Class.new(ActiveRecord::Base) do
  def self.name
    'FakeModel'
  end

  validates_presence_of :test_field
  include RailsOutbox::Outboxable
end

Uuid::FakeModel = Class.new(ActiveRecord::Base) do
  def self.name
    'Uuid::FakeModel'
  end

  def self.table_name
    'uuid_fake_models'
  end

  validates_presence_of :test_field
  include RailsOutbox::Outboxable

  before_validation -> { self.id = SecureRandom.uuid if id.nil? }
end

def create_migrations
  id_migrations
  uuid_migrations
end

def id_migrations
  ActiveRecord::Base.connection.create_table :fake_models, if_not_exists: true do |t|
    t.string :test_field

    t.timestamps
  end

  ActiveRecord::Base.connection.create_table :outboxes, if_not_exists: true do |t|
    t.string :event, null: false
    t.send(RailsOutbox::AdapterHelper.json_type, :payload)
    t.string :aggregate, null: false
    t.integer :aggregate_identifier, null: false

    t.timestamps
  end
end

def uuid_migrations
  ActiveRecord::Base.connection.create_table :uuid_fake_models, if_not_exists: true, id: false do |t|
    t.send(RailsOutbox::AdapterHelper.uuid_type, :id, primary_key: true)
    t.string :test_field

    t.timestamps
  end

  ActiveRecord::Base.connection.create_table :uuid_outboxes, if_not_exists: true, id: false do |t|
    t.send(RailsOutbox::AdapterHelper.uuid_type, :id, primary_key: true)
    t.string :event, null: false
    t.send(RailsOutbox::AdapterHelper.json_type, :payload)
    t.string :aggregate, null: false
    t.send(RailsOutbox::AdapterHelper.uuid_type, :aggregate_identifier, null: false)

    t.timestamps
  end
end
