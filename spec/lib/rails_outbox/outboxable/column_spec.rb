# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsOutbox::Outboxable do
  let(:model_class) { FakeEmitsModel }
  let(:outbox_class) { Outbox }
  let!(:instance) { model_class.create!(test_field: 'original') }

  describe 'default event' do
    before do
      model_class.emits_on(
        update: {
          column: {
            name: :test_field,
            event: :default
          }
        }
      )
    end

    it 'creates outbox record when tracked column changes' do
      before_json = instance.as_json

      expect do
        instance.update(test_field: 'updated')
      end.to create_outbox_record(outbox_class).with_attributes(
        lambda {
          {
            'event' => create_event_name(model_class, 'UPDATED'),
            'aggregate' => model_class.name,
            'aggregate_identifier' => instance.id,
            'payload' => {
              'before' => before_json,
              'after' => instance.reload.as_json
            }
          }
        }
      )
    end

    it 'does not create outbox record when timestamp changes' do
      expect do
        instance.touch
      end.not_to create_outbox_record(outbox_class)
    end
  end

  describe 'custom event' do
    before do
      model_class.emits_on(
        update: {
          column: {
            name: :test_field,
            event: :test_field_changed
          }
        }
      )
    end

    it 'creates outbox record with custom event when tracked column changes' do
      before_json = instance.as_json

      expect do
        instance.update(test_field: 'updated')
      end.to create_outbox_record(outbox_class).with_attributes(
        lambda {
          {
            'event' => 'TEST_FIELD_CHANGED',
            'aggregate' => model_class.name,
            'aggregate_identifier' => instance.id,
            'payload' => {
              'before' => before_json,
              'after' => instance.reload.as_json
            }
          }
        }
      )
    end

    it 'does not create outbox record when timestamp changes' do
      expect do
        instance.touch
      end.not_to create_outbox_record(outbox_class)
    end
  end
end
