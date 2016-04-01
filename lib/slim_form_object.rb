require "slim_form_object/version"

module SlimFormObject

  def self.included(base)
    base.include(ActiveModel::Model)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def init_models(*args)
      self.instance_eval do
        define_method(:array_of_models) { args }
      end
      add_attributes(args)
    end

    def snake(string)
      string.gsub(/((\w)([A-Z]))/,'\2_\3').downcase
    end

    def add_attributes(models)
      #attr_accessor for models and env params
      attr_accessor :params
      models.each{ |model| attr_accessor snake(model.to_s).to_sym }

      #delegate attributes of models
      models.each do |model|
        model.column_names.each do |attr|
          delegate attr.to_sym, "#{attr}=".to_sym,
                   to: snake(model.to_s).to_sym,
                   prefix: snake(model.to_s).to_sym
        end
      end
    end
  end

  def submit
    update_attributes
  end

  def save
    if valid?
      models = get_model_for_save
      while model1 = models.delete( models[0] )
        array_of_models.each{ |model2| save_models(model1, model2) }
      end

      return true
    end
    false
  end

  private

  def save_models(model1, model2)
    self_model1 = method( self.class.snake(model1.to_s) ).call
    self_model2 = method( self.class.snake(model2.to_s) ).call

    case get_association(model1, model2)
      when :belongs_to
        self_model1.send( "#{self.class.snake(model2.to_s)}=", self_model2 )
        self_model1.save
      when :has_one
        self_model1.send( "#{self.class.snake(model2.to_s)}=", self_model2 )
        self_model1.save
      when :has_many
        self_model1.method("#{model2.table_name}").call << self_model2
        self_model1.save
      when :has_and_belongs_to_many
        self_model1.method("#{model2.table_name}").call << self_model2
        self_model1.save
    end
  end

  def validation_models
    get_model_for_save.each do |model|
      set_errors( method(self.class.snake(model.to_s)).call.errors ) unless method( self.class.snake(model.to_s) ).call.valid?
    end
  end

  def set_errors(model_errors)
    model_errors.each do |attribute, message|
      errors.add(attribute, message)
    end
  end

  def update_attributes
    array_of_models.each do |model|
      model_attributes = make_attributes_of_model(model)
      method( self.class.snake(model.to_s) ).call.assign_attributes( get_attributes_for_update(model_attributes, model) )
    end
  end

  def make_attributes_of_model(model)
    model_attributes = []
    model.column_names.each do |name|
      model_attributes << "#{self.class.snake(model.to_s)}_#{name}"
    end
    model_attributes
  end

  def get_attributes_for_update(model_attributes, model)
    update_attributes = {}
    hash_attributes   = params.slice(*model_attributes)
    hash_attributes.each{ |attr, val| update_attributes[attr.gsub(/#{self.class.snake(model.to_s)}_(.*)/, '\1')] = val }
    update_attributes
  end

  def get_model_for_save
    keys = params.keys
    models = []
    array_of_models.each do |model|
      model.column_names.each do |name|
        keys.each do |key|
          models << model if key.to_s == "#{self.class.snake(model.to_s)}_#{name}"
        end
      end
    end
    models.uniq!
    models
  end

  def get_association(class1, class2)
    class1.reflections.slice(self.class.snake(class2.to_s), class2.table_name).values.first.try(:macro)
  end

end