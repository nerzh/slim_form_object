module ActionView
  module Helpers
    module HelperMethods
      def get_class_of_snake_model_name(snake_model_name)
        Object.const_get( snake_model_name.split('_').map(&:capitalize).join )
      end

      def sfo_single_attr_regexp
        /^([^-]+)-([^-]+)$/
      end

      def sfo_multiple_attr_regexp
        /^multiple-([^-]+)-([^-]+)$/
      end

      def sfo_date_attr_regexp
        /^([^-]+)-([^-]+)(\([\s\S]+\))$/
      end

      def sfo_attribute?(object)
        object.class.ancestors[1] == SlimFormObject::Base if object
      end

      def sfo_attr?(method)
        sfo_single_attr?(method) or sfo_multiple_attr?(method)
      end

      def sfo_single_attr?(method)
        method.to_s[sfo_single_attr_regexp] ? true : false
      end

      def sfo_multiple_attr?(method)
        method.to_s[sfo_multiple_attr_regexp] ? true : false
      end

      def sfo_date_attr?(tag_name)
        tag_name.to_s[sfo_date_attr_regexp] ? true : false
      end

      def sfo_get_tag_name(object_name, method)
        if method.to_s[sfo_single_attr_regexp]
          model_name = $1
          attr_name  = $2
          tag_name   = "#{object_name}[#{model_name}][#{attr_name}]"
        elsif method.to_s[sfo_multiple_attr_regexp]
          model_name = $1
          attr_name  = $2
          tag_name   = "#{object_name}[sfo-multiple][#{model_name}][][#{attr_name}]"
        end

        tag_name
      end

      def sfo_get_method_name(method)
        if method.to_s[sfo_single_attr_regexp]
          model_name = $1
          attr_name  = $2
          method     = "#{model_name}_#{attr_name}"
        elsif method.to_s[sfo_multiple_attr_regexp]
          model_name = $1
          attr_name  = $2
          method     = "#{model_name}_#{attr_name}"
        end

        method
      end

      def sfo_get_date_tag_name(prefix, tag_name)
        if tag_name[sfo_date_attr_regexp]
          model_name = $1
          attr_name  = $2
          date_type  = $3
          tag_name   = "#{prefix}[#{model_name}][#{attr_name}#{date_type}]"
        end

        tag_name
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

      # class DateSelect
      #   def datetime_selector(options, html_options)
      #     datetime = options.fetch(:selected) { value(object) || default_datetime(options) }
      #     @auto_index ||= nil
      #
      #     options = options.dup
      #     # byebug
      #     options[:field_name]           = @method_name
      #     options[:include_position]     = true
      #     options[:prefix]             ||= @object_name
      #     options[:index]                = @auto_index if @auto_index && !options.has_key?(:index)
      #
      #     # byebug
      #     DateTimeSelector.new(datetime, options, html_options)
      #   end
      # end


      class Base
        include HelperMethods

        private

        def value(object)
          method_name = sfo_get_method_name(@method_name)
          object.public_send method_name if object
        end

        def tag_name(multiple = false, index = nil)
          return sfo_get_tag_name(@object_name, sanitized_method_name) if sfo_attr?(sanitized_method_name)

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
    #
      # def fields_for(record_name, record_object = nil, fields_options = {}, &block)
      def sfo_fields_for(name, form_options: {}, options: {}, &block)
        form_object_class = get_class_of_snake_model_name(name.to_s)
        fields_for("slim_form_object_#{name}", form_object_class.new(form_options), options, &block)
      end
    #
    #   def date_select(method, options = {}, html_options = {})
    #     method, options = get_sfo_name_and_method(method, @object_name, options)
    #     @template.date_select(@object_name, method, objectify_options(options), html_options)
    #   end
    #
    #   def time_select(method, options = {}, html_options = {})
    #     method, options = get_sfo_name_and_method(method, @object_name, options)
    #     @template.time_select(@object_name, method, objectify_options(options), html_options)
    #   end
    #
    #   def datetime_select(method, options = {}, html_options = {})
    #     method, options = get_sfo_name_and_method(method, @object_name, options)
    #     @template.datetime_select(@object_name, method, objectify_options(options), html_options)
    #   end
    end
    #
    module FormHelper
      include HelperMethods
    #
      # def fields_for(record_name, record_object = nil, options = {}, &block)
      def sfo_fields_for(name, form_options: {}, options: {}, &block)
        form_object_class = get_class_of_snake_model_name(name.to_s)
        fields_for("slim_form_object_#{name}", form_object_class.new(form_options), options, &block)
      end
    #
    #   def text_field(object_name, method, options = {})
    #     method, options = get_sfo_name_and_method(method, object_name, options)
    #     Tags::TextField.new(object_name, method, self, options).render
    #   end
    end

  end
end
