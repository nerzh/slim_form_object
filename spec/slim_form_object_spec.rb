require 'spec_helper'
require 'helpers/models'

class TestModule
end

describe TestModule do

  include SlimFormObject

  it 'has a version number' do
    expect(SlimFormObject::VERSION).not_to be nil
  end

  context 'get_association' do
    it 'model1 has_one model2' do
      association = send :get_association, TestOneModel, TestTwoModel
      expect(association).to eq(:has_one)
    end

    it 'model2 belongs_to model1' do
      association = send :get_association, TestTwoModel, TestOneModel
      expect(association).to eq(:belongs_to)
    end

    it 'model1 has_many model3' do
      association = send :get_association, TestOneModel, TestThreeModel
      expect(association).to eq(:has_many)
    end

    it 'model3 belongs_to model1' do
      association = send :get_association, TestThreeModel, TestOneModel
      expect(association).to eq(:belongs_to)
    end

    it 'model1 has_many :test_four_models, through: :test_one_four_models' do
      association = send :get_association, TestOneModel, TestFourModel
      expect(association).to eq(:has_many)
    end

    it 'model2 has_and_belongs_to_many model3' do
      association = send :get_association, TestTwoModel, TestThreeModel
      expect(association).to eq(:has_and_belongs_to_many)
    end

    it 'model3 has_and_belongs_to_many model2' do
      association = send :get_association, TestThreeModel, TestTwoModel
      expect(association).to eq(:has_and_belongs_to_many)
    end

    it 'model3 has_and_belongs_to_many model2' do
      association = send :get_association, TestThreeModel, TestTwoModel
      expect(association).to eq(:has_and_belongs_to_many)
    end

    it 'model4 has_many :test_one_models, through: :test_one_four_models' do
      association = send :get_association, TestFourModel, TestOneModel
      expect(association).to eq(:has_many)
    end

    it 'model1-4 belongs_to model1' do
      association = send :get_association, TestOneFourModel, TestOneModel
      expect(association).to eq(:belongs_to)
    end

    it 'model1-4 belongs_to model4' do
      association = send :get_association, TestOneFourModel, TestFourModel
      expect(association).to eq(:belongs_to)
    end

    it 'model1 has_many model1-4' do
      association = send :get_association, TestOneModel, TestOneFourModel
      expect(association).to eq(:has_many)
    end

    it 'model4 has_many model1-4' do
      association = send :get_association, TestFourModel, TestOneFourModel
      expect(association).to eq(:has_many)
    end

    it 'model2 don\'t have model4' do
      association = send :get_association, TestTwoModel, TestFourModel
      expect(association).to eq(nil)
    end

  end

  context 'init_models' do
    it 'init variable @models' do
      self.class.init_models(TestOneModel, TestTwoModel)
      expect( self.class.instance_variable_get(:@models) ).to eq([TestOneModel, TestTwoModel])
    end

    it 'must be called add_attributes' do
      expect(self.class).to receive(:add_attributes).and_return(true)
      self.class.init_models(TestOneModel, TestTwoModel)
    end
  end

end
