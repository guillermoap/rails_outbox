# frozen_string_literal: true

require 'spec_helper'
require 'generator_spec'
require 'tempfile'
require 'generators/rails_outbox/model/model_generator'

RSpec.describe RailsOutbox::Generators::ModelGenerator, type: :generator do
  destination File.expand_path('tmp', __dir__)

  before do
    prepare_destination
    Time.use_zone('UTC') do
      travel_to Time.zone.local(2023, 10, 20, 14, 25, 30)
    end
  end

  after do
    travel_back
    FileUtils.rm_rf(destination_root)
  end

  let(:table_name) { '' }
  let(:migration_file_path) do
    "#{destination_root}/db/migrate/#{timestamp_of_migration}_rails_outbox_create_#{table_name}_outboxes.rb"
  end
  let(:timestamp_of_migration) { DateTime.now.in_time_zone('UTC').strftime('%Y%m%d%H%M%S') }

  shared_examples 'creates the correct model file' do
    let(:expected_content) do
      <<~MODEL
        class #{path_name.camelize} < ApplicationRecord
          validates_presence_of :identifier, :payload, :aggregate, :aggregate_identifier, :event
        end
      MODEL
    end

    it 'create the model file with the correct content' do
      generate
      expect(actual_content).to include(expected_content)
    end
  end

  shared_examples 'creates the correct migrations for supported adapters' do
    context 'when it is a mysql migration' do
      before do
        allow(RailsOutbox::AdapterHelper).to receive_messages(postgres?: false, mysql?: true)
      end

      let(:expected_content) do
        <<~MIGRATION
          class RailsOutboxCreate#{table_name.camelize}Outboxes < ActiveRecord::Migration[#{active_record_dependency}]
            def change
              create_table :#{table_name}#{table_name.blank? ? '' : '_'}outboxes do |t|
                t.string :identifier, null: false, index: { unique: true }
                t.string :event, null: false
                t.json :payload
                t.string :aggregate, null: false
                t.#{aggregate_identifier_types[0]} :aggregate_identifier, null: false, index: true

                t.timestamps
              end
            end
          end
        MIGRATION
      end

      it 'creates the migration with the correct content' do
        generate
        expect(actual_content).to include(expected_content)
      end
    end

    context 'when it is a sqlite migration' do
      before do
        allow(RailsOutbox::AdapterHelper).to receive_messages(postgres?: false, mysql?: false)
      end

      let(:expected_content) do
        <<~MIGRATION
          class RailsOutboxCreate#{table_name.camelize}Outboxes < ActiveRecord::Migration[#{active_record_dependency}]
            def change
              create_table :#{table_name}#{table_name.blank? ? '' : '_'}outboxes do |t|
                t.string :identifier, null: false, index: { unique: true }
                t.string :event, null: false
                t.string :payload
                t.string :aggregate, null: false
                t.#{aggregate_identifier_types[1]} :aggregate_identifier, null: false, index: true

                t.timestamps
              end
            end
          end
        MIGRATION
      end

      it 'creates the migration with the correct content' do
        generate
        expect(actual_content).to include(expected_content)
      end
    end

    context 'when it is a postgres migration' do
      before do
        allow(RailsOutbox::AdapterHelper).to receive(:postgres?).and_return(true)
      end

      let(:expected_content) do
        <<~MIGRATION
          class RailsOutboxCreate#{table_name.camelize}Outboxes < ActiveRecord::Migration[#{active_record_dependency}]
            def change
              create_table :#{table_name}#{table_name.blank? ? '' : '_'}outboxes do |t|
                t.uuid :identifier, null: false, index: { unique: true }
                t.string :event, null: false
                t.jsonb :payload
                t.string :aggregate, null: false
                t.#{aggregate_identifier_types[2]} :aggregate_identifier, null: false, index: true

                t.timestamps
              end
            end
          end
        MIGRATION
      end

      it 'creates the migration with the correct content' do
        generate
        expect(actual_content).to include(expected_content)
      end
    end
  end

  context 'with default outbox name' do
    let(:migration_file_path) do
      "#{destination_root}/db/migrate/#{timestamp_of_migration}_rails_outbox_create_outboxes.rb"
    end

    let(:model_file_path) do
      "#{destination_root}/app/models/outbox.rb"
    end

    context 'without root_component_path' do
      before do
        allow(Rails).to receive(:root).and_return(destination_root)
      end

      it 'creates the expected files' do
        run_generator
        assert_file migration_file_path
        assert_file model_file_path
      end
    end

    context 'with root_component_path' do
      it 'creates the expected files' do
        run_generator(["--component_path=#{destination_root}"])
        assert_file migration_file_path
        assert_file model_file_path
      end
    end

    describe 'model content' do
      subject(:generate) { run_generator(["--component_path=#{destination_root}"]) }

      let(:actual_content) { File.read(model_file_path) }
      let(:path_name) { 'outbox' }

      include_examples 'creates the correct model file'
    end

    describe 'migration content' do
      let(:actual_content) { File.read(migration_file_path) }
      let(:active_record_dependency) { ActiveRecord::VERSION::STRING.to_f }

      context 'with id aggregate_identifier' do
        subject(:generate) { run_generator(["--component_path=#{destination_root}"]) }

        let(:aggregate_identifier_types) { %w[bigint integer bigint] }

        include_examples 'creates the correct migrations for supported adapters'
      end

      context 'with uuid aggregate_identifier' do
        subject(:generate) { run_generator(["--component_path=#{destination_root}", '--uuid']) }

        let(:aggregate_identifier_types) { %w[string string uuid] }

        include_examples 'creates the correct migrations for supported adapters'
      end
    end
  end

  context 'with custom outbox name' do
    let(:table_name) { 'custom_table_name' }
    let(:path_name) { "#{table_name}_outbox" }
    let(:model_file_path) do
      "#{destination_root}/app/models/#{path_name}.rb"
    end

    context 'without root_component_path' do
      before do
        allow(Rails).to receive(:root).and_return(destination_root)
      end

      it 'creates the expected files' do
        run_generator [table_name]
        assert_file migration_file_path
        assert_file model_file_path
      end
    end

    context 'with root_component_path' do
      it 'creates the expected files' do
        run_generator([table_name, "--component_path=#{destination_root}"])
        assert_file migration_file_path
        assert_file model_file_path
      end
    end

    describe 'model content' do
      subject(:generate) { run_generator([table_name, "--component_path=#{destination_root}"]) }

      let(:actual_content) { File.read(model_file_path) }

      include_examples 'creates the correct model file'
    end

    describe 'migration content' do
      let(:actual_content) { File.read(migration_file_path) }
      let(:active_record_dependency) { ActiveRecord::VERSION::STRING.to_f }

      context 'with id aggregate_identifier' do
        subject(:generate) { run_generator([table_name, "--component_path=#{destination_root}"]) }

        let(:aggregate_identifier_types) { %w[bigint integer bigint] }

        include_examples 'creates the correct migrations for supported adapters'
      end

      context 'with uuid aggregate_identifier' do
        subject(:generate) { run_generator([table_name, "--component_path=#{destination_root}", '--uuid']) }

        let(:aggregate_identifier_types) { %w[string string uuid] }

        include_examples 'creates the correct migrations for supported adapters'
      end
    end
  end
end
