# frozen_string_literal: true

module OutboxableTestHelpers
  extend RSpec::Matchers::DSL

  matcher :create_outbox_record do |outbox_class|
    match(notify_expectation_failures: true) do |actual|
      count = outbox_class.count
      expect { actual.call }.to change(outbox_class, :count).by_at_least(1)
      count = outbox_class.count - count

      if @attributes
        @attributes = @attributes.call if @attributes.is_a? Proc
        outboxes = outbox_class.last(count).map do |outbox|
          outbox.attributes.tap do |attr|
            attr['payload'] = JSON.parse(attr['payload']) unless RailsOutbox::AdapterHelper.postgres?
          end
        end
        expect(outboxes).to match(array_including(hash_including(@attributes)))
      end

      true
    end

    match_when_negated(notify_expectation_failures: true) do |actual|
      expect { actual.call }.not_to change(outbox_class, :count)
    end

    supports_block_expectations
    diffable

    chain :with_attributes do |attributes|
      @attributes = attributes
    end
  end
end
