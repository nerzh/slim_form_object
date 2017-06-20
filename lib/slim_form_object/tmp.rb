







# require 'byebug'

# module SlimFormObject
#   class Base
#     attr_accessor :params

#     def self.init_models(*args)
#       self.instance_eval do
#         define_method(:array_of_single_models) { args }
#       end
#       add_attributes(args)
#     end

#     alias_method :init_single_models, :init_models

#     def self.init_multiple_models(*args)
#       self.instance_eval do
#         define_method(:array_multiple_models) { args }
#       end
#       add_attributes(args)
#     end

#     def self.add_attributes(models)
#       #acessors for model objects
#       models.each{ |model| attr_accessor snake(model.to_s).to_sym }

#       #delegate attributes of models
#       models.each do |model|
#         model.column_names.each do |attr|
#           delegate attr.to_sym, "#{attr}=".to_sym, to:     snake(model.to_s).to_sym,
#                                                    prefix: true
#         end
#       end
#     end

#     def self.set_model_name(name)
#       define_method(:model_name) { ActiveModel::Name.new(self, nil, name) }
#     end
#     # def initializer

#     # end
#   end

#   def self.included(base)
#     # define_properties(base)

#     base.include ActiveModel::Model
#     base.include HelperMethods
#     base.extend  ClassMethods
#     base.extend  HelperMethods
#   end

#   # def self.define_properties(form_object_klass)
#   #   class << form_object_klass
#   #     #attr_accessor for models and env params
#   #     # attr_accessor :params

#   #     # byebug

#   #     # def params=(val)
#   #     #   @params = val
#   #     # end

#   #     # def params
#   #     #   @params
#   #     # end
#   #   end
#   # end

#   # module ClassMethods

#   #   def init_models(*args)
#   #     self.instance_eval do
#   #       define_method(:array_of_single_models) { args }
#   #     end
#   #     add_attributes(args)
#   #   end

#   #   alias_method :init_single_models, :init_models

#   #   def init_multiple_models(*args)
#   #     self.instance_eval do
#   #       define_method(:array_multiple_models) { args }
#   #     end
#   #     add_attributes(args)
#   #   end

#   #   def add_attributes(models)
#   #     #acessors for model objects
#   #     models.each{ |model| attr_accessor snake(model.to_s).to_sym }

#   #     #delegate attributes of models
#   #     models.each do |model|
#   #       model.column_names.each do |attr|
#   #         delegate attr.to_sym, "#{attr}=".to_sym, to:     snake(model.to_s).to_sym,
#   #                                                  prefix: true
#   #       end
#   #     end
#   #   end

#   #   def set_model_name(name)
#   #     define_method(:model_name) { ActiveModel::Name.new(self, nil, name) }
#   #   end
#   # end

#   def submit
#     @array_of_single_models ||= array_of_single_models.reject do |model| 
#       array_of_single_models_without_validates.include?(model) if self.respond_to?(:array_of_single_models_without_validates)
#     end
#     update_attributes
#     update_attributes_for_collection
#     self
#   end

#   alias_method :apply_parameters, :submit

#   def save
#     if valid?
#       models = Array.new(@array_of_single_models)
#       while model1 = models.delete( models[0] )
#         models.each{ |model2| save_models(model1, model2) }
#         save_last_model_if_not_associations(model1) if models.empty?
#       end
#       return true
#     end
#     false
#   end

#   def not_validate(*args)
#     define_singleton_method(:array_of_single_models_without_validates) { args }
#   end

#   private

#   def save_models(model_1, model_2)
#     self_object_of_model_for_save = nil
#     byebug
#     if both_model_attributes_exist?(model_1, model_2)
#       # byebug
#       self_object_of_model_for_save = to_bind_models(model_1, model_2)
#       save_model(self_object_of_model_for_save)
#     else
#       get_self_objects_of_model(model_1, model_2).each do |object|
#         save_model(object)
#       end
#     end
#   end

#   def to_bind_models(model_1, model_2)
#     self_object_of_model_1, self_object_of_model_2 = get_self_objects_of_model(model_1, model_2)
#     association                                    = get_association(model_1, model_2)

#     if    association == :belongs_to or association == :has_one
#       self_object_of_model_1.send( "#{snake(model_2.to_s)}=", self_object_of_model_2 )
#     elsif association == :has_many   or association == :has_and_belongs_to_many
#       self_object_of_model_1.method("#{model_2.table_name}").call << self_object_of_model_2
#     end

#     self_object_of_model_1
#   end

