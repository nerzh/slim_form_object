module SlimFormObject
  class Validator
    include ::HelperMethods

    attr_reader :form_object, :params, :not_save_if_empty_arr, :not_save_if_nil_arr, :data_objects_arr

    def initialize(form_object)
      @form_object                          = form_object
      @params                               = form_object.params
      @data_objects_arr                     = form_object.data_objects_arr
      @not_save_if_empty_arr                = form_object.not_save_if_empty_arr
      @not_save_if_nil_arr                  = form_object.not_save_if_nil_arr
    end

    def validate_form_object
      form_object.before_validation_form_block.call(form_object)
      validation_objects(data_objects_arr)
      form_object.after_validation_form_block.call(form_object)
    end

    def allow_to_save_object?(object)
      form_object.allow_to_save_object_block.call(object)
    end

    def allow_to_associate_objects?(object_1, object_2)
      form_object.allow_to_associate_objects_block.call(object_1, object_2)
    end

    private

    def validation_objects(objects)
      objects.each do |data_object|
        set_errors( snake(data_object.model), data_object.associated_object.errors ) unless data_object.associated_object.valid?
        validation_objects(data_object.nested)
      end
    end

    def set_errors(object_name, object_errors)
      object_errors.each do |attribute, message|
        form_object.errors.add(object_name, { attribute => message})
      end
    end
  end
end



