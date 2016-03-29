$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'slim_form_object'
require 'bundler/setup'
require 'active_record'
require 'rspec/collection_matchers'
require 'helpers/connect_to_base'

RSpec.configure do |config|

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

end
