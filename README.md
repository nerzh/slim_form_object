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
  init_models User, Rating, ReviewBook  # must be list of models you want to update
  not_save_this_model Rating            # optional - e.g. if you do not want to check and save the model Rating
  
  def initialize(params: {}, current_user: nil)
    # hash of http parameters must be for automatic save input attributes
    super(params: permit_params(params))
    
    # create the objects of models which will be saved
    self.user             = current_user
    # self.review_book      = ReviewBook.new  # empty objects will generate automatically 
    # self.rating           = Rating.new      # but you can override them
  end
      
  # you can to check a params here or in controller
  def params_review
    params.require(:review_book).permit("rating"       => [:value], 
                                        "review_book"  => [:theme, :text], 
                                        "user"         => ["address_ids" => []],
                                        # sfo-multiple
                                        "sfo-multiple" => [ # if you have nested objects in your web-form and you use "sfo_fields_for" form actionview-helper 
                                          "user"       => [ # nested objects will create for this object :user
                                            "address"  => [:city, :street, :created_at] # this is permitted params of nested object
                                          ]
                                        ])
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

#### Use helper "sfo_fields_for" with options: {sfo_multiple: true}

for example
```yaml
= form_for @reviewForm, url: reviews_path, method: 'POST', html: {} do |f|
  = f.number_field 'rating-value',      placeholder: "Rating"
  = f.text_field   'review_book-theme', placeholder: "Theme"
  = f.text_field   'review_book-text',  placeholder: "Text"

# like this. Nested forms for object :user
  = f.sfo_fields_for :user, @reviewForm, options: {sfo_multiple: true} do |n|
    = n.text_field  'address-city'
    = n.text_field  'address-street'
    = n.date_select 'address-created_at'
    
    = n.text_field  'address-city'
    = n.text_field  'address-street'
    = n.date_select 'address-created_at'

#   this will create two new addresses for object of model :user    
    ...
    
    or
    
  = f.sfo_fields_for :user, @reviewForm, options: {sfo_multiple: true} do |n|
    = n.text_field  'address-city'
    = n.text_field  'address-street'
    = n.date_select 'address-created_at'
  = f.sfo_fields_for :user, @reviewForm, options: {sfo_multiple: true} do |n|
    = n.text_field  'address-city'
    = n.text_field  'address-street'
    = n.date_select 'address-created_at'

#   this too will create two new addresses for object of model :user 
    ...
    
``` 


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

