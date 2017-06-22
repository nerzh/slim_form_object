require 'byebug'

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

      def not_save_this_model(*args)
        self.instance_eval do
          define_method(:not_save_this_model) { args }
        end
      end

      def force_save_if_all_attr_is_nil(*args)
        self.instance_eval do
          define_method(:force_save_if_all_attr_is_nil) { args }
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
    end

    def initialize(params: {})
      self.params = params
      get_or_add_default_objects
    end
    # INIT END


    def apply_parameters
      check_array_settings_with_settings
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
    
    def check_array_settings_with_settings
      define_singleton_method(:not_save_this_model) { [] } unless respond_to?(:not_save_this_model)
      define_singleton_method(:force_save_if_all_attr_is_nil) { [] } unless respond_to?(:force_save_if_all_attr_is_nil)
    end

  end
end







