$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'slim_form_object'
require 'bundler/setup'
require 'active_record'
require 'rspec/collection_matchers'
require 'database_cleaner'
require 'helpers/connect_to_base'
require 'byebug'

RSpec.configure do |config|

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.before(:suite) do
    ActiveRecord::Base.establish_connection dbconfig['test']
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

end
