def const_exists?(const_name)
  return true if Module.const_get(const_name)
rescue NameError
  return false
end

module HelperMethods

  private

  def get_class_of_snake_model_name(snake_model_name)
    Object.const_get( snake_model_name.split('_').map(&:capitalize).join )
  end

  def sfo_single_attr_regexp
    /^([^-]+)-([^-]+)$/
  end

  def sfo_date_attr_regexp
    /^([^-]+)-([^-]+)(\([\s\S]+\))$/
  end

  def sfo_date_attr?(tag_name)
    tag_name.to_s[sfo_date_attr_regexp] ? true : false
  end

  def sfo_get_date_tag_name(prefix, tag_name, options)
    # model_name, attr_name, date_type = apply_expression_date(tag_name)
    attr_name, date_type = apply_expression_text(tag_name)
    model_name = options[:sfo_model]

    if options[:sfo_model]
      "#{prefix}[#{model_name}][][#{attr_name}#{date_type}]"
    else
      "#{prefix}[#{model_name}][#{attr_name}#{date_type}]"
    end
  end

  def apply_expression_date(string)
    string[sfo_date_attr_regexp]
    model_name = $1
    attr_name  = $2
    date_type  = $3

    [model_name, attr_name, date_type]
  end

  def apply_expression_text(string)
    string[sfo_single_attr_regexp]
    model_name = $1
    attr_name  = $2

    [model_name, attr_name]
  end
end


if const_exists?('ActionView::Helpers')

  module ActionView
    module Helpers
      # EXTENSIONS

      class DateTimeSelector
        include HelperMethods

        def input_name_from_type(type)
          prefix = @options[:prefix] || ActionView::Helpers::DateTimeSelector::DEFAULT_PREFIX
          prefix += "[#{@options[:index]}]" if @options.has_key?(:index)

          field_name = @options[:field_name] || type
          if @options[:include_position]
            field_name += "(#{ActionView::Helpers::DateTimeSelector::POSITION[type]}i)"
          end
          options = self.instance_variable_get(:@options)
          return sfo_get_date_tag_name(prefix, field_name, options) if sfo_date_attr?(field_name)

          @options[:discard_type] ? prefix : "#{prefix}[#{field_name}]"

        end
      end

      
    end
  end
end