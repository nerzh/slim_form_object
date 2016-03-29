
class CreateModelOneFour < ActiveRecord::Migration
  def self.up
    create_table :test_one_four_models do |t|
      t.integer :test_one_model_id
      t.integer :test_four_model_id
    end
  end
 
  def self.down
    drop_table :test_one_four_model
  end
end