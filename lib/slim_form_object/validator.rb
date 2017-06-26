module SlimFormObject
  class Validator
    include ::HelperMethods

    attr_reader   :form_object, :params, :hash_objects_for_save, :array_models_which_not_save_if_empty

    def initialize(form_object)
      @form_object                          = form_object
      @params                               = form_object.params
      @hash_objects_for_save                = form_object.hash_objects_for_save
      @array_models_which_not_save_if_empty = form_object.array_models_which_not_save_if_empty
    end

    def validate_form_object
      filter_models
      validation_objects
      validation_nested_objects
    end

    def valid_model_for_save?(object)
      true
    end

    private

    def validation_objects
      hash_objects_for_save[:objects].each do |object|
        set_errors( snake(object.class), object.errors ) unless object.valid?
      end
    end

    def validation_nested_objects
      hash_objects_for_save[:nested_objects].keys.each do |snake_model_name|
        hash_objects_for_save[:nested_objects][snake_model_name].each do |object|
          set_errors( snake(object.class), object.errors ) unless object.valid?
        end
      end
    end

    def filter_models
      filter_nil_objects
    end

    def filter_nil_objects
      hash_objects_for_save[:objects].reject! do |object|
        !save_if_object_is_empty?(object)
      end
    end

    def all_attributes_is_nil?(object)
      object.class.column_names.each do |attr_name|
        return false if object.send(attr_name.to_sym) != nil
      end
      true
    end

    def save_if_object_is_empty?(object)
      !(all_attributes_is_nil?(object) and array_models_which_not_save_if_empty.include?(object.class))
    end

    def set_errors(object_name, object_errors)
      object_errors.each do |attribute, message|
        form_object.errors.add(object_name, { attribute => message})
      end
    end

  end
end



