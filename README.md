# Rails Outbox
A Transactional Outbox implementation for Rails and ActiveRecord.

![transactional outbox pattern](./docs/images/transactional_outbox.png)

This gem aims to implement the event persistance side of the pattern, focusing only on providing a seamless way to store Outbox records whenever a change occurs on a given model (#1 in the diagram).
We do not provide an event publisher, nor a consumer as a part of this gem since the idea is to keep it as light weight as possible.

## Motivation
If you find yourself repeatedly defining a transaction block every time you need to persist an event, it might be a sign that something needs improvement. We believe that adopting a pattern should enhance your workflow, not hinder it. Creating, updating or destroying a record should remain a familiar and smooth process.

Our primary objective is to ensure a seamless experience without imposing our own opinions or previous experiences. That's why this gem exclusively focuses on persisting records. We leave the other aspects of the pattern entirely open for your customization. You can emit these events using Sidekiq jobs, or explore more sophisticated solutions like Kafka Connect.

## Why rails_outbox?
- Seamless integration with ActiveRecord
- CRUD events out of the box
- Ability to set custom events
- Test helpers to easily check Outbox records are being created correctly
- Customizable

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_outbox'
```

And then execute:
```bash
bundle install
```
Or install it yourself as:
```bash
gem install rails_outbox
```

## Usage
### Setup
Create the outbox table and model using the provided generator. Any model name can be passed as an argument but if empty it will default to `outboxes` and `Outbox` respectively.
```bash
rails g rails_outbox:model <optional model_name>

  create  db/migrate/20231115182800_rails_outbox_create_<model_name_>outboxes.rb
  create  app/models/<model_name_>outbox.rb
```
After running the migration, create an initializer under `config/initializers/rails_outbox.rb` and setup the default outbox class to the new `Outbox` model you just created.
```bash
rails g rails_outbox:install
```

To allow models to store Outbox records on changes, you will have to include the `Outboxable` concern.
```ruby
# app/models/user.rb

class User < ApplicationRecord
  include RailsOutbox::Outboxable
end
```
### Base Events
Using the User model as an example, the default event names provided are:
- USER_CREATED
- USER_UPDATED
- USER_DESTROYED

This will live under `RailsOutbox::Events` wherever you include the `Outboxable` concern. The intent is to define it under `Object` for non-namespaced models, as well as under each model namespace that is encountered.

### Custom Events
If you want to persist a custom event other than the provided base events, you can do so.
```ruby
user.save(outbox_event: 'YOUR_CUSTOM_EVENT')
```
## Advanced Usage
### Supporting UUIDs
By default our Outbox migration has an `aggregate_identifier` field which serves the purpose of identifying which record was involved in the event emission. We default to integer IDs, but if you're using UUIDs as a primary key for your records you have to adjust the migrations accordingly. To do so just run the model generator with the `--uuid` flag.
```bash
rails g rails_outbox:model <optional model_name> --uuid
```
### Modularized Outbox Mappings
If more granularity is desired multiple outbox classes can be configured. Using the provided generators we can specify namespaces and the folder structure.
```bash
rails g rails_outbox:model user_access/ --component-path packs/user_access

  create  packs/user_access/db/migrate/20231115181205_rails_outbox_create_user_access_outboxes.rb
  create  packs/user_access/app/models/user_access/outbox.rb
```
After creating the needed `Outbox` classes for each module you can specify multiple mappings in the initializer.
```ruby
# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  RailsOutbox.configure do |config|
    config.outbox_mapping = {
      'member' => 'Member::Outbox',
      'user_access' => 'UserAccess::Outbox'
    }
  end
end
```
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guillermoap/rails_outbox. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/guillermoap/rails_outbox/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/license/mit/).

## Code of Conduct

Everyone interacting in the RailsOutbox project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/guillermoap/rails_outbox/blob/main/CODE_OF_CONDUCT.md).
