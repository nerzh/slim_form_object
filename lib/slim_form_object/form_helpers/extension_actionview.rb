module ActionView
  module Helpers
    module HelperMethods
      def sfo_fields_for(name, object = nil, form_options: {}, options: {}, &block)
        object = get_class_of_snake_model_name(name.to_s).new unless object

        if options[:sfo_form]
          form_object_class = get_class_of_snake_model_name(name.to_s)
          name = "slim_form_object_#{name}"
          object = form_object_class.new(form_options)
        end

        fields_for(name, object, options, &block)
      end

      private

      def get_class_of_snake_model_name(snake_model_name)
        Object.const_get( snake_model_name.split('_').map(&:capitalize).join )
      end

      def sfo_single_attr_regexp
        /^([^-]+)-([^-]+)$/
      end

      def sfo_multiple_attr_regexp
        /sfo-multiple/
      end

      def sfo_date_attr_regexp
        /^([^-]+)-([^-]+)(\([\s\S]+\))$/
      end

      def sfo_collection_ads_regexp
        /_ids$/
      end

      def sfo_form_attribute?(object)
        object.class.ancestors[1] == SlimFormObject::Base if object
      end

      def sfo_attr?(method)
        sfo_single_attr?(method) or sfo_multiple_attr?(method)
      end

      def sfo_single_attr?(method)
        method.to_s[sfo_single_attr_regexp] ? true : false
      end

      def sfo_multiple_attr?(string)
        string.to_s[sfo_multiple_attr_regexp] ? true : false
      end

      def sfo_date_attr?(tag_name)
        tag_name.to_s[sfo_date_attr_regexp] ? true : false
      end

      def sfo_collection_ads_attr?(tag_name)
        tag_name.to_s[sfo_collection_ads_regexp] ? true : false
      end

      def sfo_get_tag_name(object_name, method, multiple)
        model_name, attr_name = apply_expression_text(method, sfo_single_attr_regexp)

        if sfo_multiple_attr?(object_name)
          tag_name   = "#{object_name}[#{model_name}][][#{attr_name}]#{"[]" if multiple}"
        elsif sfo_single_attr?(method)
          tag_name   = "#{object_name}[#{model_name}][#{attr_name}]#{"[]" if multiple}"
        end

        tag_name
      end

      def sfo_get_method_name(method)
        if sfo_single_attr?(method) and !sfo_collection_ads_attr?(method)
          model_name, attr_name = apply_expression_text(method, sfo_single_attr_regexp)
          method = "#{model_name}_#{attr_name}"
        end

        method
      end

      def sfo_get_date_tag_name(prefix, tag_name)
        model_name, attr_name, date_type = apply_expression_date(tag_name, sfo_date_attr_regexp)

        if sfo_multiple_attr?(prefix)
          tag_name   = "#{prefix}[#{model_name}][][#{attr_name}#{date_type}]"
        else
          tag_name   = "#{prefix}[#{model_name}][#{attr_name}#{date_type}]"
        end

        tag_name
      end

      def apply_expression_date(string, exp)
        string[exp]
        model_name = $1
        attr_name  = $2
        date_type  = $3

        [model_name, attr_name, date_type]
      end

      def apply_expression_text(string, exp)
        string[exp]
        model_name = $1
        attr_name  = $2

        [model_name, attr_name]
      end
    end

    class DateTimeSelector
      include HelperMethods

      def input_name_from_type(type)
        prefix = @options[:prefix] || ActionView::Helpers::DateTimeSelector::DEFAULT_PREFIX
        prefix += "[#{@options[:index]}]" if @options.has_key?(:index)

        field_name = @options[:field_name] || type
        if @options[:include_position]
          field_name += "(#{ActionView::Helpers::DateTimeSelector::POSITION[type]}i)"
        end

        return sfo_get_date_tag_name(prefix, field_name) if sfo_date_attr?(field_name)

        @options[:discard_type] ? prefix : "#{prefix}[#{field_name}]"

      end
    end

    module Tags
      class Base
        include HelperMethods

        private

        def value(object)
          method_name = sfo_get_method_name(@method_name)
          # byebug
          object.public_send method_name if object
        end

        def tag_name(multiple = false, index = nil)
          return sfo_get_tag_name(@object_name, sanitized_method_name, multiple) if sfo_attr?(sanitized_method_name)

          if index
            "#{@object_name}[#{index}][#{sanitized_method_name}]#{"[]" if multiple}"
          else
            "#{@object_name}[#{sanitized_method_name}]#{"[]" if multiple}"
          end
        end
      end
    end

    class FormBuilder
      include HelperMethods
    end

    module FormHelper
      include HelperMethods

      def fields_for(record_name, record_object = nil, options = {}, &block)
        if options[:sfo_multiple]
          record_name[/^([\s\S]+)(\[[\s\S]+\])/]
          part_1 = $1
          part_2 = $2
          record_name = "#{part_1}[sfo-multiple]#{part_2}"
        end
        builder = instantiate_builder(record_name, record_object, options)
        capture(builder, &block)
      end
    end

  end
end
