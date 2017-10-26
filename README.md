# SlimFormObject

[![Build Status](https://travis-ci.org/woodcrust/slim_form_object.svg?branch=master)](https://travis-ci.org/woodcrust/slim_form_object) [![Code Climate](https://codeclimate.com/github/woodcrust/slim_form_object/badges/gpa.svg)](https://codeclimate.com/github/woodcrust/slim_form_object)
[![Gem Version](https://badge.fury.io/rb/slim_form_object.svg)](https://badge.fury.io/rb/slim_form_object)

Welcome to your new gem for fast save data of your html forms. Very simple automatic generation and saving of your models nested attributes. With ActiveModel.

New features or have any questions, write here:
[![Join the chat at https://gitter.im/woodcrust/slim_form_object](https://badges.gitter.im/woodcrust/slim_form_object.svg)](https://gitter.im/woodcrust/slim_form_object?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## to read the [WIKI](https://github.com/woodcrust/slim_form_object/wiki) with images about slim form object

# Installation

Add this line to your application's Gemfile:

```ruby
gem 'slim_form_object'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install slim_form_object

# Usage
## e.g. Model User
/app/models/user.rb
```ruby
class User < ActiveRecord::Base
  has_many :review_books
  has_many :ratings
  has_and_belongs_to_many :addresses
end
```
## e.g. Model ReviewBook
/app/models/review_book.rb
```ruby
class ReviewBook < ActiveRecord::Base
  belongs_to :user
  has_one    :rating
end
```
## e.g. model Rating
/app/models/rating.rb
```ruby
class Rating < ActiveRecord::Base
  belongs_to :user
  belongs_to :review_book
end
```
## e.g. model Address
/app/models/address.rb
```ruby
class Address < ActiveRecord::Base
  has_and_belongs_to_many :users
end
```
## EXAMPLE CLASS of Form Object for review_controller
/app/forms/review_form.rb
```ruby
class ReviewForm < SlimFormObject::Base

  validate :validation_models           # optional - if you want to save validations of your models
  set_model_name('ReviewBook')          # name of model for params.require(:model_name).permit(...) e.g. 'ReviewBook'
  base_module = EngineName              # optional - default nil, e.g. you using engine and your models are named EngineName::User
  init_models User, Rating, ReviewBook  # must be list of models you want to update, if you use engine, then EngineName::User, EngineName::Rating ...
  not_save_empty_object_for Rating      # optional - e.g. if you do not want to validate and save the empty object Rating
  
  before_save_form           { |form|  } # code inside current activerecord transaction before save this form 
  after_save_form            { |form|  } # code inside current activerecord transaction after save this form 
  before_validation_form     { |form|  } # ...
  after_validation_form      { |form|  } # ...
  allow_to_save_object       { |object|  return true or false } # ...
  allow_to_associate_objects { |object_1, object_2|  return true or false } # ...
  
  def initialize(params: {}, current_user: nil)
    # hash of http parameters must be for automatic save input attributes
    super(params: permit_params(params))
    
    # create the objects of models which will be saved
    if current_user
      self.user             = current_user
    end

    # new objects will generate automatically if you not created their
    # self.review_book      = ReviewBook.new
    # self.rating           = Rating.new
  end
      
  # you can to check a params here or in controller
  def permit_params(params)
    return {} if params.empty?
    params.require(:review_book).permit("rating"        => [:value], 
                                        
                                        "review_book"   => [:theme, :text], 
                                        
                                        "user"          => [
                                          "address_ids" => [],
                                          "address"     => [:city, :street, :created_at] # this is permitted params of nested object
                                        ]
                                        )
  end
end
```
## EXAMPLE CONTROLLER of review_controller
/app/controllers/review_controller.rb
 ```ruby
class ReviewController < ApplicationController
  def new
    @reviewForm = ReviewForm.new(current_user: current_user)
  end
    
  def create
    reviewForm = ReviewForm.new(params: params, current_user: current_user)
    reviewForm.apply_parameters       # assign attributes of *params*. Will return the instance of ReviewForm with assigned attributes
    if reviewForm.save
      render json: {status: 200}
    else
      render json: reviewForm.errors, status: 422
    end
  end
end
```

## HTML FORM (Haml)

!!! this naming should be to successfully save your models !!!

example name of attributes: 
name_model & name_attribute_of_your_model => name_model-name_attribute_of_your_model 

e.g. *review_book* & *theme* => **review_book-theme** OR *rating* & *value* => **rating-value**
```yaml
= form_for @reviewForm, url: reviews_path, method: 'POST', html: {} do |f|
  = f.number_field 'rating-value',      placeholder: "Rating"
  = f.text_field   'review_book-theme', placeholder: "Theme"
  = f.text_field   'review_book-text',  placeholder: "Text"
```
## FOR COLLECTION

WITH (multiple: true) - you must to use a attribute name_model_ids in your names of attributes:

*name_model* & *name_attribute_of_your_model_ids* => **name_model-name_attribute_of_your_model_ids** 

e.g. *user* & *address_ids* => **user-address_ids**
```yaml
= f.collection_select('user-address_ids', Address.all, :id, :column_name, {selected: @settings_form.user.address_ids}, {multiple: true})
= f.submit 'Create review'
```

WITH (multiple: false) - you must to use a attribute name_model_id in your names of attributes:

*name_model* & *name_attribute_of_your_model_id* => **name_model-name_attribute_of_your_model_id** 

e.g. *user* & *address_id* => **user-address_id**
```yaml
= f.collection_select('user-address_id', Address.all, :id, :column_name, {}, {})
= f.submit 'Create review'
```

## FOR NESTED OBJECTS

#### Use helper "fields_for" with name of model :user, object Address.new and options {sfo_nested: true}

for example
```yaml
= form_for @reviewForm, url: reviews_path, method: 'POST', html: {} do |f|
  = f.number_field 'rating-value',      placeholder: "Rating"
  = f.text_field   'review_book-theme', placeholder: "Theme"
  = f.text_field   'review_book-text',  placeholder: "Text"

# like this. Nested forms for object :user
  
  = f.fields_for :user, Address.new, {sfo_nested: true} do |n|
    = n.text_field  'address-city'
    = n.text_field  'address-street'
    = n.date_select 'address-created_at'

    # first address
    = n.fields_for :address, Phone.new, {sfo_nested: true} do |z|
      = z.text_field 'phone-number'
      = z.fields_for :phone, Model.new, {sfo_nested: true} do |y|
        = y.text_field 'model-name'

    # another one second address   
    = n.fields_for :address, Phone.new, {sfo_nested: true} do |z|
      = z.text_field 'phone-number'
      = z.fields_for :phone, Model.new, {sfo_nested: true} do |y|
        = y.text_field 'model-name'    

#   this will create two new addresses and him nested objects for object of model :user
    ...
``` 

## IN CALLBACKS
You have access to hash of data for save which you can use for change objects inside callbacks

method data_for_save
him output data format - Array of hashes
example
```
[
  {
    essence: {model: 'user', object: UserObject},
    nested: [
      {
        essence: {model: 'address_user', object: AddressUserObject},
        nested: [
          {
            essence: {model: 'image', object: ImageObject},
            nested: []
          },
          {
            essence: {model: 'image', object: ImageObject},
            nested: []
          }
        ] 
      }
    ]
  }
]
```
### Usage
e.g.
```
before_validation_form do |form|
  form.data_for_save
  ... do something 
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

