module SlimFormObject
  class Base
    include ActiveModel::Model
    include ::HelperMethods
    extend  ::HelperMethods

    attr_accessor :params, :data_with_attributes

    class << self
      attr_accessor :base_module

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

      # array_models_which_not_save_if_empty
      def save_object_with_empty_attributes_for(*args)
        args.each { |model| raise "#{model.to_s} - type is not a Class" if model.class != Class }
        instance_eval do
          define_method(:save_if_empty_arr) { args }
        end
      end

      def save_object_with_nil_attributes_for(*args)
        args.each { |model| raise "#{model.to_s} - type is not a Class" if model.class != Class }
        instance_eval do
          define_method(:save_if_nil_arr) { args }
        end
      end

      # CALLBACKS
      %w(allow_to_save_object allow_to_associate_objects before_save_form after_save_form before_validation_form after_validation_form).each do |method_name|
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
          get_class_of(main_model_name)
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
      self.params = params
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

      params.require(snake(model_name)).permit(structure)
    end

    private

    def require_extensions
      require "slim_form_object/form_helpers/extension_actionview"
    end

    def apply
      assign                    = Assign.new(self)
      self.data_with_attributes = assign.apply_parameters
      self.data_with_attributes = assign.associate_objects
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
      define_singleton_method(:save_if_empty_arr) { [] } unless respond_to?(:save_if_empty_arr)
      define_singleton_method(:save_if_nil_arr) { [] } unless respond_to?(:save_if_nil_arr)
      define_singleton_method(:allow_to_associate_objects_block) { Proc.new { true } } unless respond_to?(:allow_to_associate_objects_block)
      define_singleton_method(:allow_to_save_object_block) { Proc.new { true } } unless respond_to?(:allow_to_save_object_block)
      define_singleton_method(:before_save_form_block) { Proc.new {} } unless respond_to?(:before_save_form_block)
      define_singleton_method(:after_save_form_block) { Proc.new {} } unless respond_to?(:after_save_form_block)
      define_singleton_method(:before_validation_form_block) { Proc.new {} } unless respond_to?(:before_validation_form_block)
      define_singleton_method(:after_validation_form_block) { Proc.new {} } unless respond_to?(:after_validation_form_block)
    end

    def permit_params(params)
      return {} if params.empty?

      params.require(:product_form).permit(
        product: [
          :id,
          :category_id,
          :group_id,
          :brand_id,
          filters_product: [
              :id,
              :filter_id,
              :value_id,
              :product_id,
              filter: [:name],
              value: [:name]
          ]
        ],
        filters_product: [
            :id,
            :product_id,
            :filter_id,
            :value_id
        ]
      )
    end
  end
end







