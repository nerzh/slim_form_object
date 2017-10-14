module SlimFormObject
  class Validator
    include ::HelperMethods

    attr_reader :form_object, :params, :array_models_which_not_save_if_empty, :base_module, :data_for_save

    def initialize(form_object)
      @form_object                          = form_object
      @base_module                          = form_object.class.base_module
      @params                               = form_object.params
      @data_for_save                        = form_object.data_for_save
      @array_models_which_not_save_if_empty = form_object.array_models_which_not_save_if_empty
    end

    def validate_form_object
      form_object.before_validation_form_block.call(form_object)
      validation_objects(data_for_save)
      form_object.after_validation_form_block.call(form_object)
    end

    def save_if_object_is_empty?(object)
      !(all_attributes_is_nil?(object) and array_models_which_not_save_if_empty.include?(object.class))
    end

    def allow_to_save_object?(object)
      form_object.allow_to_save_object_block.call(object)
    end

    def allow_to_associate_objects?(object_1, object_2)
      form_object.allow_to_associate_objects_block.call(object_1, object_2)
    end

    private

    def validation_objects(nested_array)
      nested_array.each do |hash|
        set_errors( snake(hash[:essence][:object].class), hash[:essence][:object].errors ) unless hash[:essence][:object].valid?
        validation_objects(hash[:nested])
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



