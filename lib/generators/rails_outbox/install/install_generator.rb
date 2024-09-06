# frozen_string_literal: true

require 'rails/generators/base'

module RailsOutbox
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __dir__)

      desc 'Creates an initializer file at config/initializers/rails_outbox.rb'

      def create_initializer_file
        copy_file('initializer.rb', Rails.root.join('config', 'initializers', 'rails_outbox.rb'))
      end
    end
  end
end
