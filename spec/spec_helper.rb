$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bundler/setup'
require 'byebug'
require 'yaml'
require 'active_record'
require 'database_cleaner'
require 'rspec/collection_matchers'
require 'helpers/connect_to_base'
require 'slim_form_object'

RSpec.configure do |config|
  ActiveRecord::Base.establish_connection( dbconfig['test'] )

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.before(:suite) do
    # ActiveRecord::Base.establish_connection( dbconfig['test'] )
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

end
