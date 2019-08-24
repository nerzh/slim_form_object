module SlimFormObject
  class Validator
    include ::HelperMethods

    attr_reader :form_object, :data_objects_arr

    def initialize(form_object)
      @form_object                          = form_object
      @data_objects_arr                     = form_object.data_objects_arr
    end

    def validate_form_object
      validation_objects(data_objects_arr)
      form_object.after_validation_form_block.call(form_object)
    end

    def allow_to_save_object?(object, form_object)
      form_object.allow_to_save_object_block.call(object, form_object)
    end

    def allow_to_validate_object?(data_object)
      form_object.allow_to_validate_object_block.call(data_object) 
    end

    def empty_attributes?(attributes)
      attributes.empty?
    end

    def only_blank_strings_in_attributes?(attributes)
      return false if empty_attributes?(attributes)
      attributes.each { |key, value| return false if value&.to_s&.strip != '' }
      true
    end

    def only_blank_or_empty_attributes(attributes)
      empty_attributes?(attributes) or only_blank_strings_in_attributes?(attributes)
    end

    def blank_or_empty_object?(data_object, except_fileds: [])
      attributes = data_object.attributes.reject { |key| except_fileds.map{|name| name.to_s }.include?(key.to_s) }
      only_blank_or_empty_attributes(attributes) and data_object.nested.empty?
    end

    def allow_object_processing?(data_object)
      form_object.allow_object_processing_block.call(data_object)
    end

    private

    def validation_objects(objects)
      objects.each do |data_object|
        next unless allow_to_validate_object?(data_object)
        set_errors( snake(data_object.model), data_object.object.errors ) unless data_object.object.valid?
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



