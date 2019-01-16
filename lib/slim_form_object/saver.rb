module SlimFormObject
  class Saver
    include ::HelperMethods

    attr_reader :form_object, :params, :validator, :base_module, :data_with_attributes

    def initialize(form_object)
      @form_object           = form_object
      @base_module           = form_object.class.base_module
      @params                = form_object.params
      @data_with_attributes  = form_object.data_with_attributes
      @validator             = Validator.new(form_object)
    end

    def save
      if form_object.valid?
        save_all
        return true
      end
      false
    rescue
      false
    end

    def save!
      if form_object.valid?
        save_all
      end
      true
    end

    private

    def save_all
      ActiveRecord::Base.transaction do
        form_object.before_save_form_block.call(form_object)
        save_main_objects
        save_nested_objects
        form_object.after_save_form_block.call(form_object)
      end
    end

    def save_main_objects
      objects = Array.new(data_with_attributes)
      while object = objects.delete( objects[0] )
        object_1 = object[:object]
        objects.each { |hash| save_objects(object_1, hash[:object]) }
        save_last_model_if_not_associations(object_1)
      end
    end

    def save_nested_objects
      data_with_attributes.each do |main_object|
        main_object[:nested].each do |object|
          save_object(object[:object])
        end
      end
    end

    def save_objects(object_1, object_2)
      object_for_save = to_bind_models(object_1, object_2)
      save_object(object_for_save)
    end

    def save_object(object_of_model)
      object_of_model.save! if validator.allow_to_save_object?(object_of_model)
    end

    def save_last_model_if_not_associations(object_1)
      association_trigger = false
      data_with_attributes.each { |hash| association_trigger = true if get_reflection(object_1.class, hash[:object].class) }
      save_object(object_1) unless association_trigger
    end
  end
end