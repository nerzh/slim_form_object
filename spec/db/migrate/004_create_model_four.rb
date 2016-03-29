
class CreateModelFour < ActiveRecord::Migration
  def self.up
    create_table :test_four_model do |t|
      t.string :title
      t.string :descr
    end
  end
 
  def self.down
    drop_table :test_four_model
  end
end