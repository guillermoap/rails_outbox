# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsOutbox::Outboxable do
  describe 'CREATED event' do
    context 'with normal ID' do
      let(:model_class) { FakeModel }
      let(:outbox_class) { Outbox }
      let(:instance) { model_class.new(test_field: 'test value') }

      it 'creates outbox record on create' do
        expect do
          instance.save
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'CREATED'),
              'aggregate' => model_class.name,
              'aggregate_identifier' => instance.id,
              'payload' => {
                'before' => nil,
                'after' => instance.as_json

              }
            }
          }
        )
      end
    end

    context 'with UUID' do
      let(:model_class) { Uuid::FakeModel }
      let(:outbox_class) { Uuid::Outbox }
      let(:instance) { model_class.new(test_field: 'test value') }

      it 'creates outbox record on create' do
        expect do
          instance.save
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'CREATED'),
              'aggregate' => model_class.name,
              'aggregate_identifier' => instance.id,
              'payload' => {
                'before' => nil,
                'after' => instance.as_json

              }
            }
          }
        )
      end
    end
  end

  describe 'UPDATED event' do
    context 'with normal ID' do
      let(:model_class) { FakeModel }
      let(:outbox_class) { Outbox }

      it 'creates outbox record on update' do
        instance = model_class.create!(test_field: 'original')
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
    end

    context 'with UUID' do
      let(:model_class) { Uuid::FakeModel }
      let(:outbox_class) { Uuid::Outbox }

      it 'creates outbox record on update' do
        instance = model_class.create!(test_field: 'original')
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
    end
  end

  describe 'DESTROYED event' do
    context 'with normal ID' do
      let(:model_class) { FakeModel }
      let(:outbox_class) { Outbox }

      it 'creates outbox record on destroy' do
        instance = model_class.create!(test_field: 'to be deleted')
        before_json = instance.as_json

        expect do
          instance.destroy
        end.to create_outbox_record(outbox_class).with_attributes(
          'event' => create_event_name(model_class, 'DESTROYED'),
          'aggregate' => model_class.name,
          'aggregate_identifier' => instance.id,
          'payload' => {
            'before' => before_json,
            'after' => nil
          }
        )
      end
    end

    context 'with UUID' do
      let(:model_class) { Uuid::FakeModel }
      let(:outbox_class) { Uuid::Outbox }

      it 'creates outbox record on destroy' do
        instance = model_class.create!(test_field: 'to be deleted')
        before_json = instance.as_json

        expect do
          instance.destroy
        end.to create_outbox_record(outbox_class).with_attributes(
          'event' => create_event_name(model_class, 'DESTROYED'),
          'aggregate' => model_class.name,
          'aggregate_identifier' => instance.id,
          'payload' => {
            'before' => before_json,
            'after' => nil
          }
        )
      end
    end
  end

  describe 'SAVED event' do
    context 'with normal ID' do
      let(:model_class) { FakeModel }
      let(:outbox_class) { Outbox }
      let(:instance) { model_class.new(test_field: 'test value') }

      it 'creates outbox record on save' do
        expect do
          instance.save
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'SAVED'),
              'aggregate' => model_class.name,
              'aggregate_identifier' => instance.id,
              'payload' => {
                'before' => {
                  'id' => nil,
                  'test_field' => nil,
                  'created_at' => nil,
                  'updated_at' => nil
                },
                'after' => instance.as_json
              }
            }
          }
        )
      end
    end

    context 'with UUID' do
      let(:model_class) { Uuid::FakeModel }
      let(:outbox_class) { Uuid::Outbox }
      let(:instance) { model_class.new(test_field: 'test value') }

      it 'creates outbox record on save' do
        expect do
          instance.save
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'SAVED'),
              'aggregate' => model_class.name,
              'aggregate_identifier' => instance.id,
              'payload' => {
                'before' => {
                  'id' => nil,
                  'test_field' => nil,
                  'created_at' => nil,
                  'updated_at' => nil
                },
                'after' => instance.as_json
              }
            }
          }
        )
      end
    end
  end

  describe 'TOUCHED event' do
    context 'with normal ID' do
      let(:model_class) { FakeModel }
      let(:outbox_class) { Outbox }

      it 'creates outbox record on touch' do
        instance = model_class.create!(test_field: 'test value')
        before_json = instance.as_json

        expect do
          instance.touch
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'TOUCHED'),
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
    end

    context 'with UUID' do
      let(:model_class) { Uuid::FakeModel }
      let(:outbox_class) { Uuid::Outbox }

      it 'creates outbox record on touch' do
        instance = model_class.create!(test_field: 'test value')
        before_json = instance.as_json

        expect do
          instance.touch
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'TOUCHED'),
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
    end
  end

  describe 'COMMITTED event' do
    context 'with normal ID' do
      let(:model_class) { FakeModel }
      let(:outbox_class) { Outbox }
      let(:instance) { model_class.new(test_field: 'test value') }

      it 'creates outbox record on commit' do
        expect do
          instance.save!
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'COMMITTED'),
              'aggregate' => model_class.name,
              'aggregate_identifier' => instance.id,
              'payload' => {
                'before' => {
                  'id' => nil,
                  'test_field' => nil,
                  'created_at' => nil,
                  'updated_at' => nil
                },
                'after' => instance.as_json
              }
            }
          }
        )
      end
    end

    context 'with UUID' do
      let(:model_class) { Uuid::FakeModel }
      let(:outbox_class) { Uuid::Outbox }
      let(:instance) { model_class.new(test_field: 'test value') }

      it 'creates outbox record on commit' do
        expect do
          ActiveRecord::Base.transaction do
            instance.save!
          end
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'COMMITTED'),
              'aggregate' => model_class.name,
              'aggregate_identifier' => instance.id,
              'payload' => {
                'before' => {
                  'id' => nil,
                  'test_field' => nil,
                  'created_at' => nil,
                  'updated_at' => nil
                },
                'after' => instance.as_json
              }
            }
          }
        )
      end
    end
  end

  describe 'ROLLED_BACK event' do
    context 'with normal ID' do
      let(:model_class) { FakeModel }
      let(:outbox_class) { Outbox }
      let(:instance) { model_class.new(test_field: 'test value') }

      it 'creates outbox record on rollback' do
        saved_instance = nil
        expect do
          ActiveRecord::Base.transaction do
            instance.save!
            saved_instance = instance.clone
            raise ActiveRecord::Rollback
          end
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'ROLLED_BACK'),
              'aggregate' => model_class.name,
              'aggregate_identifier' => saved_instance.id,
              'payload' => {
                'before' => saved_instance.as_json,
                'after' => saved_instance.as_json
              }
            }
          }
        )
      end
    end

    context 'with UUID' do
      let(:model_class) { Uuid::FakeModel }
      let(:outbox_class) { Uuid::Outbox }
      let(:instance) { model_class.new(test_field: 'test value') }

      it 'creates outbox record on rollback' do
        saved_instance = nil
        expect do
          ActiveRecord::Base.transaction do
            instance.save!
            saved_instance = instance.clone
            raise ActiveRecord::Rollback
          end
        end.to create_outbox_record(outbox_class).with_attributes(
          lambda {
            {
              'event' => create_event_name(model_class, 'ROLLED_BACK'),
              'aggregate' => model_class.name,
              'aggregate_identifier' => saved_instance.id,
              'payload' => {
                'before' => saved_instance.as_json,
                'after' => saved_instance.as_json
              }
            }
          }
        )
      end
    end
  end
end
