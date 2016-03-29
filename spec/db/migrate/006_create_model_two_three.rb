
class CreateModelTwoThree < ActiveRecord::Migration
  def self.up
    create_table :test_three_model_test_two_models do |t|
      t.integer :test_three_model_id
      t.integer :test_two_model_id
    end
  end
 
  def self.down
    drop_table :test_three_model_test_two_model
  end
end