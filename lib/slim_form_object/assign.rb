module SlimFormObject
  class Assign
    include ::HelperMethods

    attr_reader :form_object, :params, :array_all_objects_for_save, :array_not_save_model, :result_array_updated_objects
    # attr_accessor :array_all_objects_for_save

    def initialize(form_object, params, array_all_objects_for_save, array_not_save_model)
      @form_object                  = form_object
      @params                       = params
      @array_all_objects_for_save   = array_all_objects_for_save
      @array_not_save_model         = array_not_save_model
      @result_array_updated_objects = []
    end

    def apply_parameters
      filter_not_save_objects
      update_attributes_single_models
      update_attributes_for_multiple_models

      update_attributes_for_collection

      result_array_updated_objects
    end

    def filter_not_save_objects
      array_all_objects_for_save.reject do |object|
        array_not_save_model.include?(object.class)
      end
    end

    # STANDART OBJECTS

    def update_attributes_single_models
      array_all_objects_for_save.each do |object|
        object.assign_attributes( hash_attributes_from_params_for_update(object) )
        result_array_updated_objects << object
      end

      form_object.array_objects_for_save = result_array_updated_objects
    end

    def hash_attributes_from_params_for_update(object)
      attributes_for_update = {}
      model_attributes      = get_names_form_attributes_of(object.class)
      hash_attributes       = params.slice(*model_attributes)
      hash_attributes.each{ |attr, val| attributes_for_update[attr.gsub(/#{snake(object.class.to_s)}_(.*)/, '\1')] = val }
      attributes_for_update
    end


    # MULTIPLE OBJECTS

    def update_attributes_for_multiple_models
      params.keys.each do |key|
        if params[key].class == Array and params[key].first.class == ActionController::Parameters
          params[key].each do |parameters|
            object = get_class_of_snake_model_name(key).new
            object.assign_attributes(JSON.parse(parameters.to_json))
            result_array_updated_objects << object
          end
        end
      end

      form_object.array_objects_for_save = result_array_updated_objects
    end


    # OBJECTS HAS COLLECTION

    def update_attributes_for_collection
      array_all_objects_for_save.each do |object|
        assign_attributes_for_collection(object)
      end

      form_object.array_objects_for_save = result_array_updated_objects
    end

    def assign_attributes_for_collection(object)
      form_object.array_objects_for_save = result_array_updated_objects

      real_name_keys_of_collections.each do |method_name|
        if object.respond_to?(method_name)
          old_attribute = object.method( method_name ).call
          unless exist_any_errors_without_collections?
            unless object.update_attributes( {method_name.to_s => params["#{snake(object.class.to_s)}_#{method_name}".to_sym]} )
              form_object.send( :set_errors, object.errors)
              object.update_attributes( {method_name.to_s => old_attribute} )
            end
          end
        end
      end
    end

    def real_name_keys_of_collections
      @keys ||= []
      params.keys.each do |key|
        array_all_objects_for_save.each do |object|
          method_name = key.to_s[/#{snake(object.class.to_s)}_(.*)/, 1]
          @keys << method_name if object.respond_to?(method_name.to_s)
        end if key[/^.+_ids$/]
      end if @keys.empty?
      @keys
    end

    def exist_any_errors_without_collections?
      unless form_object.valid?
        real_name_keys_of_collections.each do |method_name|
          name_of_model     = method_name.to_s[/^(.+)_ids$/, 1]
          name_of_key_error = get_class_of_snake_model_name(name_of_model).table_name
          form_object.errors.messages.delete(name_of_key_error.to_sym)
        end
      end
      form_object.errors.messages.present?
    end

  end
end








