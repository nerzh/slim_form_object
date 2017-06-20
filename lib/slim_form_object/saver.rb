module SlimFormObject
  class Saver

    attr_reader :form_object, :params, :array_objects_for_save

    def initialize(form_object, params, array_objects_for_save)
      @form_object            = form_object
      @params                 = params
      @array_objects_for_save = array_objects_for_save
    end

    def save
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


  end
end