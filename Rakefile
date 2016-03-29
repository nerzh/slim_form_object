require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'yaml'
require 'active_record'
require_relative 'spec/helpers/connect_to_base'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :db do
  desc "Migrate the database"
  task :migrate do
    ActiveRecord::Base.establish_connection dbconfig['test']
    ActiveRecord::Migrator.migrate('/spec/db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
  end
end

namespace :db do
  desc "Create the database"
  task :create do
    ActiveRecord::Base.establish_connection dbconfig['test'].merge('database' => 'postgres')
    ActiveRecord::Base.connection.create_database dbconfig['test']['database']
    ActiveRecord::Base.establish_connection dbconfig['test']
  end
end

namespace :db do
  desc "Drop the database"
  task :drop do
    ActiveRecord::Base.establish_connection dbconfig['test'].merge('database' => 'postgres')
    ActiveRecord::Base.connection.drop_database dbconfig['test']['database']
  end
end

namespace :db do
  desc "Setup the database"
  task :setup do
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end
end