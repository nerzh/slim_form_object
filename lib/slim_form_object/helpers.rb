module HelperMethods
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
end