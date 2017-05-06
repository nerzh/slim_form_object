
class CreateModelTwo < ActiveRecord::Migration[5.0]
  def self.up
    create_table :test_two_models do |t|
      t.string  :title
      t.string  :descr
      t.integer :test_one_model_id
    end
  end
 
  def self.down
    drop_table :test_two_model
  end
end