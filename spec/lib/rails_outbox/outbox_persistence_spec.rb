# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsOutbox::OutboxPersistence do
  shared_examples 'outbox persistence' do |model_class, outbox_class|
    let(:model) { model_class.new(test_field: 'test') }

    describe '#create_outbox!' do
      before do
        model.save
      end

      context 'when creating an outbox record' do
        it 'creates the outbox record with create event' do
          expect do
            model.create_outbox!(:create, "#{model_class.name.underscore.upcase}_CREATED")
          end.to create_outbox_record(outbox_class).with_attributes({
            'aggregate' => model_class.name,
            'aggregate_identifier' => model.id,
            'event' => "#{model_class.name.underscore.upcase}_CREATED",
            'payload' => {
              'before' => nil,
              'after' => model.as_json
            }
          })
        end
      end

      context 'when updating a record' do
        before do
          model.update(test_field: 'updated')
        end

        it 'creates the outbox record with update event' do
          expect do
            model.create_outbox!(:update, "#{model_class.name.underscore.upcase}_UPDATED")
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => "#{model_class.name.underscore.upcase}_UPDATED",
            'payload' => {
              'before' => hash_including('test_field' => 'test'),
              'after' => hash_including('test_field' => 'updated')
            }
          })
        end
      end

      context 'when saving a record' do
        before do
          model.test_field = 'new value'
          model.save
        end

        it 'creates the outbox record with save event' do
          expect do
            model.create_outbox!(:save, "#{model_class.name.underscore.upcase}_SAVED")
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => "#{model_class.name.underscore.upcase}_SAVED",
            'payload' => {
              'before' => hash_including('test_field' => 'test'),
              'after' => hash_including('test_field' => 'new value')
            }
          })
        end
      end

      context 'when committing a transaction' do
        before do
          model.test_field = 'committed value'
          model.save
        end

        it 'creates the outbox record with commit event' do
          expect do
            model.create_outbox!(:commit, "#{model_class.name.underscore.upcase}_COMMITTED")
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => "#{model_class.name.underscore.upcase}_COMMITTED",
            'payload' => {
              'before' => hash_including('test_field' => 'test'),
              'after' => hash_including('test_field' => 'committed value')
            }
          })
        end
      end

      context 'when rolling back a transaction' do
        it 'creates the outbox record with rollback event' do
          expect do
            model.create_outbox!(:rollback, "#{model_class.name.underscore.upcase}_ROLLED_BACK")
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => "#{model_class.name.underscore.upcase}_ROLLED_BACK",
            'payload' => {
              'before' => model.as_json,
              'after' => model.as_json
            }
          })
        end
      end

      context 'when destroying a record' do
        it 'creates the outbox record with destroy event' do
          expect do
            model.create_outbox!(:destroy, "#{model_class.name.underscore.upcase}_DESTROYED")
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => "#{model_class.name.underscore.upcase}_DESTROYED",
            'payload' => {
              'before' => model.as_json,
              'after' => nil
            }
          })
        end
      end

      context 'when touching a record' do
        let(:original_timestamp) { model.updated_at }

        before do
          travel_to(original_timestamp + 1.day)
          model.touch
        end

        after { travel_back }

        it 'creates the outbox record with touch event' do
          expect do
            model.create_outbox!(:touch, "#{model_class.name.underscore.upcase}_TOUCHED")
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => "#{model_class.name.underscore.upcase}_TOUCHED"
          })
        end

        it 'creates the outbox record with timestamp changes' do
          model.create_outbox!(:touch, "#{model_class.name.underscore.upcase}_TOUCHED")
          outbox = outbox_class.last
          payload = RailsOutbox::AdapterHelper.postgres? ? outbox.payload : JSON.parse(outbox.payload)
          before_date = DateTime.parse(payload.dig('before', 'updated_at'))
          after_date = DateTime.parse(payload.dig('after', 'updated_at'))
          expect(before_date.to_i).to be < after_date.to_i
        end
      end

      context 'with custom event name' do
        before do
          model.instance_variable_set(:@outbox_event, 'CUSTOM_EVENT')
        end

        it 'uses the custom event name' do
          expect do
            model.create_outbox!(:create, "#{model_class.name.underscore.upcase}_CREATED")
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => 'CUSTOM_EVENT'
          })
          expect(model.instance_variable_get(:@outbox_event)).to be_nil
        end
      end

      context 'with an invalid action' do
        it 'raises RecordNotSaved error' do
          expect do
            model.create_outbox!(:invalid_action, 'TEST_EVENT')
          end.to raise_error(
            ActiveRecord::RecordNotSaved,
            "Failed to create Outbox payload for #{model_class.name}: #{model.id}"
          )
        end
      end
    end

    describe '#outbox_model' do
      it 'returns the correct outbox model' do
        expect(model.outbox_model).to eq(outbox_class)
      end

      it 'caches the outbox model in a constant' do
        model.outbox_model
        expect(model_class.module_parent.const_get('OUTBOX_MODEL')).to eq(outbox_class)
      end
    end

    describe '#outbox_model_name!' do
      context 'with default mapping' do
        it 'returns the configured outbox model name' do
          expect(model.outbox_model_name!).to eq(outbox_class.name)
        end
      end

      context 'without any mapping' do
        before do
          @original_mapping = RailsOutbox.config.outbox_mapping.dup
          RailsOutbox.config.outbox_mapping.clear
        end

        after do
          RailsOutbox.config.outbox_mapping = @original_mapping
        end

        it 'raises OutboxClassNotFoundError' do
          expect { model.outbox_model_name! }.to raise_error(RailsOutbox::OutboxClassNotFoundError)
        end
      end
    end
  end

  context 'with regular models' do
    include_examples 'outbox persistence', FakeModel, Outbox
  end

  context 'with UUID models' do
    include_examples 'outbox persistence', Uuid::FakeModel, Uuid::Outbox
  end
end
