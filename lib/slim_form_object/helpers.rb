module HelperMethods
  def snake(string)
    string.gsub(/((\w)([A-Z]))/,'\2_\3').downcase
  end
end