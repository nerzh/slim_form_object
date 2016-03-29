
class CreateModelOne < ActiveRecord::Migration
  def self.up
    create_table :test_one_models do |t|
      t.string :title
      t.string :descr
    end
  end
 
  def self.down
    drop_table :test_one_model
  end
end