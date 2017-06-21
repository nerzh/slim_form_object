module SlimFormObject
  class Validator
    include ::HelperMethods

    attr_reader   :params
    attr_accessor :array_objects_for_save

    def initialize(form_object, params, array_objects_for_save = [])
      @params                 = params
      @array_objects_for_save = array_objects_for_save
    end

    def validate_form_object
      byebug
      array_objects_for_save.each do |object|
        next unless valid_model_for_save?( object )
        form_object.set_errors( object.errors ) unless object.valid?
      end
    end

    def valid_model_for_save?(object)
      ( (attributes_is_present?(object) and object.id != nil) or (object.id == nil and !all_attributes_is_empty?(object)) )
    end

    def attributes_is_present?(object)
      (get_names_form_attributes_of(object.class) & params.keys).present?
    end

    def both_model_attributes_exist?(object_1, object_2)
      valid_model_for_save?(object_1) and valid_model_for_save?(object_2)
    end

    def all_attributes_is_empty?(object)
      is_empty = true
      array_symbols_of_attributes = (get_names_form_attributes_of(object.class) & params.keys).map { |attr| attr.to_sym }
      params.slice(*array_symbols_of_attributes).values.each do |value|
        is_empty = false unless value == ""
      end
      is_empty
    end

  end
end