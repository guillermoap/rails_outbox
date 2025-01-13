# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsOutbox::OutboxPersistence do
  shared_examples 'outbox persistence' do |model_class, outbox_class|
    let(:model) { model_class.new(test_field: 'test') }

    describe 'outbox model resolution' do
      context 'with normal ID' do
        it 'caches outbox model in module parent constant' do
          outbox_model = model.outbox_model
          expect(outbox_model).to eq(outbox_class)
          expect(model_class.module_parent::OUTBOX_MODEL).to eq(outbox_class)
        end

        it 'resolves outbox model from mapping' do
          # Clear any cached model
          if model_class.module_parent.const_defined?(:OUTBOX_MODEL)
            model_class.module_parent.send(:remove_const,
              :OUTBOX_MODEL)
          end

          expect(model.outbox_model_name!).to eq(outbox_class.name)
          expect(model.outbox_model).to eq(outbox_class)
        end

        it 'raises error when no mapping exists' do
          allow(RailsOutbox.config).to receive(:outbox_mapping).and_return({})
          expect { model.send(:outbox_model_name!) }.to raise_error(RailsOutbox::OutboxClassNotFoundError)
        end
      end
    end

    describe '#create_outbox!' do
      subject { model.create_outbox!(event, event_name) }

      before { model.save! }

      context 'when creating an outbox record' do
        let(:event) { :create }
        let(:event_name) { create_event_name(model.class, 'created') }

        it 'creates the outbox record with create event' do
          expect do
            subject
          end.to create_outbox_record(outbox_class).with_attributes({
            'aggregate' => model_class.name,
            'aggregate_identifier' => model.id,
            'event' => event_name,
            'payload' => {
              'before' => nil,
              'after' => model.as_json
            }
          })
        end
      end

      context 'when updating a record' do
        let(:event) { :update }
        let(:event_name) { create_event_name(model.class, 'updated') }

        before { model.update!(test_field: 'updated') }

        it 'creates the outbox record with update event' do
          expect do
            subject
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => event_name,
            'payload' => {
              'before' => hash_including('test_field' => 'test'),
              'after' => hash_including('test_field' => 'updated')
            }
          })
        end
      end

      context 'when saving a record' do
        let(:event) { :save }
        let(:event_name) { create_event_name(model.class, 'saved') }

        before do
          model.test_field = 'new value'
          model.save!
        end

        it 'creates the outbox record with save event' do
          expect do
            subject
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => event_name,
            'payload' => {
              'before' => hash_including('test_field' => 'test'),
              'after' => hash_including('test_field' => 'new value')
            }
          })
        end
      end

      context 'when committing a transaction' do
        let(:event) { :commit }
        let(:event_name) { create_event_name(model.class, 'committed') }

        before do
          model.test_field = 'committed value'
          model.save!
        end

        it 'creates the outbox record with commit event' do
          expect do
            subject
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => event_name,
            'payload' => {
              'before' => hash_including('test_field' => 'test'),
              'after' => hash_including('test_field' => 'committed value')
            }
          })
        end
      end

      context 'when rolling back a transaction' do
        let(:event) { :rollback }
        let(:event_name) { create_event_name(model.class, 'rollbacked') }

        it 'creates the outbox record with rollback event' do
          expect do
            subject
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => event_name,
            'payload' => {
              'before' => model.as_json,
              'after' => model.as_json
            }
          })
        end
      end

      context 'when destroying a record' do
        let(:event) { :destroy }
        let(:event_name) { create_event_name(model.class, 'destroyed') }

        before do
          model.destroy!
        end

        it 'creates the outbox record with destroy event' do
          expect do
            subject
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => event_name,
            'payload' => {
              'before' => model.as_json,
              'after' => nil
            }
          })
        end
      end

      context 'when touching a record' do
        let!(:model) { model_class.create!(test_field: 'test') }
        let(:event) { :touch }
        let(:event_name) { create_event_name(model.class, 'touched') }

        before do
          model.touch
        end

        it 'creates the outbox record with touch event' do
          expect do
            subject
          end.to create_outbox_record(outbox_class).with_attributes({
            'event' => event_name
          })
        end
      end

      context 'with custom event name' do
        let(:event) { :create }
        let(:event_name) { create_event_name(model.class, 'created') }

        before do
          model.instance_variable_set(:@outbox_event, 'CUSTOM_EVENT')
        end

        it 'uses the custom event name' do
          expect do
            subject
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
        let!(:original_mapping) { RailsOutbox.config.outbox_mapping.dup }

        before do
          RailsOutbox.config.outbox_mapping.clear
        end

        after do
          RailsOutbox.config.outbox_mapping = original_mapping
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
