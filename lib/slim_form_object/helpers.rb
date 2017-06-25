module HelperMethods
  private

  def snake(string)
    string = string.to_s
    string.gsub!(/((\w)([A-Z]))/,'\2_\3')
    class_name_if_module(string.downcase)
  end

  def class_name_if_module(string)
    return $1 if string =~ /^.+::(.+)$/
    string
  end

  def get_self_object(model)
    method( snake(model.to_s).to_sym ).call
  end

  def get_class_of_snake_model_name(snake_model_name)
    Object.const_get( snake_model_name.to_s.split('_').map(&:capitalize).join )
  end

  def get_model_and_method_names(method)
    if sfo_single_attr?(method)
      apply_expression_text(method, sfo_single_attr_regexp)
    end
  end

  def sfo_single_attr?(method)
    method.to_s[sfo_single_attr_regexp] ? true : false
  end

  def sfo_single_attr_regexp
    /^([^-]+)-([^-]+)$/
  end

  def apply_expression_text(string, exp)
    string[exp]
    model_name = $1
    attr_name  = $2

    [model_name, attr_name]
  end
end