#   def valid_model_for_save?(model)
#     ( (attributes_is_present?(model) and method( snake(model.to_s) ).call.id != nil) or (method( snake(model.to_s) ).call.id == nil and !all_attributes_is_empty?(model)) )
#   end

#   def attributes_is_present?(model)
#     (make_attributes_of_model(model) & params.keys).present?
#   end

#   def both_model_attributes_exist?(model_1, model_2)
#     valid_model_for_save?(model_1) and valid_model_for_save?(model_2)
#   end

#   def save_model(self_object_of_model)
#     if valid_model_for_save?(self_object_of_model.class)
#       self_object_of_model.save!  
#     end
#   end

#   def all_attributes_is_empty?(model)
#     is_empty = true
#     array_symbols_of_attributes = (make_attributes_of_model(model) & params.keys).map { |attr| attr.to_sym }
#     params.slice(*array_symbols_of_attributes).values.each do |value|
#       is_empty = false unless value == ""
#     end
#     is_empty
#   end

#   def get_self_objects_of_model(model_1, model_2)
#     [ method( snake(model_1.to_s) ).call, method( snake(model_2.to_s) ).call ]
#   end

#   def save_last_model_if_not_associations(model)
#     association_trigger  = false
#     self_object_of_model = method( snake(model.to_s) ).call
#     @array_of_single_models.each { |model2| association_trigger = true if get_association(model, model2) }
#     self_object_of_model.save unless association_trigger
#   rescue
#     self_object_of_model.class.find(self_object_of_model.id).update!(self_object_of_model.attributes)
#   end

#   def validation_models
#     @array_of_single_models.each do |model|
#       next unless valid_model_for_save?(model)
#       set_errors( method(snake(model.to_s)).call.errors ) unless method( snake(model.to_s) ).call.valid?
#     end
#   end

#   def set_errors(model_errors)
#     model_errors.each do |attribute, message|
#       errors.add(attribute, message)
#     end
#   end

#   def update_attributes
#     @array_of_single_models.each do |model|
#       model_attributes = make_attributes_of_model(model)
#       method( snake(model.to_s) ).call.assign_attributes( get_attributes_for_update(model_attributes, model) )
#     end
#   end

#   def update_attributes_for_collection
#     @array_of_single_models.each do |model|
#       assign_attributes_for_collection(model)
#     end
#   end

#   def keys_of_collections
#     @keys ||= []
#     params.keys.each do |key|
#       @array_of_single_models.each do |model|
#         self_object_of_model = method( snake(model.to_s) ).call
#         method_name          = key.to_s[/#{snake(model.to_s)}_(.*)/, 1]
#         @keys << method_name if self_object_of_model.respond_to? method_name.to_s
#       end if key[/^.+_ids$/]
#     end if @keys.empty?
#     @keys
#   end

#   def exist_any_errors_without_collections?
#     keys_of_collections.each do |method_name|
#       @array_of_single_models.each do |model|
#         name_of_model          = method_name.to_s[/^(.+)_ids$/, 1]
#         name_of_constant_model = name_of_model.split('_').map(&:capitalize).join
#         name_of_key_error      = Object.const_get(name_of_constant_model).table_name
#         errors.messages.delete(name_of_key_error.to_sym)
#       end
#     end unless valid?
#     errors.messages.empty?
#   end

#   def assign_attributes_for_collection(model)
#     self_object_of_model = method( snake(model.to_s) ).call

#     keys_of_collections.each do |method_name|
#       if self_object_of_model.respond_to? method_name
#         old_attribute = self_object_of_model.method( method_name ).call
#         unless self_object_of_model.update_attributes( {method_name.to_s => params["#{snake(model.to_s)}_#{method_name}".to_sym]} )
#           set_errors(self_object_of_model.errors)
#           self_object_of_model.update_attributes( {method_name.to_s => old_attribute} )
#         end if exist_any_errors_without_collections?
#       end
#     end
#   end

#   def make_attributes_of_model(model)
#     model_attributes = []
#     model.column_names.each do |name|
#       model_attributes << "#{snake(model.to_s)}_#{name}"
#     end
#     model_attributes
#   end

#   def get_attributes_for_update(model_attributes, model)
#     attributes_for_update = {}
#     hash_attributes   = params.slice(*model_attributes)
#     hash_attributes.each{ |attr, val| attributes_for_update[attr.gsub(/#{snake(model.to_s)}_(.*)/, '\1')] = val }
#     attributes_for_update
#   end

#   def get_association(class1, class2)
#     class1.reflections.slice(snake(class2.to_s), class2.table_name).values.first&.macro
#   end


#   # get attributes
#   # .gsub(/^\[|\]$|"/, '').split(', ')

# end