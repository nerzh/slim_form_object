module SlimFormObject
  class Assign
    include ::HelperMethods

    attr_reader :form_object, :params, :data_for_assign, :data_with_attributes, :base_module, :validator

    def initialize(form_object)
      @form_object                 = form_object
      @base_module                 = form_object.class.base_module
      @params                      = form_object.params
      @structure                   = form_object.data_structure
      @validator                   = Validator.new(form_object)
      @data_for_assign             = []
      @data_with_attributes        = []
    end

    def apply_parameters
      make_data_for_assign
      make_data_with_attributes
      delete_empty_objects(data_with_attributes)

      data_with_attributes
    end

    def associate_objects
      associate_all_objects(data_with_attributes)
      
      data_with_attributes
    end


    private

    def is_nested?(value)
      def nested?(e)
        e.class == ActionController::Parameters or e.class == Hash
      end

      return true if nested?(value)

      if value.class == Array
        value.select{ |e| nested?(e) }.size == value.size
      end
    end

    # data_for_assign format
    # 
    # [
    #   { :model      => Product(id: integer, category_id: integer, brand_id: integer), 
    #     :attributes => {:id=>"3871", :category_id=>"1", :brand_id=>"1"}, 
    #     :nested     => [ 
    #                      { :model      => FiltersProduct(id: integer, product_id: integer, filter_id: integer, value_id: integer), 
    #                        :attributes => {:id=>"", :product_id=>"111", filter_id: "222", value_id: "333"}, 
    #                        :nested     => []
    #                      }
    #                    ]
    #   }
    # ]
    def make_hash_objects_and_nested_objects(key_params, value_params)
      model      = get_class_of(key_params)
      attributes = {}
      nested     = []

      value_params.each do |key, value|
        if is_nested?(value)
          if value.is_a?(Array)
            value.each { |hash_params| nested << make_hash_objects_and_nested_objects(key, hash_params) }
          elsif value.is_a?(ActionController::Parameters)
            value.each { |index, hash_params| nested << make_hash_objects_and_nested_objects(key, hash_params) }
          else
            nested << make_hash_objects_and_nested_objects(key, value)
          end
        else
          element = {key.to_sym => value}
          attributes.merge!(element)
        end
      end

      {model: model, attributes: attributes, nested: nested}
    end

    def make_data_for_assign
      params.each do |main_model_name, attributes|
        data_for_assign << make_hash_objects_and_nested_objects(main_model_name, attributes)
      end
    end


    def assign_object_attributes(data)
      object = data[:attributes][:id].to_i > 0 ? data[:model].find(data[:attributes][:id]) : data[:model].new
      nested = []

      object.assign_attributes(data[:attributes])
      data[:nested].each do |nested_model|
        nested << assign_object_attributes(nested_model)
      end

      {object: object, nested: nested}
    end

    def make_data_with_attributes
      data_for_assign.each do |data|
        data_with_attributes << assign_object_attributes(data)
      end
    end

    def clear_nested_arr(arr_objects)
      arr_objects.select do |data|
        validator.save_if_nil_or_empty?(data[:object])
      end
    end

    def delete_empty_objects(data_with_attributes)
      data_with_attributes.each do |data|
        data[:nested] = clear_nested_arr(data[:nested])
        delete_empty_objects(data[:nested])
      end
    end

    # def associate_all_main_objects(data_for_save)
    #   objects = Array.new(data_for_save)
    #   while object = objects.delete( objects[0] )
    #     object_1 = object[:essence][:object]
    #     objects.each do |hash|
    #       object_2 = hash[:essence][:object]
    #       next if !object_1.new_record? and !object_2.new_record?
    #       to_bind_models(object_1, object_2) 
    #     end
    #   end
    # end

    def associate_arr_objects(data)
      objects = Array.new(data)
      while object = objects.delete( objects[0] )
        object_1 = object[:object]
        objects.each do |hash|
          object_2 = hash[:object]
          next if !object_1.new_record? and !object_2.new_record?
          to_bind_models(object_1, object_2)
        end
      end
    end

    def associate_all_objects(nested_objects)
      associate_arr_objects(nested_objects)

      nested_objects.each do |data|
        parent_with_nested_arr = Array.new(data[:nested]) << data
        associate_arr_objects(parent_with_nested_arr)
        associate_all_objects(data[:nested])
      end
    end

  end
end








