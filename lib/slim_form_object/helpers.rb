module HelperMethods
  def get_self_object(model)
    method( snake(model.to_s).to_sym ).call
  end

  def get_class_of_snake_model_name(snake_model_name)
    pref = if self.base_module
      self.base_module.to_s + '::'
    else
      ''
    end
    Object.const_get( pref + snake_model_name.to_s.split('_').map(&:capitalize).join )
  end

  def apply_expression_text(string, exp)
    string[exp]
    model_name = $1
    attr_name  = $2

    [model_name, attr_name]
  end

  def snake(string)
    string = string.to_s
    string.gsub!(/((\w)([A-Z]))/,'\2_\3')
    class_name_if_module(string.downcase)
  end

  def to_bind_models(object_1, object_2)
    association = get_association(object_1.class, object_2.class)

    if    association == :belongs_to or association == :has_one
      object_1.send( "#{snake(object_2.class.to_s)}=", object_2 )
    elsif association == :has_many   or association == :has_and_belongs_to_many
      object_1.method("#{object_2.class.table_name}").call << object_2
    end

    object_1
  end

  def get_association(class1, class2)
    class1.reflections.slice(snake(class2.to_s), class2.table_name).values.first&.macro
  end

  private
  
  def class_name_if_module(string)
    return $1 if string =~ /^.+::(.+)$/
    string
  end
end