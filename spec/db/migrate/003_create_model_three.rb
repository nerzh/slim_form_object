
class CreateModelThree < ActiveRecord::Migration
  def self.up
    create_table :test_three_models do |t|
      t.string  :title
      t.string  :descr
      t.integer :test_one_model_id
    end
  end
 
  def self.down
    drop_table :test_three_model
  end
end