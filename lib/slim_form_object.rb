require "slim_form_object/version"
require "slim_form_object/helpers"

module SlimFormObject

  def self.included(base)
    base.include ActiveModel::Model
    base.include HelperMethods
    base.extend  ClassMethods
    base.extend  HelperMethods
  end

  module ClassMethods

    def init_models(*args)
      self.instance_eval do
        define_method(:array_of_models) { args }
      end
      add_attributes(args)
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
    update_attributes_for_collection
  end

  def save
    if valid?
      models = Array.new(array_of_models)
      while model1 = models.delete( models[0] )
        array_of_models.each{ |model2| save_models(model1, model2) }
      end

      return true
    end
    false
  end

  private

  def save_models(model1, model2)
    self_object_of_model1 = method( snake(model1.to_s) ).call
    self_object_of_model2 = method( snake(model2.to_s) ).call

    case get_association(model1, model2)
      when :belongs_to
        self_object_of_model1.send( "#{snake(model2.to_s)}=", self_object_of_model2 )
        self_object_of_model1.save!
      when :has_one
        self_object_of_model1.send( "#{snake(model2.to_s)}=", self_object_of_model2 )
        self_object_of_model1.save!
      when :has_many
        self_object_of_model1.method("#{model2.table_name}").call << self_object_of_model2
        self_object_of_model1.save!
      when :has_and_belongs_to_many
        self_object_of_model1.method("#{model2.table_name}").call << self_object_of_model2
        self_object_of_model1.save!
    end
  end

  def validation_models
    array_of_models.each do |model|
      set_errors( method(snake(model.to_s)).call.errors ) unless method( snake(model.to_s) ).call.valid?
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
      method( snake(model.to_s) ).call.assign_attributes( get_attributes_for_update(model_attributes, model) )
    end
  end

  def update_attributes_for_collection
    array_of_models.each do |model|
      assign_attributes_for_collection(model)
    end
  end

  def keys_of_collections
    params.keys.select{ |key| key =~ /^.+_ids$/ }
  end

  def assign_attributes_for_collection(model)
    self_object_of_model = method( snake(model.to_s) ).call

    keys_of_collections.each do |key|
      key.to_s =~ /#{snake(model.to_s)}_(.*)/
      if self_object_of_model.respond_to? $1.to_s
        old_attribute = self_object_of_model.method( $1 ).call
        unless self_object_of_model.update_attributes( {$1.to_s => params[key]} )
          set_errors(self_object_of_model.errors)
          self_object_of_model.update_attributes( {$1.to_s => old_attribute} )
        end if valid?
      end
    end
  end

  def make_attributes_of_model(model)
    model_attributes = []
    model.column_names.each do |name|
      model_attributes << "#{snake(model.to_s)}_#{name}"
    end
    model_attributes
  end

  def get_attributes_for_update(model_attributes, model)
    update_attributes = {}
    hash_attributes   = params.slice(*model_attributes)
    hash_attributes.each{ |attr, val| update_attributes[attr.gsub(/#{snake(model.to_s)}_(.*)/, '\1')] = val }
    update_attributes
  end

  def get_association(class1, class2)
    class1.reflections.slice(snake(class2.to_s), class2.table_name).values.first.try(:macro)
  end

end