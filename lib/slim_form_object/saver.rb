module SlimFormObject
  class Saver
    include ::HelperMethods

    attr_reader :form_object, :params, :array_objects_for_save, :validator

    def initialize(form_object, params, array_objects_for_save)
      @form_object            = form_object
      @params                 = params
      @array_objects_for_save = array_objects_for_save
      @validator              = Validator.new(form_object, params, array_objects_for_save)
    end

    def save
      byebug

      raise 'save'
      if form_object.valid?

        objects = Array.new(array_objects_for_save)
        while object_1 = objects.delete( objects[0] )
          objects.each{ |object_2| save_objects(object_1, object_2) }
          save_last_model_if_not_associations(object_1) if objects.empty?
        end
        return true
      end
      false
    end

    def save_objects(object_1, object_2)
      if validator.both_model_attributes_exist?(object_1, object_2)
        object_for_save = to_bind_models(object_1, object_2)
        save_object(object_for_save)
      else
        [object_1, object_2].each do |object|
          save_object(object)
        end
      end
    end

    def to_bind_models(object_1, object_2)
      # self_object_of_model_1, self_object_of_model_2 = get_self_objects_of_model(model_1, model_2)
      association = get_association(object_1.class, object_2.class)

      if    association == :belongs_to or association == :has_one
        object_1.send( "#{snake(object_2.class.to_s)}=", object_2 )
      elsif association == :has_many   or association == :has_and_belongs_to_many
        object_1.method("#{object_2.class.table_name}").call << object_2
      end

      object_1
    end

    def save_object(object_of_model)
      if validator.valid_model_for_save?(object_of_model.class)
        object_of_model.save!  
      end
    end

    def save_last_model_if_not_associations(object_1)
      association_trigger  = false
      array_objects_for_save.each { |object_2| association_trigger = true if get_association(object_1.class, object_2.class) }
      object_1.save unless association_trigger
    rescue
      object_1.class.find(object_1.id).update!(object_1.attributes)
    end

    def get_association(class1, class2)
      class1.reflections.slice(snake(class2.to_s), class2.table_name).values.first&.macro
    end

    # def get_self_objects_of_model(model_1, model_2)
    #   [ method( snake(model_1.to_s) ).call, method( snake(model_2.to_s) ).call ]
    # end




  end
end