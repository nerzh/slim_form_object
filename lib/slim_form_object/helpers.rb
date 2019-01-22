module HelperMethods
  def get_self_object(model)
    method( snake(model.to_s).to_sym ).call
  end

  def get_class_of(snake_model_name, base_module=nil)
    pref = base_module ? (base_module.to_s + '::') : ''
    Module.const_get( pref + snake_model_name.to_s.split('_').map(&:capitalize).join )
  rescue
    nil
  end

  def to_bind_models(object_1, object_2)
    if object_1.new_record?
      assignment_to_each_other(object_1, object_2)
      object_1
    else
      assignment_to_each_other(object_2, object_1)
      object_2
    end
  end

  def assignment_to_each_other(object_1, object_2)
    type, method_name = get_type_and_name_of_association(object_1.class, object_2.class)

    if    type == :belongs_to or type == :has_one
      object_1.send( "#{method_name.to_s}=", object_2 )
    elsif type == :has_many   or type == :has_and_belongs_to_many
      object_1.method(method_name).call << object_2
    end
  end

  def get_type_and_name_of_association(class1, class2)
    reflection  = get_reflection(class1, class2)
    [type_association(reflection), method_name_association(reflection)]
  end

  def get_reflection(class1, class2)
    class1.reflections.select{ |k,v| v.klass == class2 }.values.first
  end

  def type_association(reflection)
    reflection&.macro
  end

  def method_name_association(reflection)
    reflection&.name
  end

  def type_and_name_of_association_back_and_forth(class1, class2)
    get_type_and_name_of_association(class1, class2) + get_type_and_name_of_association(class2, class1)
  end

  def snake(string)
    string = string.to_s
    string.gsub!(/((\w)([A-Z]))/,'\2_\3')
    class_name_if_module(string.downcase)
  end
  
  def class_name_if_module(string)
    return $1 if string =~ /^.+::(.+)$/
    string
  end
  
  def define_classes_array_with_name(name, args)
    args.each { |model| raise "#{model.to_s} - type is not a Class" if model.class != Class }
    instance_eval do
      define_method(name) { args }
    end
  end

end
