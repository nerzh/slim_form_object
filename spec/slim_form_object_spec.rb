require 'spec_helper'
require 'helpers/models'

class TestModule < SlimFormObject::Base
  init_models TestOneModel, TestTwoModel, TestThreeModel, TestFourModel
end

describe TestModule, enviroment: :test do

  let!(:object) { TestModule.new }
  let!(:saver)  { SlimFormObject::Saver.new(object) }

  it { expect(TestModule).to include(ActiveModel::Model) }
  it { expect(TestModule).to be < SlimFormObject::Base }

  it 'has a version number' do
    expect(SlimFormObject::VERSION).not_to be nil
  end

  context 'get_association' do
    it 'model1 has_one model2' do
      association = saver.send :get_association, TestOneModel, TestTwoModel
      expect(association).to eq(:has_one)
    end

    it 'model2 belongs_to model1' do
      association = saver.send :get_association, TestTwoModel, TestOneModel
      expect(association).to eq(:belongs_to)
    end

    it 'model1 has_many model3' do
      association = saver.send :get_association, TestOneModel, TestThreeModel
      expect(association).to eq(:has_many)
    end

    it 'model3 belongs_to model1' do
      association = saver.send :get_association, TestThreeModel, TestOneModel
      expect(association).to eq(:belongs_to)
    end

    it 'model1 has_many :test_four_models, through: :test_one_four_models' do
      association = saver.send :get_association, TestOneModel, TestFourModel
      expect(association).to eq(:has_many)
    end

    it 'model2 has_and_belongs_to_many model3' do
      association = saver.send :get_association, TestTwoModel, TestThreeModel
      expect(association).to eq(:has_and_belongs_to_many)
    end

    it 'model3 has_and_belongs_to_many model2' do
      association = saver.send :get_association, TestThreeModel, TestTwoModel
      expect(association).to eq(:has_and_belongs_to_many)
    end

    it 'model3 has_and_belongs_to_many model2' do
      association = saver.send :get_association, TestThreeModel, TestTwoModel
      expect(association).to eq(:has_and_belongs_to_many)
    end

    it 'model4 has_many :test_one_models, through: :test_one_four_models' do
      association = saver.send :get_association, TestFourModel, TestOneModel
      expect(association).to eq(:has_many)
    end

    it 'model1-4 belongs_to model1' do
      association = saver.send :get_association, TestOneFourModel, TestOneModel
      expect(association).to eq(:belongs_to)
    end

    it 'model1-4 belongs_to model4' do
      association = saver.send :get_association, TestOneFourModel, TestFourModel
      expect(association).to eq(:belongs_to)
    end

    it 'model1 has_many model1-4' do
      association = saver.send :get_association, TestOneModel, TestOneFourModel
      expect(association).to eq(:has_many)
    end

    it 'model4 has_many model1-4' do
      association = saver.send :get_association, TestFourModel, TestOneFourModel
      expect(association).to eq(:has_many)
    end

    it 'model2 don\'t have model4' do
      association = saver.send :get_association, TestTwoModel, TestFourModel
      expect(association).to eq(nil)
    end

  end

  context 'init_models' do
    class Test < SlimFormObject::Base; end
    Test.init_models(TestOneModel, TestTwoModel)
    object = Test.new

    it 'init variable @models' do
      expect( object.array_of_all_models ).to eq([TestOneModel, TestTwoModel])
    end

    it 'must be called add_attributes' do
      expect(object.class).to receive(:define_array_of_models).and_return(true)
      object.class.init_models(TestOneModel, TestTwoModel)
    end
  end

  context 'snake' do
    it { expect( object.class.snake(TestOneModel.to_s) ).to eq('test_one_model') }
    it { expect( object.class.snake('123_Asd') ).to eq('123__asd') }
    it { expect( object.class.snake('_zA') ).to eq('_z_a') }
    it { expect( object.class.snake('_zA12') ).to eq('_z_a12') }
    it { expect( object.class.snake('_zA-12_') ).to eq('_z_a-12_') }
  end

  context 'add_attributes' do
    class Test2 < SlimFormObject::Base; end
    Test2.init_models()
    object = Test2.new

    it 'attributes do not exist' do
      expect(object.respond_to? :params).to eq(true)
      expect(object.respond_to? :test_one_model_title).to eq(false)
      expect(object.respond_to? :test_two_model_title).to eq(false)
      expect(object.respond_to? :test_three_model_title).to eq(false)
      expect(object.respond_to? :test_four_model_title).to eq(false)
    end

    it 'attributes exist' do
      object.class.init_models(TestOneModel, TestTwoModel)

      expect(object.respond_to? :params).to eq(true)
      expect(object.respond_to? :test_one_model_title).to eq(true)
      expect(object.respond_to? :test_one_model_descr).to eq(true)
      expect(object.respond_to? :test_two_model_title).to eq(true)
      expect(object.respond_to? :test_two_model_descr).to eq(true)
      expect(object.respond_to? :test_two_model_test_one_model_id).to eq(true)
    end
  end

  context 'set_errors' do
    before :each do
      @test_object = TestModule.new
      @validator   = SlimFormObject::Validator.new(@test_object)
    end
    
    it 'errors is present' do
      error = {title: "can't be blank"}
      @validator.send :set_errors, 'object_name', error

      expect( @test_object.errors.messages ).to eq( {object_name: [{title: "can't be blank"}]} )
    end

    it 'errors is not exist' do
      expect( @test_object.errors.messages ).to eq( {} )
    end
  end

  context 'update_attributes' do
    # it 'must call this methods' do
    #   attributes_of_model = ["test_one_model_id", "test_one_model_title", "test_one_model_descr"]
    #   attributes_for_update = {"title"=>"Test Title", "descr"=>"Test Descr"}
    #
    #   object.instance_eval{ @array_of_models = [TestOneModel] }
    #   expect(object).to receive(:make_attributes_of_model).and_return( attributes_of_model )
    #   expect(object).to receive(:get_attributes_for_update).and_return( attributes_for_update )
    #   object.stub(:test_one_model).and_return( TestOneModel.new )
    #   object.send :update_attributes
    # end
  end

  context 'get_attributes_for_update' do
    # it 'make attributes for update model' do
    #   object.stub(:params).and_return( {'test_one_model_title'=>'Test Title', 'test_one_model_descr'=>'Test Descr'} )
    #   model_attributes = ["test_one_model_id", "test_one_model_title", "test_one_model_descr"]
    #   update_attributes = object.send :get_attributes_for_update, model_attributes, TestOneModel
    #
    #   expect(update_attributes).to eq( {"title"=>"Test Title", "descr"=>"Test Descr"} )
    # end
  end

  context 'make_attributes_of_model' do
    # it 'make attributes of model' do
    #   update_attributes = object.send :make_attributes_of_model, TestOneModel
    #
    #   expect(update_attributes).to eq( ["test_one_model_id", "test_one_model_title", "test_one_model_descr"] )
    # end
  end

end








