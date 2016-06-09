module HelperMethods
  def snake(string)
    string.gsub!(/((\w)([A-Z]))/,'\2_\3')
    class_name_if_module(string.downcase)
  end

  def class_name_if_module(string)
    return $1 if string =~ /^.+::(.+)$/
    string
  end
end