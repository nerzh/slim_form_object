module SlimFormObject
  class Assign
    include ::HelperMethods

    attr_reader :form_object, :params, :data_for_assign
    attr_accessor :data_objects_arr

    def initialize(form_object)
      @form_object                     = form_object
      @params                          = form_object.params
      @structure                       = form_object.data_structure
      @data_for_assign                 = []
      @data_objects_arr                = []
    end

    def apply_parameters_and_make_objects
      parse_params
      @data_objects_arr = make_data_objects(data_for_assign)
      associate_all_objects(data_objects_arr)

      data_objects_arr
    end

    private

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

    def parse_params
      params.each do |main_model_name, attributes|
        data_for_assign << make_hash_objects_and_nested_objects(main_model_name, attributes)
      end
    end

    def is_nested?(value)
      def nested?(e)
        e.class == ActionController::Parameters or e.class == Hash
      end

      return true if nested?(value)

      if value.class == Array
        value.select{ |e| nested?(e) }.size == value.size
      end
    end

    def make_data_objects(data_for_assign)
      data_for_assign.map do |data|
        data_object        = DataObject.new(name: snake(data[:model]), attributes: data[:attributes], form_object: form_object)
        data_object.nested = make_data_objects(data[:nested])
        data_object
      end
    end

    def associate_objects(data_objects)
      objects = Array.new(data_objects)
      while data_object_1 = objects.delete( objects[0] )
        associate_all_objects(data_object_1.nested)
        objects.each do |data_object_2|
          data_object_1.associate_with(data_object_2.associated_object)
        end
      end
    end

    def associate_all_objects(objects)
      associate_objects(objects)

      objects.each do |data_object|
        data_object.nested.each do |nested_data_object|  
          data_object.associate_with(nested_data_object.associated_object)
        end
      end
    end

    def clean_data_objects_arr(objects)
      objects.select! do |data_object|
        clean_data_objects_arr(data_object.nested)
        data_object.save_if_nil_or_empty?
      end
    end

  end
end








