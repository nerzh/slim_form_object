module SlimFormObject
  class Validator
    include ::HelperMethods

    attr_reader   :form_object, :params, :hash_objects_for_save

    def initialize(form_object)
      @form_object            = form_object
      @params                 = form_object.params
      @hash_objects_for_save  = form_object.hash_objects_for_save
    end

    def validate_form_object
      filter_nil_objects

      hash_objects_for_save[:objects].each do |object|
        next if all_attributes_is_nil?(object)
        form_object.set_errors( object.errors ) unless object.valid?
      end

      hash_objects_for_save[:nested_objects].keys do |snake_model_name|
        hash_objects_for_save[:nested_objects][model_name].keys.each do |object_name|
          hash_objects_for_save[:nested_objects][model_name][object_name].each do |object|
            form_object.set_errors( object.errors ) unless object.valid?   
          end
        end
      end
    end

    def filter_nil_objects
      hash_objects_for_save[:objects].reject! do |object|
        all_attributes_is_nil?(object)
      end
    end

    def valid_model_for_save?(object)
      # ( (attributes_is_present?(object) and object.id != nil) or (object.id == nil and !all_attributes_is_empty?(object)) )
      true
    end

    def both_model_attributes_exist?(object_1, object_2)
      # valid_model_for_save?(object_1) and valid_model_for_save?(object_2)
      !(all_attributes_is_nil?(object_1) and all_attributes_is_nil?(object_2))
    end

    def all_attributes_is_nil?(object)
      object.class.column_names.each do |attr_name|
        return false if object.send(attr_name.to_sym) != nil
      end
      true
    end

  end
end



