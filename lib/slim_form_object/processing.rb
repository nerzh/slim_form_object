module SlimFormObject
  class Base
    include ActiveModel::Model
    include ::HelperMethods
    extend  ::HelperMethods

    attr_accessor :params, :array_objects_for_save, :hash_objects_for_save

    class << self
      def set_model_name(name)
        define_method(:model_name) { ActiveModel::Name.new(self, nil, name) }
      end

      def init_single_models(*args)
        define_array_of_models(:array_of_all_models, args)
      end
      alias_method :init_models, :init_single_models

      def not_save_empty_object_for(*args)
        args.each { |model| raise "#{model.to_s} - type is not a Class" if model.class != Class }
        self.instance_eval do
          define_method(:array_models_which_not_save_if_empty) { args }
        end
      end

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

      # CALLBACKS
      def before_save_form(&block)
        if block_given?
          self.instance_eval do
            define_method(:before_save_block) { block }
          end
        end
      end

      def after_save_form(&block)
        if block_given?
          self.instance_eval do
            define_method(:after_save_block) { block }
          end
        end
      end
      # END CALLBACKS
    end

    def method_missing(name, *args, &block)
      if name[/_ids$/]
        model_name, attr_name = get_model_and_method_names(name)
        return self.send(model_name.to_sym).send(attr_name.to_sym)
      end
      super(name, args, block)
    end

    def initialize(params: {})
      self.params = params
      get_or_add_default_objects
    end
    # END INIT

    def apply_parameters
      default_settings
      apply
      self
    end
    alias_method :submit, :apply_parameters

    def save
      Saver.new(self).save
    end

    def validation_models
      Validator.new(self).validate_form_object
    end

    def array_all_objects_for_save
      array_objects_for_save ||= get_or_add_default_objects
    end

    private

    def apply
      assign                 = Assign.new(self)
      @hash_objects_for_save = assign.apply_parameters
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
      define_singleton_method(:array_models_which_not_save_if_empty) { [] } unless respond_to?(:array_models_which_not_save_if_empty)
      define_singleton_method(:after_save_block) { Proc.new {} } unless respond_to?(:after_save_block)
      define_singleton_method(:before_save_block) { Proc.new {} } unless respond_to?(:before_save_block)
    end

  end
end







