require 'spec_helper'

RSpec.describe RailsOutbox::Emits do
  let(:test_class) { FakeEmitsModel }
  let(:events) { test_class.instance_variable_get(:@outbox_events) }

  after { test_class.remove_instance_variable(:@outbox_events) }

  describe '#emits_on' do
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

    context 'merging default events with column configs' do
      it 'adds default event when column has custom event' do
        test_class.emits_on(update: {
          column: {
            name: :test_field,
            event: :custom
          }
        })
        test_class.emits_on(:update)

        expect(events[:update]).to eq({
          event: :default,
          column: {
            name: :test_field,
            event: :custom
          }
        })
      end

      it 'does not add default event when column has default event' do
        test_class.emits_on(update: { column: :test_field }) # default event
        test_class.emits_on(:update)

        expect(events[:update]).to eq({
          column: {
            name: :test_field,
            event: :default
          }
        })
      end

      it 'handles multiple events correctly' do
        test_class.emits_on(
          :create,
          update: {
            column: {
              name: :test_field,
              event: :custom
            }
          },
          destroy: { column: :another_field } # default event
        )
        test_class.emits_on(:update, :destroy)

        expect(events).to eq({
          create: { event: :default },
          update: {
            event: :default,
            column: {
              name: :test_field,
              event: :custom
            }
          },
          destroy: {
            column: {
              name: :another_field,
              event: :default
            }
          }
        })
      end
    end
  end
end
