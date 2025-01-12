require 'spec_helper'

RSpec.describe RailsOutbox::Emits do
  let(:test_class) { FakeEmitsModel }
  let(:events) { test_class.instance_variable_get(:@outbox_events) }

  describe '#emits_on' do
    after { test_class.remove_instance_variable(:@outbox_events) }

    context 'validation' do
      it 'raises error when no events provided' do
        expect { test_class.emits_on }.to raise_error(
          ArgumentError, 'You need to supply at least one event'
        )
      end

      it 'raises error for invalid events' do
        expect { test_class.emits_on(:invalid_event) }.to raise_error(
          ArgumentError, /You need to provide supported events/
        )
      end
    end

    context 'basic events' do
      it 'handles single event' do
        test_class.emits_on(:create)

        expect(events).to eq({
          create: { event: :default }
        })
      end

      it 'handles multiple events' do
        test_class.emits_on(:create, :update)

        expect(events).to eq({
          create: { event: :default },
          update: { event: :default }
        })
      end
    end

    context 'column tracking' do
      it 'normalizes simple column reference' do
        test_class.emits_on(update: { column: :test_field })

        expect(events).to eq({
          update: {
            column: {
              name: :test_field,
              event: :default
            }
          }
        })
      end

      it 'handles string column names' do
        test_class.emits_on(update: { column: 'test_field' })

        expect(events).to eq({
          update: {
            column: {
              name: 'test_field',
              event: :default
            }
          }
        })
      end

      it 'preserves custom column events' do
        test_class.emits_on(
          update: {
            column: {
              name: :test_field,
              event: :custom
            }
          }
        )

        expect(events).to eq({
          update: {
            column: {
              name: :test_field,
              event: :custom
            }
          }
        })
      end
    end

    context 'multiple configurations' do
      it 'handles mix of default and column events' do
        test_class.emits_on(
          :create,
          update: { column: :test_field },
          destroy: {
            column: {
              name: :another_field,
              event: :custom
            }
          }
        )

        expect(events).to eq({
          create: { event: :default },
          update: {
            column: {
              name: :test_field,
              event: :default
            }
          },
          destroy: {
            column: {
              name: :another_field,
              event: :custom
            }
          }
        })
      end
    end
  end

  describe 'instance methods' do
    let(:test_instance) { test_class.new }

    describe '#has_event_config?' do
      context 'when no events are configured' do
        it 'returns false' do
          expect(test_instance.has_event_config?(:create)).to be false
        end
      end

      context 'when events are configured' do
        before do
          test_class.emits_on(:create, update: { column: :test_field })
        end

        it 'returns true for configured events' do
          expect(test_instance.has_event_config?(:create)).to be true
          expect(test_instance.has_event_config?(:update)).to be true
        end

        it 'returns false for unconfigured events' do
          expect(test_instance.has_event_config?(:destroy)).to be false
        end
      end

      context 'when events are configured with columns' do
        before do
          test_class.emits_on(
            update: {
              column: {
                name: :test_field,
                event: :custom
              }
            }
          )
        end

        it 'returns true for configured column events' do
          expect(test_instance.has_event_config?(:update)).to be true
        end
      end
    end
  end
end
