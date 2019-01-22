module SlimFormObject
  class Saver
    include ::HelperMethods

    attr_reader :form_object, :params, :validator, :data_objects_arr

    STAGE_3 = 3

    def initialize(form_object)
      @form_object                     = form_object
      @params                          = form_object.params
      @data_objects_arr                = form_object.data_objects_arr
      @validator                       = Validator.new(form_object)
    end

    def save
      if form_object.valid?
        _save
        return true
      end
      false
    rescue
      false
    end

    def save!
      if form_object.valid?
        _save
      end
      true
    end

    private

    def regenerate_objects_with_attributes(objects)
      objects.each do |object|
        object.regenerate_object
        object.assign_attributes!
        regenerate_objects_with_attributes(object.nested)
      end
    end

    def _save
      regenerate_objects_with_attributes(data_objects_arr)

      ActiveRecord::Base.transaction do
        stage_1(data_objects_arr)
        stage_2(data_objects_arr)
        stage_3(data_objects_arr)
        form_object.after_save_form_block.call(form_object)
      end
    end

    # association per parent with all nested objects
    def stage_1(objects)
      objects.each do |data_object|
        data_object.nested.each do |nested_data_object|
          data_object.associate_with(nested_data_object.object)
        end
        stage_1(data_object.nested)
      end
    end

    # save all objects
    def stage_2(objects)
      objects.each do |data_object|
        stage_2(data_object.nested)
        save_object(data_object.object)
      end
    end

    # associate and save between a nested objects
    def stage_3(objects)
      associate_and_save_objects(objects)

      objects.each do |data_object|
        stage_3(data_object.nested)
      end
    end

    def associate_and_save_objects(data_objects)
      objects = Array.new(data_objects)
      while data_object_1 = objects.delete( objects[0] )
        objects.each do |data_object_2|
          obj = data_object_1.associate_with(data_object_2.object, stage: STAGE_3)
          save_object(obj)
        end
      end
    end

    def save_object(object_of_model)
      if validator.allow_to_save_object?(object_of_model)
          object_of_model.save!
      end
    end

  end
end