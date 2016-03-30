require 'spec_helper'
require 'helpers/models'
require 'byebug'

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

  context 'snake' do
    it { expect( self.class.snake(TestOneModel.to_s) ).to eq('test_one_model') }
    it { expect( self.class.snake('123_Asd') ).to eq('123__asd') }
    it { expect( self.class.snake('_zA') ).to eq('_z_a') }
    it { expect( self.class.snake('_zA12') ).to eq('_z_a12') }
    it { expect( self.class.snake('_zA-12_') ).to eq('_z_a-12_') }
  end

  context 'add_attributes' do
    it 'attributes do not exist' do
      expect(self.respond_to? :params).to eq(false)
      expect(self.respond_to? :test_one_model_title).to eq(false)
      expect(self.respond_to? :test_one_model_descr).to eq(false)
    end

    it 'attributes exist' do
      self.class.instance_variable_set(:@models, [TestOneModel, TestTwoModel])
      self.class.add_attributes
      expect(self.respond_to? :params).to eq(true)
      expect(self.respond_to? :test_one_model_title).to eq(true)
      expect(self.respond_to? :test_one_model_descr).to eq(true)
      expect(self.respond_to? :test_two_model_title).to eq(true)
      expect(self.respond_to? :test_two_model_descr).to eq(true)
      expect(self.respond_to? :test_two_model_test_one_model_id).to eq(true)
    end
  end

  context 'get_models' do
    self.class_eval {@models = [TestOneModel, TestTwoModel]}
    models = self.new.send :get_models
    it { expect( models ).to eq( [TestOneModel, TestTwoModel] ) }
  end

end
