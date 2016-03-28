class TestOneModel < ActiveRecord::Base
  has_one  :test_two_model
  has_many :test_three_models
  has_many :test_four_models, through: :test_one_four_models
end

class TestTwoModel < ActiveRecord::Base
  belongs_to :test_one_model
  has_and_belongs_to_many :test_three_models
end

class TestThreeModel < ActiveRecord::Base
  belongs_to :test_one_model
  has_and_belongs_to_many :test_two_models
end

class TestFourModel < ActiveRecord::Base
  has_many :test_one_models, through: :test_one_four_models
end

class TestOneFourModel < ActiveRecord::Base
  belongs_to :test_one_model
  belongs_to :test_four_model
end