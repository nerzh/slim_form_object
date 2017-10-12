module SlimFormObject
  class Assign
    include ::HelperMethods

    attr_reader :form_object, :params, :all_updated_objects, :base_module, :validator

    def initialize(form_object)
      @form_object                 = form_object
      @base_module                 = form_object.class.base_module
      @params                      = form_object.params
      @array_all_objects_for_save  = form_object.array_all_objects_for_save
      @validator                   = Validator.new(form_object)
      @all_updated_objects         = []
    end

    def apply_parameters
      make_all_objects_with_attributes
      clear_nil_objects

      all_updated_objects
    end

    def associate_objects
      associate_all_objects(all_updated_objects)

      all_updated_objects
    end

    private

    def clear_nil_objects
      arr_ids_nil_object = []
      find_ids_nil_object(arr_ids_nil_object, all_updated_objects)
      delete_hash_nil_objects(arr_ids_nil_object, all_updated_objects)
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

    def associate_all_objects(nested_array, object=nil)
      nested_array.each do |hash|
        to_bind_models(object, hash[:essence][:object]) if object
        associate_all_objects(hash[:nested], hash[:essence][:object])
      end
    end

    def make_all_objects_with_attributes
      object_hash = {}
      params.each do |main_model_name, hash|
        assign_objects_attributes(main_model_name, hash, object_hash, @all_updated_objects)
      end
    end

    def nested(model_name, nested_array, result_array)
      object_hash = {}
      nested_array.each do |nested_object|
        assign_objects_attributes(model_name, nested_object, object_hash, result_array)
      end
    end

    def is_nested?(value)
      return false unless value.class == Array
      value.select{ |e| e.class == ActionController::Parameters or e.class == Hash }.size == value.size
    end

    def assign_objects_attributes(model_name, hash, object_hash, result_array)
      object               = get_class_of_snake_model_name(model_name).new
      object_hash[:nested] = []
      hash.each do |key, val|
        if is_nested?(val)
          nested(key, val, object_hash[:nested])
        else
          object.assign_attributes({"#{key}": val})
        end
      end
      object_hash[:essence] = {model: model_name, object: object}
      result_array << object_hash
    end

    
    # def force_permit(params)
    #   return nil if params.class != ActionController::Parameters
    #   params.instance_variable_set(:@permitted, true)
    #   params
    # end

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

    # make_all_objects_with_attributes() EXAMPLE @all_updated_objects FORMAT
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








