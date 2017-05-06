
class CreateModelFour < ActiveRecord::Migration[5.0]
  def self.up
    create_table :test_four_models do |t|
      t.string :title
      t.string :descr
    end
  end
 
  def self.down
    drop_table :test_four_model
  end
end