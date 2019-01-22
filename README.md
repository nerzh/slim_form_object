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

  set_model_name('ReviewBook')          # name of model for params.require(:model_name).permit(...) e.g. 'ReviewBook'
  # you must define structure of data input params, also it will be data for the permit method 
  input_data_structure(
    [
      rating: [:value], 
      review_book: [:theme, :text], 
      user: [
        address_ids: [],
        address: [:city, :street, :created_at]
      ]
    ]
  )
  
  validate :validation_models           # optional - if you want to save and check validations of your models
  base_module = EngineName              # optional - default nil, e.g. you using engine and your models are named EngineName::User  
  not_save_empty_object_for Rating      # optional - if you do not want to validate and save object Rating with params like empty string
  not_save_nil_object_for Rating        # optional - if you do not want to validate and save object Rating with empty params like {} or all attributes is nil
   
  after_save_form            { |form|  } # code inside current activerecord transaction after save this form 
  before_validation_form     { |form|  } 
  allow_to_save_object       { |object|  true or false } 
  allow_to_validate_object   { |data_object|  true or false } 
  allow_object_processing { |data_object|  true or false } # ignore object if false
  
  allow_object_processing do |data_object|
  
    case data_object.model.to_s
    when 'Rating'
      # e.g. do not save object if input rating value <= 0 
      data_object.attributes[:value]&.to_i <= 0
    else
      # html form can send empty attributes and method .blank_or_empty?(except fields: []) will check it. Also we can ignore :id check or any input attributes with argument :except_fields  
      !data_object.blank_or_empty?(except_fileds: [:id]) 
    end
  end
  
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

## EXAMPLES OF HTML FORMS (Haml) IF YOU USE ACTIONVIEW

## EXAMPLES OF HTML FORMS (Haml) IF YOU USE ACTIONVIEW

!!! To specify model membership you should to use helper fields_for !!!

example name of attributes: 

```yaml
= form_for @reviewForm, url: reviews_path, method: 'POST', html: {} do |f|
  = f.fields_for :rating, @reviewForm.rating do |n|
    
    # id is needed in sent attributes that to update an already existing object
    = n.text_field :id, hidden: true
    = n.number_field :value, placeholder: "Rating"
  = f.fields_for :review_book, @reviewForm.review_book do |n|
    = n.text_field :id, hidden: true
    = n.text_field :theme, placeholder: "Theme"
    = n.text_field :text,  placeholder: "Text"
```
html without actionview

```html
<form action="/user/review" method="post">
  <input hidden="hidden" type="text" value="1" name="review_form[rating][id]">
  <input type="text" value="1" name="review_form[rating][id]">
  <input type="number" name="review_form[rating][value]">
  
  <input hidden="hidden" type="text" value="1" name="review_form[review_book][id]">
  <input type="text" name="review_form[review_book][theme]">
  <input type="text" name="review_form[review_book][text]">
</form>
```
## FOR COLLECTION

WITH (multiple: true) 

```yaml
= f.fields_for :user, @form.user do |n|
  = n.collection_select(:address_ids, Address.all, :id, :column_name, {selected: @settings_form.user.address_ids}, {multiple: true})
= f.submit 'Create review'
```

WITH (multiple: false)

```yaml
= f.fields_for :user, @form.user do |n|
  = n.collection_select(:address_id, Address.all, :id, :column_name, {}, {})
= f.submit 'Create review'
```

## FOR NESTED OBJECTS

for example
```yaml
= form_for @reviewForm, url: reviews_path, method: 'POST', html: {} do |f|
  = f.fields_for :rating, @reviewForm.rating do |n|
    = n.number_field :value, placeholder: "Rating"
  = f.fields_for :review_book, @reviewForm.review_book do |n|
    = n.text_field :theme, placeholder: "Theme"
    = n.text_field :text,  placeholder: "Text"

# Nested forms for object :user
  = f.fields_for :user, @reviewForm.user do |n|
    # if has many phones you should define a option index  
    
    # first address
    = n.fields_for :address, Address.new, {index: '0'} do |z|
      = z.text_field  :city
      = z.text_field  :street
    # second address
    = n.fields_for :address, Address.new, {index: '1'} do |z|
      = z.text_field  :city
      = z.text_field  :street
      = z.date_select :created_at

    # this will create two new nested addresses for :user
    ...
``` 


```html
  <form action="/user/review" method="post">
  <input hidden="hidden" type="text" value="1" name="review_form[rating][id]">
  <input type="text" value="1" name="review_form[rating][id]">
  <input type="number" name="review_form[rating][value]">

  <input hidden="hidden" type="text" value="1" name="review_form[review_book][id]">
  <input type="text" name="review_form[review_book][theme]">
  <input type="text" name="review_form[review_book][text]">
  
  <input type="text" name="review_form[review_book][user][address][0][city]">
  <input type="text" name="review_form[review_book][user][address][0][street]">
  
  <input type="text" name="review_form[review_book][user][address][1][city]">
  <input type="text" name="review_form[review_book][user][address][1][street]">
  
  ...
</form>
```
## IN CALLBACKS
You have access to hash of data for save which you can use for change objects inside callbacks

##### form_object.data_for_assign
example
```ruby
# data_for_assign format
# 
# [
#   { :model      => Product(id: integer, category_id: integer, brand_id: integer), 
#     :attributes => {:id=>"3871", :category_id=>"1", :brand_id=>"1"}, 
#     :nested     => [ 
#                      { :model      => FiltersProduct(id: integer, product_id: integer, filter_id: integer, value_id: integer), 
#                        :attributes => {:id=>"", :product_id=>"111", filter_id: "222", value_id: "333"}, 
#                        :nested     => []
#                      }
#                    ]
#   }
# ]
```
### Usage
e.g.
```
before_validation_form do |form_object|
  form_object.data_for_assign
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

