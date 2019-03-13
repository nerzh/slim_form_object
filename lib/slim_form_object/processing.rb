module SlimFormObject
  class Base
    include ActiveModel::Model
    include ::HelperMethods
    extend  ::HelperMethods

    attr_accessor :params, :data_objects_arr, :base_modules

    class << self
      attr_accessor :base_modules

      def set_model_name(name)
        define_method(:model_name) { ActiveModel::Name.new(self, nil, name) }
      end

      # data_structure
      def input_data_structure(**structure)
        instance_eval do
          define_method(:data_structure) { structure }
        end
        
        define_array_of_models(:array_of_all_models, get_main_models_from_structure(structure))
      end

      # CALLBACKS
      [
        'after_validation_form',
        'after_save_form',         
        'after_save_object', 
        'allow_to_save_object', 
        'allow_to_validate_object',
        'allow_object_processing',
        'check_params'
      ].each do |method_name|
        define_method("#{method_name}".to_sym) do |&block|
          instance_eval do
            define_method("#{method_name}_block".to_sym) { block }
          end if block
        end
      end
      # END CALLBACKS

      private

      def get_main_models_from_structure(structure)
        structure.keys.map do |main_model_name|
          get_class_of(main_model_name, base_modules[main_model_name])
        end
      end

      def define_array_of_models(name, args)
        instance_eval do
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

    def method_missing(name, *args, &block)
      if name[/_ids$/]
        model_name, attr_name = get_model_and_method_names(name)
        return send(model_name.to_sym).send(attr_name.to_sym)
      end
      super(name, args, block)
    end

    def initialize(params: {})
      require_extensions
      self.base_modules = self.class.base_modules
      self.params       = params
      get_or_add_default_objects
      default_settings
    end
    # END INIT

    def apply_parameters
      apply
      self
    end
    alias_method :submit, :apply_parameters

    def save
      Saver.new(self).save
    end

    def save!
      Saver.new(self).save!
    end

    def validation_models
      Validator.new(self).validate_form_object
    end

    def permit_params(params)
      return {} if params.empty?
      params.require(snake(model_name.name).gsub(/_+/, '_')).permit(data_structure)
    end

    private

    def require_extensions
      require "slim_form_object/form_helpers/extension_actionview"
    end

    def apply
      assign                = Assign.new(self)
      self.data_objects_arr = assign.apply_parameters_and_make_objects
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
    
    def default_settings
      define_singleton_method(:after_validation_form_block)    { Proc.new {} }       unless respond_to?(:after_validation_form_block)
      define_singleton_method(:after_save_form_block)          { Proc.new {} }       unless respond_to?(:before_save_form_block)
      define_singleton_method(:check_params_block)             { Proc.new {} }       unless respond_to?(:check_params_block)
      define_singleton_method(:after_save_object_block)        { Proc.new { true } } unless respond_to?(:allow_to_save_object_block)
      define_singleton_method(:allow_to_validate_object_block) { Proc.new { true } } unless respond_to?(:allow_to_validate_object_block)
      
      define_singleton_method(:allow_to_save_object_block) do 
        Proc.new { |object|  object.valid? and object.changed? } 
      end unless respond_to?(:allow_to_save_object_block)

      define_singleton_method(:allow_object_processing_block) do
        # Proc.new { |data_object| data_object.blank_or_empty? }
        Proc.new { |data_object| true }
      end unless respond_to?(:allow_object_processing_block)
    end

  end
end







