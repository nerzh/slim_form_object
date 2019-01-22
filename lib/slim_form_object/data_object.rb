module SlimFormObject
  class DataObject
    include ::HelperMethods

    attr_reader :name, :model, :attributes, :object, :form_object, :validator
    attr_accessor :nested

    def initialize(name: nil, attributes: {}, form_object: nil)
      @name              = name
      @model             = get_class_of(name)
      @attributes        = attributes
      @form_object       = form_object
      @object            = make_object
      @validator         = Validator.new(form_object)
      assign_attributes!
    end

    def associate_with(other_object, stage: nil)
      return object if (stage != Saver::STAGE_3 and !object.new_record? and !other_object.new_record?)

      to_bind_models(object, other_object)
    end

    def blank_or_empty?(except_fileds: [])
      validator.blank_or_empty_object?(self, except_fileds: except_fileds)
    end

    def empty_attributes?
      validator.empty_attributes?(attributes)
    end

    def only_blank_strings_in_attributes?
      validator.only_blank_strings_in_attributes?(attributes)
    end

    def regenerate_object
      @object = make_object
    end

    def assign_attributes!
      object.assign_attributes(attributes)
    end

    private

    def make_object
      attributes[:id].to_i > 0 ? model.find(attributes[:id]) : model.new
    end
  end
end

