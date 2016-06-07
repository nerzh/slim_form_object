# SlimFormObject

[![Join the chat at https://gitter.im/woodcrust/slim_form_object](https://badges.gitter.im/woodcrust/slim_form_object.svg)](https://gitter.im/woodcrust/slim_form_object?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://travis-ci.org/woodcrust/slim_form_object.svg?branch=master)](https://travis-ci.org/woodcrust/slim_form_object) [![Code Climate](https://codeclimate.com/github/woodcrust/slim_form_object/badges/gpa.svg)](https://codeclimate.com/github/woodcrust/slim_form_object)

Welcome to your new gem for fast save data of your html forms. Very simple automatic generation and saving of your models nested attributes. With ActiveModel.

Do you have a questions ? You can write me:
<mailto:info@inclouds.com.ua>

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
    class ReviewForm
      include SlimFormObject

      validate :validation_models     # if you want to save validations of your models - optional
      set_model_name('ReviewBook')    # name of model for params.require(:model_name).permit(...) e.g. 'ReviewBook'
      init_models User, Rating, ReviewBook     # must be list of models you want to update
    
      def initialize(params: {}, current_user: nil)
        # create the objects of models which will be saved
        self.user             = current_user
        self.review_book      = ReviewBook.new
        self.rating           = Rating.new
        
        #hash of http parameters must be for automatic save input attributes 
        self.params           = params
      end
    end
```
## EXAMPLE CONTROLLER of review_controller
/app/forms/review_controller.rb
 ```ruby
    class ReviewController < ApplicationController
      def new
        @reviewForm = ReviewForm.new(current_user: current_user)
      end
    
      def create
        reviewForm = ReviewForm.new(params: params_review, current_user: current_user)
        reviewForm.apply_parameters     # assign attributes of *params*. Will return the instance of ReviewForm with assigned attributes
        if reviewForm.save
          render json: {status: 200}
        else
          render json: reviewForm.errors, status: 422
        end
      end
    
      private
    
      def params_review
        params.require(:review_book).permit(:rating_ratings, :review_book_theme, :review_book_text, :user_address_ids => [])
      end
    end
```


## HTML FORM (Haml)

!!! this naming should be to successfully save your models !!!

example name of attributes: 
name_model & name_attribute_of_your_model => name_model_name_attribute_of_your_model 

e.g. *review_book* & *theme* => **review_book_theme** OR *rating* & *value* => **rating_value**
```haml
      = form_for @reviewForm, url: reviews_path, method: 'POST', html: {class: 'form-control'} do |f|
        = f.number_field :rating_value,      placeholder: "Rating", class: 'form-control input-checkout'
        = f.text_field   :review_book_theme, placeholder: "Theme",  class: 'form-control input-checkout'
        = f.text_field   :review_book_text,  placeholder: "Text",   class: 'form-control input-checkout'
```
## FOR COLLECTION you must to use _ids in your name attributes:

*name_model* & *name_attribute_of_your_model* & *ids* => **name_model_name_attribute_of_your_model_ids** 

e.g. *user* & *address* & *ids* => **user_address_ids**
```haml
        = f.collection_select(:user_address_ids, Address.all, :id, :column_name, {selected: @settings_form.user.address_ids}, {multiple: true, class: "form-control input-address"})

        = f.submit 'Create review', class: 'form-control btn btn-success'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

