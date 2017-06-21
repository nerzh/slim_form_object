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

    def validation_models
      Validator.new(self, params, array_objects_for_save).validate_form_object
    end

    # POMOGAY

    def not_validate(*args)
      @array_not_save_model ||= args.map { |model| model }
    end

    def set_errors(object_errors)
      object_errors.each do |attribute, message|
        errors.add(attribute, message)
      end
    end

    def array_all_objects_for_save
      array_objects_for_save ||= get_or_add_default_objects
    end

    def get_self_object(model)
      method( snake(model.to_s).to_sym ).call
    end


  # get attributes
  # .gsub(/^\[|\]$|"/, '').split(', ')
  end
end







