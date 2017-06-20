module HelperMethods
  def snake(string)
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

  def get_names_form_attributes_of(model)
    model_attributes = []
    model.column_names.each do |name|
      model_attributes << "#{snake(model.to_s)}_#{name}"
    end
    model_attributes
  end

  def get_class_of_snake_model_name(snake_model_name)
    Object.const_get( snake_model_name.split('_').map(&:capitalize).join )
  end
end