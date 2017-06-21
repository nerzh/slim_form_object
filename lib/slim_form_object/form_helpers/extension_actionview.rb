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

      def get_sfo_name_and_method(method, object_name, options={})
        # if method.to_s[sfo_single_attr_regexp]
        #   model_name = $1
        #   attr_name  = $2
        #   options[:name] = "#{object_name}[#{method}]"
        #   method         = "#{model_name}_#{attr_name}"
        # elsif method.to_s[sfo_multiple_attr_regexp]
        #   model_name = $1
        #   attr_name  = $2
        #   options[:name] = "#{object_name}[sfo-multiple][#{model_name}][][#{attr_name}]"
        #   method         = "#{model_name}_#{attr_name}"
        # end

        [method, options]
      end

      def sfo_get_tag_name(object_name, method)
        if method.to_s[sfo_single_attr_regexp]
          model_name = $1
          attr_name  = $2
          # options[:name] = "#{object_name}[#{method}]"
          # method         = "#{model_name}_#{attr_name}"
          method         = "#{object_name}[#{model_name}][#{attr_name}]"
        elsif method.to_s[sfo_multiple_attr_regexp]
          model_name = $1
          attr_name  = $2
          method = "#{object_name}[sfo-multiple][#{model_name}][][#{attr_name}]"
        end

        method
      end

      def sfo_get_method_name(method)
        if method.to_s[sfo_single_attr_regexp]
          model_name = $1
          attr_name  = $2
          # options[:name] = "#{object_name}[#{method}]"
          method         = "#{model_name}_#{attr_name}"
        elsif method.to_s[sfo_multiple_attr_regexp]
          model_name = $1
          attr_name  = $2
          # options[:name] = "#{object_name}[sfo-multiple][#{model_name}][][#{attr_name}]"
          method         = "#{model_name}_#{attr_name}"
        end

        method
      end
    end


    module Tags

      class DateSelect
        def datetime_selector(options, html_options)
          datetime = options.fetch(:selected) { value(object) || default_datetime(options) }
          @auto_index ||= nil

          options = options.dup
          # byebug
          options[:field_name]           = @method_name
          # options[:field_name]           = "huy"
          options[:include_position]     = true
          options[:prefix]             ||= @object_name
          # options[:prefix]             ||= "huy"
          options[:index]                = @auto_index if @auto_index && !options.has_key?(:index)

          DateTimeSelector.new(datetime, options, html_options)
        end
      end


      class Base
        include HelperMethods
        # This is what child classes implement.
        def render
          raise NotImplementedError, "Subclasses must implement a render method"
        end

        private

        def value(object)
          # byebug

          method_name = sfo_get_method_name(@method_name)
          object.public_send method_name if object
        end

        def value_before_type_cast(object)
          unless object.nil?
            method_before_type_cast = @method_name + "_before_type_cast"
            # byebug
            if value_came_from_user?(object) && object.respond_to?(method_before_type_cast)
              object.public_send(method_before_type_cast)
            else
              value(object)
            end
          end
        end

        def value_came_from_user?(object)
          method_name = "#{@method_name}_came_from_user?"
          # byebug
          !object.respond_to?(method_name) || object.public_send(method_name)
        end

        def retrieve_object(object)
          if object
            object
          elsif @template_object.instance_variable_defined?("@#{@object_name}")
            @template_object.instance_variable_get("@#{@object_name}")
          end
        rescue NameError
          # As @object_name may contain the nested syntax (item[subobject]) we need to fallback to nil.
          nil
        end

        def retrieve_autoindex(pre_match)
          object = self.object || @template_object.instance_variable_get("@#{pre_match}")
          if object && object.respond_to?(:to_param)
            object.to_param
          else
            raise ArgumentError, "object[] naming but object param and @object var don't exist or don't respond to to_param: #{object.inspect}"
          end
        end

        def add_default_name_and_id_for_value(tag_value, options)
          if tag_value.nil?
            add_default_name_and_id(options)
          else
            specified_id = options["id"]
            add_default_name_and_id(options)

            if specified_id.blank? && options["id"].present?
              options["id"] += "_#{sanitized_value(tag_value)}"
            end
          end
        end

        def add_default_name_and_id(options)
          # byebug
          index = name_and_id_index(options)
          options["name"] = options.fetch("name"){ tag_name(options["multiple"], index) }
          # options["name"] = "huy"
          options["id"] = options.fetch("id"){ tag_id(index) }
          if namespace = options.delete("namespace")
            options['id'] = options['id'] ? "#{namespace}_#{options['id']}" : namespace
          end
        end

        def tag_name(multiple = false, index = nil)
          # a little duplication to construct less strings
          # return sfo_get_tag_name(@object_name, sanitized_method_name) if sfo_multiple_attr?(sanitized_method_name)
          return sfo_get_tag_name(@object_name, sanitized_method_name) if sfo_attr?(sanitized_method_name)

          if index
            "#{@object_name}[#{index}][#{sanitized_method_name}]#{"[]" if multiple}"
          else
            "#{@object_name}[#{sanitized_method_name}]#{"[]" if multiple}"
          end
        end

        def tag_id(index = nil)
          # a little duplication to construct less strings
          if index
            "#{sanitized_object_name}_#{index}_#{sanitized_method_name}"
          else
            "#{sanitized_object_name}_#{sanitized_method_name}"
          end
        end

        def sanitized_object_name
          @sanitized_object_name ||= @object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
        end

        def sanitized_method_name
          @sanitized_method_name ||= @method_name.sub(/\?$/,"")
        end

        def sanitized_value(value)
          value.to_s.gsub(/\s/, "_").gsub(/[^-\w]/, "").downcase
        end

        def select_content_tag(option_tags, options, html_options)
          html_options = html_options.stringify_keys
          add_default_name_and_id(html_options)

          if placeholder_required?(html_options)
            raise ArgumentError, "include_blank cannot be false for a required field." if options[:include_blank] == false
            options[:include_blank] ||= true unless options[:prompt]
          end

          value = options.fetch(:selected) { value(object) }
          select = content_tag("select", add_options(option_tags, options, value), html_options)

          if html_options["multiple"] && options.fetch(:include_hidden, true)
            tag("input", :disabled => html_options["disabled"], :name => html_options["name"], :type => "hidden", :value => "") + select
          else
            select
          end
        end

        def placeholder_required?(html_options)
          # See https://html.spec.whatwg.org/multipage/forms.html#attr-select-required
          html_options["required"] && !html_options["multiple"] && html_options.fetch("size", 1).to_i == 1
        end

        def add_options(option_tags, options, value = nil)
          if options[:include_blank]
            option_tags = content_tag_string('option', options[:include_blank].kind_of?(String) ? options[:include_blank] : nil, :value => '') + "\n" + option_tags
          end
          if value.blank? && options[:prompt]
            option_tags = content_tag_string('option', prompt_text(options[:prompt]), :value => '') + "\n" + option_tags
          end
          option_tags
        end

        def name_and_id_index(options)
          if options.key?("index")
            options.delete("index") || ""
          elsif @generate_indexed_names
            @auto_index || ""
          end
        end
      end
    end




    class FormBuilder
      include HelperMethods

      # def fields_for(record_name, record_object = nil, fields_options = {}, &block)
      def sfo_fields_for(name, form_options: {}, options: {}, &block)
        form_object_class = get_class_of_snake_model_name(name.to_s)
        fields_for("slim_form_object_#{name}", form_object_class.new(form_options), options, &block)
      end

      def date_select(method, options = {}, html_options = {})
        method, options = get_sfo_name_and_method(method, @object_name, options)
        @template.date_select(@object_name, method, objectify_options(options), html_options)
      end

      def time_select(method, options = {}, html_options = {})
        method, options = get_sfo_name_and_method(method, @object_name, options)
        @template.time_select(@object_name, method, objectify_options(options), html_options)
      end

      def datetime_select(method, options = {}, html_options = {})
        method, options = get_sfo_name_and_method(method, @object_name, options)
        @template.datetime_select(@object_name, method, objectify_options(options), html_options)
      end
    end

    module FormHelper
      include HelperMethods

      # def fields_for(record_name, record_object = nil, options = {}, &block)
      def sfo_fields_for(name, form_options: {}, options: {}, &block)
        form_object_class = get_class_of_snake_model_name(name.to_s)
        fields_for("slim_form_object_#{name}", form_object_class.new(form_options), options, &block)
      end

      def text_field(object_name, method, options = {})
        method, options = get_sfo_name_and_method(method, object_name, options)
        Tags::TextField.new(object_name, method, self, options).render
      end
    end

  end
end
