module SlimFormObject
  class Validator
    include ::HelperMethods

    attr_reader   :form_object, :params, :hash_objects_for_save

    def initialize(form_object)
      @form_object           = form_object
      @params                = form_object.params
      @hash_objects_for_save = form_object.hash_objects_for_save
    end

    def validate_form_object
      filter_nil_objects

      hash_objects_for_save[:objects].each do |object|
        next if all_attributes_is_nil?(object)
        set_errors( snake(object.class), object.errors ) unless object.valid?
      end

      hash_objects_for_save[:nested_objects].keys.each do |snake_model_name|
        hash_objects_for_save[:nested_objects][snake_model_name].each do |object|
          set_errors( snake(object.class), object.errors ) unless object.valid?
        end
      end
    end

    def valid_model_for_save?(object)
      true
    end

    private

    def filter_nil_objects
      hash_objects_for_save[:objects].reject! do |object|
        all_attributes_is_nil?(object)
      end
    end

    def all_attributes_is_nil?(object)
      object.class.column_names.each do |attr_name|
        return false if object.send(attr_name.to_sym) != nil
      end
      true
    end

    def set_errors(object_name, object_errors)
      object_errors.each do |attribute, message|
        form_object.errors.add(object_name, { attribute => message})
      end
    end

  end
end



