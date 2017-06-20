require 'byebug'

module SlimFormObject
  class Base
    include ActiveModel::Model
    include ::HelperMethods
    extend  ::HelperMethods

    attr_accessor :params, :array_objects_for_save

    class << self
      # DUBLE 2

      def set_model_name(name)
        define_method(:model_name) { ActiveModel::Name.new(self, nil, name) }
      end

      def init_single_models(*args)
        define_array_of_models(:array_of_all_models, args)
      end
      alias_method :init_models, :init_single_models

      def define_array_of_models(name, args)
        self.instance_eval do
          define_method(name) { args }
        end
        make_methods_for_objects_of(args)
      end

      def make_methods_for_objects_of(models)
        models.each{ |model| attr_accessor snake(model.to_s).to_sym }

        delegate_models_attributes(models)
      end

      def delegate_models_attributes(models)
        models.each do |model|
          model.column_names.each do |attr|
            delegate attr.to_sym, "#{attr}=".to_sym, to: snake(model.to_s).to_sym, prefix: true
          end
        end
      end
    end

    def initialize(params: {})
      self.params = params
      get_or_add_default_objects
    end

    def get_or_add_default_objects
      array_of_all_models.map do |model|
        if get_self_object(model) == nil
          method( "#{snake(model.to_s)}=" ).call(model.new)
        else
          get_self_object(model)
        end
      end
    end
    # INIT END


    def apply_parameters
      assign                 = Assign.new(self, params, array_all_objects_for_save, not_validate)
      array_objects_for_save = assign.apply_parameters
    end
    alias_method :submit, :apply_parameters

    def save
      Saver.new(self, params, array_objects_for_save).save
    end



    # POMOGAY

    def array_all_objects_for_save
      array_objects_for_save ||= get_or_add_default_objects
    end

    def get_self_object(model)
      method( snake(model.to_s).to_sym ).call
    end

    

    ########################################




    # def apply_parameters
    #   @array_of_objects_models_for_save = []
      
    #   @array_of_all_models ||= array_of_all_models.reject do |model| 
    #     array_of_all_models_without_validates.include?(model) if self.respond_to?(:array_of_all_models_without_validates)
    #   end

    #   update_attributes_single_models

    #   # byebug
    #   update_attributes_for_collection
    #   update_attributes_for_multiple_models

    #   byebug
    #   self
    # end
    
    # alias_method :submit, :apply_parameters

    # def save
    #   if valid?
    #     # models = Array.new(@array_of_all_models)
    #     objects = Array.new(@array_of_objects_models_for_save)
    #     byebug
    #     while object_1 = objects.delete( objects[0] )
    #       objects.each{ |object_2| save_objects(object_1, object_2) }
    #       save_last_model_if_not_associations(object_1) if objects.empty?
    #     end
    #     return true
    #   end
    #   false
    # end

    def not_validate(*args)
      @array_not_save_model ||= args.map { |model| model }
    end

    # private

    # def save_objects(object_1, object_2)
    #   self_object_of_model_for_save = nil
    #   # byebug
    #   if both_model_attributes_exist?(object_1, object_2)
    #     # byebug
    #     self_object_of_model_for_save = to_bind_models(model_1, model_2)
    #     save_model(self_object_of_model_for_save)
    #   else
    #     get_self_objects_of_model(model_1, model_2).each do |object|
    #       save_model(object)
    #     end
    #   end
    # end

    def to_bind_models(object_1, object_2)
      # self_object_of_model_1, self_object_of_model_2 = get_self_objects_of_model(model_1, model_2)
      association                                    = get_association(object_1.class, object_2.class)

      if    association == :belongs_to or association == :has_one
        object_1.send( "#{snake(object_2.class.to_s)}=", object_2 )
      elsif association == :has_many   or association == :has_and_belongs_to_many
        object_1.method("#{object_2.class.table_name}").call << object_2
      end

      object_1
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

    def save_model(self_object_of_model)
      if valid_model_for_save?(self_object_of_model.class)
        self_object_of_model.save!  
      end
    end

    def all_attributes_is_empty?(object)
      is_empty = true
      array_symbols_of_attributes = (get_names_form_attributes_of(object.class) & params.keys).map { |attr| attr.to_sym }
      params.slice(*array_symbols_of_attributes).values.each do |value|
        is_empty = false unless value == ""
      end
      is_empty
    end

    def get_self_objects_of_model(model_1, model_2)
      [ method( snake(model_1.to_s) ).call, method( snake(model_2.to_s) ).call ]
    end

    # def save_last_model_if_not_associations(model)
    #   association_trigger  = false
    #   self_object_of_model = method( snake(model.to_s) ).call
    #   @array_of_all_models.each { |model2| association_trigger = true if get_association(model, model2) }
    #   self_object_of_model.save unless association_trigger
    # rescue
    #   self_object_of_model.class.find(self_object_of_model.id).update!(self_object_of_model.attributes)
    # end

    def validation_models
      array_of_all_models.each do |model|
        next unless valid_model_for_save?( method(snake(model.to_s)).call )
        set_errors( method(snake(model.to_s)).call.errors ) unless method( snake(model.to_s) ).call.valid?
      end
    end

    def set_errors(model_errors)
      model_errors.each do |attribute, message|
        errors.add(attribute, message)
      end
    end

    # def update_attributes_single_models
    #   @array_of_all_models.each do |model|
    #     method( snake(model.to_s) ).call.assign_attributes( hash_attributes_from_params_for_update(model) )
    #     @array_of_objects_models_for_save << method( snake(model.to_s) ).call
    #   end
    # end

    # def update_attributes_for_collection
    #   @array_of_all_models.each do |model|
    #     assign_attributes_for_collection(model)
    #   end
    # end

    # def update_attributes_for_multiple_models
    #   params.keys.each do |key|
    #     if params[key].class == Array and params[key].first.class == ActionController::Parameters
    #       params[key].each do |parameters|
    #         object = get_class_of_snake_model_name(key).new
    #         object.assign_attributes(JSON.parse(parameters.to_json))
    #         @array_of_objects_models_for_save << object
    #       end
    #     end
    #   end
    # end

    # def keys_of_collections
    #   @keys ||= []
    #   params.keys.each do |key|
    #     @array_of_all_models.each do |model|
    #       self_object_of_model = method( snake(model.to_s) ).call
    #       method_name          = key.to_s[/#{snake(model.to_s)}_(.*)/, 1]
    #       @keys << method_name if self_object_of_model.respond_to? method_name.to_s
    #     end if key[/^.+_ids$/]
    #   end if @keys.empty?
    #   @keys
    # end

    # def assign_attributes_for_collection(model)
    #   self_object_of_model = method( snake(model.to_s) ).call

    #   keys_of_collections.each do |method_name|
    #     if self_object_of_model.respond_to? method_name
    #       old_attribute = self_object_of_model.method( method_name ).call
    #       if exist_any_errors_without_collections?
    #         unless self_object_of_model.update_attributes( {method_name.to_s => params["#{snake(model.to_s)}_#{method_name}".to_sym]} )
    #           set_errors(self_object_of_model.errors)
    #           self_object_of_model.update_attributes( {method_name.to_s => old_attribute} )
    #         else
    #           # @array_of_objects_models_for_save << self_object_of_model
    #         end
    #       end
    #     end
    #   end
    # end

    # def exist_any_errors_without_collections?
    #   keys_of_collections.each do |method_name|
    #     @array_of_all_models.each do |model|
    #       name_of_model     = method_name.to_s[/^(.+)_ids$/, 1]
    #       name_of_key_error = get_class_of_snake_model_name(name_of_model).table_name
    #       errors.messages.delete(name_of_key_error.to_sym)
    #     end
    #   end unless valid?
    #   errors.messages.empty?
    # end

    # def get_class_of_snake_model_name(snake_model_name)
    #   Object.const_get( snake_model_name.split('_').map(&:capitalize).join )
    # end

    # def get_names_form_attributes_of(model)
    #   model_attributes = []
    #   model.column_names.each do |name|
    #     model_attributes << "#{snake(model.to_s)}_#{name}"
    #   end
    #   model_attributes
    # end

    # def hash_attributes_from_params_for_update(model)
    #   attributes_for_update = {}
    #   model_attributes      = get_names_form_attributes_of(model)
    #   hash_attributes       = params.slice(*model_attributes)
    #   hash_attributes.each{ |attr, val| attributes_for_update[attr.gsub(/#{snake(model.to_s)}_(.*)/, '\1')] = val }
    #   attributes_for_update
    # end

    # def get_association(class1, class2)
    #   class1.reflections.slice(snake(class2.to_s), class2.table_name).values.first&.macro
    # end


  # get attributes
  # .gsub(/^\[|\]$|"/, '').split(', ')
  end
end







