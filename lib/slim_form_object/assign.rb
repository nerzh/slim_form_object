module SlimFormObject
  class Assign
    include ::HelperMethods

    attr_reader :form_object, :params, :array_all_objects_for_save, :not_save_this_model, :result_hash_updated_objects

    def initialize(form_object)
      @form_object                 = form_object
      @params                      = form_object.params
      @array_all_objects_for_save  = form_object.array_all_objects_for_save
      # @not_save_this_model         = form_object.not_save_this_model
      @result_hash_updated_objects = {objects: [], nested_objects: {}}
    end

    def apply_parameters
      # filter_not_save_objects
      update_objects_attributes
      make_nested_objects

      result_hash_updated_objects
    end

    private

    # def filter_not_save_objects
    #   array_all_objects_for_save.reject do |object|
    #     not_save_this_model.include?(object.class)
    #   end
    # end

    # STANDART OBJECTS

    def update_objects_attributes
      array_all_objects_for_save.each do |object|
        object.assign_attributes(hash_params_of_object(object))
      end

      result_hash_updated_objects[:objects] = array_all_objects_for_save
    end

    def hash_params_of_object(object)
      if force_permit(params[snake(object.class.to_s)])
        params[snake(object.class.to_s)]
      else
        {}
      end
    end

    def force_permit(params)
      return nil if params.class != ActionController::Parameters
      params.instance_variable_set(:@permitted, true)
      params
    end

    # NESTED OBJECTS
    # example params
    # 
    #                     "sfo-multiple"=>{
    # snake_model_name      "category_vacancy"=>{
    # snake_object_name        "specialty_vacancy"=>[ 
    # parameters                  {"name"=>"4", "category_vacancy_id"=>"12"}, {"name"=>"6", "category_vacancy_id"=>"14"} ]}} 
    #
    def make_nested_objects
      params.keys.each do |key|
        if key == 'sfo-multiple'
          params[key].keys.each do |snake_model_name|
            result_hash_updated_objects[:nested_objects][snake_model_name.to_sym] ||= []

            params[key][snake_model_name].keys.each do |snake_object_name|
              params[key][snake_model_name][snake_object_name].each do |parameters|
                object = get_class_of_snake_model_name(snake_object_name).new
                object.assign_attributes(force_permit(parameters))
                result_hash_updated_objects[:nested_objects][snake_model_name.to_sym] << object
              end
            end
          end
        end
      end
    end
  end
end








