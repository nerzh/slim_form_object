module SlimFormObject
  class Validator
    include ::HelperMethods

    attr_reader :form_object, :params, :save_if_empty_arr, :save_if_nil_arr, :base_module, :data_with_attributes

    def initialize(form_object)
      @form_object                          = form_object
      @base_module                          = form_object.class.base_module
      @params                               = form_object.params
      @data_with_attributes                 = form_object.data_with_attributes
      @save_if_empty_arr                    = form_object.save_if_empty_arr
      @save_if_nil_arr                      = form_object.save_if_nil_arr
    end

    def validate_form_object
      form_object.before_validation_form_block.call(form_object)
      validation_objects(data_with_attributes)
      form_object.after_validation_form_block.call(form_object)
    end

    def save_if_nil_or_empty?(object)
      condition_1 = (save_if_empty_arr.include?(object.class) or !all_attributes_is_empty?(object))
      condition_2 = (save_if_nil_arr.include?(object.class) or !all_attributes_is_nil?(object))

      condition_1 and condition_2
    end

    def allow_to_save_object?(object)
      form_object.allow_to_save_object_block.call(object)
    end

    def allow_to_associate_objects?(object_1, object_2)
      form_object.allow_to_associate_objects_block.call(object_1, object_2)
    end

    private

    def validation_objects(nested_array)
      byebug
      nested_array.each do |hash|
        set_errors( snake(hash[:object].class), hash[:object].errors ) unless hash[:object].valid?
        validation_objects(hash[:nested])
      end
    end

    def all_attributes_is_nil?(object)
      object.class.column_names.each do |attr_name|
        return false if object.send(attr_name.to_sym) != nil
      end
      true
    end

    def all_attributes_is_empty?(object)
      object.class.column_names.each do |attr_name|
        return false if object.send(attr_name.to_sym) != nil and object.send(attr_name.to_sym)&.to_s&.strip != ''
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



