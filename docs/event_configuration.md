# RailsOutbox Advanced Usage Guide

## Event Emission Configuration

### Column-Specific Events

When tracking column changes, there are two main scenarios: default events and custom events. The behavior differs significantly between these:

```ruby
class Post < ApplicationRecord
  include RailsOutbox::Outboxable

  # Scenario 1: Default Event for Column
  emits_on update: {
    column: {
      name: :title,
      event: :default
    }
  }
  # Result: Emits POST_UPDATED only when title changes

  # Scenario 2: Custom Event for Column
  emits_on :update,
           update: {
             column: {
               name: :status,
               event: :status_changed
             }
           }
  # Result: 
  # - Emits POST_STATUS_CHANGED when status changes
  # - Emits POST_UPDATED for any update (including status)
end
```

### Event Merging Rules

The gem follows specific rules when merging multiple event configurations:

```ruby
# Rule 1: Custom column events coexist with default events
emits_on update: { column: { name: :status, event: :status_changed } }
emits_on :update
# Result: Both events will fire on status changes

# Rule 2: Default column events prevent duplicate default events
emits_on update: { column: { name: :title, event: :default } }
emits_on :update
# Result: Only column-specific event fires on title changes

# Rule 3: Later configs don't override column-specific configs
emits_on update: { column: { name: :status, event: :status_changed } }
emits_on :update
emits_on :update
# Column config is preserved
```

### Multiple Column Tracking

You can track multiple columns with different event configurations:

```ruby
class Post < ApplicationRecord
  include RailsOutbox::Outboxable

  emits_on(
    # Default tracking for basic changes
    :create,
    :destroy,
    
    # Status changes emit custom event + default event
    update: {
      column: {
        name: :status,
        event: :status_changed
      }
    },
    
    # Title changes only emit default event
    update: {
      column: {
        name: :title,
        event: :default
      }
    },
    
    # Published changes emit custom event + default event
    update: {
      column: {
        name: :published,
        event: :publication_changed
      }
    }
  )
end
```

### Event Emission Timing

Events are emitted based on transaction state:

```ruby
class Post < ApplicationRecord
  include RailsOutbox::Outboxable

  # Track transaction states
  emits_on :commit, :rollback

  # Combine with column tracking
  emits_on :commit,
           update: {
             column: {
               name: :status,
               event: :status_changed
             }
           }
end
```

### Complex Event Names

You can use custom event names in different formats:

```ruby
class Post < ApplicationRecord
  include RailsOutbox::Outboxable

  emits_on(
    # Simple custom event
    update: {
      column: {
        name: :status,
        event: :status_changed
      }
    },

    # Namespaced event
    update: {
      column: {
        name: :published,
        event: :'blog.post.published'
      }
    },

    # Event with version
    update: {
      column: {
        name: :title,
        event: :'v1.post.title_changed'
      }
    }
  )
end
```

## Event Emission Patterns

### Event Isolation

When you want to ensure events are emitted only for specific changes:

```ruby
class Post < ApplicationRecord
  include RailsOutbox::Outboxable

  # Only emit events for status changes
  emits_on update: {
    column: {
      name: :status,
      event: :status_changed
    }
  }
  # No events for other changes

  # Mix isolated and general tracking
  emits_on :create,  # Track all creates
           update: {
             column: {
               name: :status,
               event: :status_changed
             }
           }  # Only track status updates
end
```

### Conditional Event Emission

While the gem doesn't directly support conditional events, you can achieve this through model callbacks:

```ruby
class Post < ApplicationRecord
  include RailsOutbox::Outboxable

  emits_on update: {
    column: {
      name: :status,
      event: :status_changed
    }
  }

  before_save :check_status_change

  private

  def check_status_change
    return unless status_changed?
    
    # Customize event based on status
    case status
    when 'published'
      @outbox_event = 'POST_PUBLISHED'
    when 'archived'
      @outbox_event = 'POST_ARCHIVED'
    end
  end
end
```

## Best Practices

### Event Naming

1. Use consistent naming patterns:
```ruby
# Good
emits_on update: { column: { name: :status, event: :status_changed } }
emits_on update: { column: { name: :title, event: :title_updated } }

# Avoid
emits_on update: { column: { name: :status, event: :changed_status } }
emits_on update: { column: { name: :title, event: :update_title } }
```

2. Consider versioning in event names:
```ruby
emits_on update: {
  column: {
    name: :status,
    event: :'v1.post.status_changed'
  }
}
```

### Configuration Organization

1. Group related events:
```ruby
class Post < ApplicationRecord
  include RailsOutbox::Outboxable

  # Group by feature
  emits_on(
    # Publication events
    update: {
      column: {
        name: :published,
        event: :publication_changed
      }
    },
    update: {
      column: {
        name: :publish_at,
        event: :schedule_changed
      }
    },

    # Content events
    update: {
      column: {
        name: :title,
        event: :default
      }
    },
    update: {
      column: {
        name: :content,
        event: :default
      }
    }
  )
end
```

2. Use multiple `emits_on` calls for better organization:
```ruby
class Post < ApplicationRecord
  include RailsOutbox::Outboxable

  # Basic lifecycle events
  emits_on :create, :destroy

  # Publication events
  emits_on update: {
    column: {
      name: :published,
      event: :publication_changed
    }
  }

  # Content events
  emits_on update: {
    column: {
      name: :title,
      event: :default
    }
  }
end
```

### Performance Considerations

1. Avoid tracking unnecessary columns:
```ruby
# Bad: Tracks all updates
emits_on :update

# Better: Track only what you need
emits_on update: {
  column: {
    name: :status,
    event: :default
  }
}
```

2. Use default events when possible to reduce event volume:
```ruby
# Might generate too many events
emits_on :update,
         update: {
           column: {
             name: :title,
             event: :title_changed
           }
         }

# More efficient
emits_on update: {
  column: {
    name: :title,
    event: :default
  }
}
```

## Common Pitfalls

1. **Event Duplication**: Be careful when mixing column-specific and general events:
```ruby
# This will emit two events for status changes
emits_on :update,
         update: {
           column: {
             name: :status,
             event: :status_changed
           }
         }
```

2. **Missing Events**: Ensure you're tracking all necessary columns:
```ruby
# Only tracks title changes, misses other important changes
emits_on update: {
  column: {
    name: :title,
    event: :default
  }
}
```

3. **Overriding Configurations**: Later configurations don't override column-specific ones:
```ruby
# The :update won't override the column config
emits_on update: {
  column: {
    name: :status,
    event: :status_changed
  }
}
emits_on :update  # Adds default event tracking
```
