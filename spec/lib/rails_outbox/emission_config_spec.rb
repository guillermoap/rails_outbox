# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsOutbox::EmissionConfig do
  describe '.from_args' do
    subject(:config) { described_class.from_args(*args) }

    context 'with array of events' do
      let(:args) { [%i[create update]] }

      it 'creates config with events array' do
        expect(config.events).to eq(%i[create update])
        expect(config.column).to be_nil
        expect(config.event_names).to eq({ create: nil, update: nil })
      end
    end

    context 'with single event' do
      let(:args) { [:create] }

      it 'creates config with single event array' do
        expect(config.events).to eq([:create])
        expect(config.column).to be_nil
        expect(config.event_names).to eq({ create: nil })
      end
    end

    context 'with column and events hash' do
      let(:args) { [{ title: %i[update create] }] }

      it 'creates config with column and events' do
        expect(config.events).to eq(%i[update create])
        expect(config.column).to eq(:title)
        expect(config.event_names).to eq({ update: nil, create: nil })
      end
    end

    context 'with custom event names' do
      let(:args) { [{ update: :post_modified, create: :post_created }] }

      it 'creates config with custom event names' do
        expect(config.events).to eq({ update: :post_modified, create: :post_created })
        expect(config.column).to be_nil
        expect(config.event_names).to eq({ update: 'POST_MODIFIED', create: 'POST_CREATED' })
      end
    end

    context 'with column-specific custom events' do
      let(:args) { [{ title: { update: :title_changed } }] }

      it 'creates config with column and custom event' do
        expect(config.events).to eq({ update: :title_changed })
        expect(config.column).to eq(:title)
        expect(config.event_names).to eq({ update: 'TITLE_CHANGED' })
      end
    end

    context 'with invalid event type' do
      let(:args) { [:invalid_event] }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(
          ArgumentError,
          /Invalid event: invalid_event. Valid events are: #{RailsOutbox::Constants::VALID_EVENTS.keys.join(', ')}/
        )
      end
    end

    context 'with no arguments' do
      let(:args) { [] }

      it 'creates empty config' do
        expect(config.events).to be_empty
        expect(config.column).to be_nil
        expect(config.event_names).to be_empty
      end
    end
  end

  describe '#initialize' do
    subject(:config) { described_class.new(config_hash) }

    context 'with valid configuration' do
      let(:config_hash) do
        {
          column: :title,
          events: %i[create update]
        }
      end

      it 'initializes with the provided configuration' do
        expect(config.column).to eq(:title)
        expect(config.events).to eq(%i[create update])
        expect(config.event_names).to eq({ create: nil, update: nil })
      end
    end

    context 'with custom event names in configuration' do
      let(:config_hash) do
        {
          events: { create: :article_created, update: :article_updated }
        }
      end

      it 'initializes with custom event names' do
        expect(config.column).to be_nil
        expect(config.events).to eq({ create: :article_created, update: :article_updated })
        expect(config.event_names).to eq({ create: 'ARTICLE_CREATED', update: 'ARTICLE_UPDATED' })
      end
    end

    context 'with invalid event in configuration' do
      let(:config_hash) do
        {
          events: [:invalid_event]
        }
      end

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(
          ArgumentError,
          /Invalid event: invalid_event. Valid events are: #{RailsOutbox::Constants::VALID_EVENTS.keys.join(', ')}/
        )
      end
    end

    context 'with mixed valid and invalid events' do
      let(:config_hash) do
        {
          events: %i[create invalid_event]
        }
      end

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(
          ArgumentError,
          /Invalid event: invalid_event. Valid events are: #{RailsOutbox::Constants::VALID_EVENTS.keys.join(', ')}/
        )
      end
    end
  end
end
