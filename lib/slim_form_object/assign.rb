module SlimFormObject
  class Assign
    include ::HelperMethods

    attr_reader :form_object, :params, :data_for_save, :base_module, :validator

    def initialize(form_object)
      @form_object                 = form_object
      @base_module                 = form_object.class.base_module
      @params                      = form_object.params
      @array_all_objects_for_save  = form_object.array_all_objects_for_save
      @validator                   = Validator.new(form_object)
      @data_for_save               = []
    end

    def apply_parameters
      make_all_objects_with_attributes
      clear_nil_objects

      data_for_save
    end

    def associate_objects
      associate_all_nested_objects(data_for_save)
      associate_all_main_objects(data_for_save)

      data_for_save
    end

    private

    def clear_nil_objects
      arr_ids_nil_object = []
      find_ids_nil_object(arr_ids_nil_object, data_for_save)
      delete_hash_nil_objects(arr_ids_nil_object, data_for_save)
    end

    def delete_hash_nil_objects(ids_arr, nested_array)
      nested_array.select!{|e| !ids_arr.include?(e.object_id)}
      nested_array.each do |hash|
        delete_hash_nil_objects(ids_arr, hash[:nested])
      end
    end

    def find_ids_nil_object(ids_arr, nested_array)
      nested_array.each do |hash|
        ids_arr << hash.object_id if !validator.save_if_object_is_empty?(hash[:essence][:object])
        find_ids_nil_object(ids_arr, hash[:nested])
      end
    end

    def associate_all_nested_objects(nested_array, object=nil)
      nested_array.each do |hash|
        to_bind_models(object, hash[:essence][:object]) if object and validator.allow_to_associate_objects?(object, hash[:essence][:object])
        associate_all_nested_objects(hash[:nested], hash[:essence][:object])
      end
    end

    def associate_all_main_objects(data_for_save)
      objects = Array.new(data_for_save)
      while object = objects.delete( objects[0] )
        object_1 = object[:essence][:object]
        objects.each do |hash|
          object_2 = hash[:essence][:object]
          next if !object_1.new_record? and !object_2.new_record?
          to_bind_models(object_1, object_2) 
        end
      end
    end

    def make_all_objects_with_attributes
      params.each do |main_model_name, hash|
        assign_objects_attributes(main_model_name, hash, data_for_save, :main)
      end
    end

    def nested(model_name, nested_array, result_array)
      nested_array.each do |nested_object|
        assign_objects_attributes(model_name, nested_object, result_array, :nested)
      end
    end

    def is_nested?(value)
      return false unless value.class == Array
      value.select{ |e| e.class == ActionController::Parameters or e.class == Hash }.size == value.size
    end

    def assign_objects_attributes(model_name, hash, result_array, type)
      object_hash          = {}
      object               = type == :main ? form_object.send(model_name.to_sym) : get_class_of(model_name, base_module).new
      object_hash[:nested] = []
      object_attrs         = {}
      hash.each do |key, val|
        if is_nested?(val)
          nested(key, val, object_hash[:nested])
        else
          object_attrs.merge!({"#{key}": val})
        end
      end
      object.assign_attributes(object_attrs)
      object_hash[:essence] = {model: model_name, object: object}
      result_array << object_hash
    end

    # PARAMS FORMAT
    # { 
    #   "user"=> { 
    #     "email"=>"kjbkj@bk.ddd", 
    #     "password"=>"dsmndvvs", 
    #     "password_confirmation"=>"jvdjshvd", 
    #     "address_user"=> [
    #       {
    #         "first_name"=>"dsdsd", 
    #         "last_name"=>"kjhkjbk", 
    #         "order"=> [
    #           {
    #             "created_at"=>"kjkjb", 
    #             "updated_at"=>"kjbkjb"
    #           }
    #         ]
    #       }
    #     ]
    #   }
    # }

    # make_all_objects_with_attributes() EXAMPLE @data_for_save FORMAT
    #
    # [
    #   {
    #     essence: {model: 'user', object: WoodShop::User.new(attributes)},
    #     nested: [
    #       {
    #         essence: {model: 'address_user', object: WoodShop::AddressUser.new(attributes)},
    #         nested: [
    #           {
    #             essence: {model: 'image', object: WoodShop::Image.new(attributes)},
    #             nested: []
    #           },
    #           {
    #             essence: {model: 'image', object: WoodShop::Image.new(attributes)},
    #             nested: []
    #           }
    #         ] 
    #       }
    #     ]
    #   }
    # ]
  end
end








