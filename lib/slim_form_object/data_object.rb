module SlimFormObject
  class DataObject
    include ::HelperMethods

    attr_reader :name, :model, :attributes, :object, :associated_object, :form_object
    attr_accessor :nested

    def initialize(name: nil, attributes: {}, form_object: nil)
      @name              = name
      @model             = get_class_of(name)
      @attributes        = attributes
      @form_object       = form_object
      @object            = make_object
      @associated_object = assign_attributes_for(make_object)
      assign_attributes!
    end

    def associate_with(other_object, stage: nil)
      case stage
      when 1
        obj = object
      when 2
        obj = object
      else
        obj = associated_object  
      end

      return obj if (stage != 2 and !obj.new_record? and !other_object.new_record?)

      to_bind_models(obj, other_object)
    end

    def save_if_nil_or_empty?
      save_if_empty? and save_if_nil?
    end

    def save_if_empty?
      !form_object.not_save_if_empty_arr.include?(model) or !empty_attributes?
    end

    def save_if_nil?
      !form_object.not_save_if_nil_arr.include?(model) or !nil_attributes?
    end

    private

    def empty_attributes?
      return false if nil_attributes?
      attributes.each { |key, value| return false if value&.to_s&.strip != '' }
      true
    end

    def nil_attributes?
      attributes.empty?
    end

    def assign_attributes!
      assign_attributes_for(object)
    end

    def assign_attributes_for(obj)
      obj.assign_attributes(attributes)
      obj
    end

    def make_object
      attributes[:id].to_i > 0 ? model.find(attributes[:id]) : model.new
    end
  end
end



