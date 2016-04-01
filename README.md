# SlimFormObject
[![Build Status](https://travis-ci.org/woodcrust/slim_form_object.svg?branch=master)](https://travis-ci.org/woodcrust/slim_form_object) [![Code Climate](https://codeclimate.com/github/woodcrust/slim_form_object/badges/gpa.svg)](https://codeclimate.com/github/woodcrust/slim_form_object)

Welcome to your new gem!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'slim_form_object'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install slim_form_object

## Usage
```ruby

# Model User
    class User < ActiveRecord::Base
    
      devise :database_authenticatable, :registerable,
             :recoverable, :rememberable, :trackable, :validatable, :omniauthable
    
      has_many :review_books, dependent: :delete_all
      has_many :ratings,      dependent: :delete_all
    
    end

# Model ReviewBook

    class ReviewBook < ActiveRecord::Base
    
      belongs_to :user
      has_one    :rating, dependent: :delete
    
      validates :text,  presence: true, length: { maximum: 400 }
      validates :theme, presence: true, length: { maximum: 150 }
    
    end

# model Rating

    class Rating < ActiveRecord::Base
    
      belongs_to :user
      belongs_to :review_book
    
      validates  :ratings, presence: true
    
    end

# class FormObject

    class ReviewForm
      include SlimFormObject
      validate :validation_models
      
      #name params for params.require(:NAME).permit(...) e.g. 'ReviewBook'
      def self.model_name
        ActiveModel::Name.new(self, nil, "ReviewBook")
      end
    
      #models which will be updated
      init_models User, Rating, ReviewBook
    
      # create objects for models
      def initialize(params: {}, current_user: nil)
        self.user             = current_user
        self.review_book      = ReviewBook.new
        self.rating           = Rating.new
        
        #hash of attributes
        self.params           = params
      end
    
    end
    
# review_controller
 
    class ReviewController < ApplicationController

      def new
        @user = current_user
        @reviewForm = ReviewForm.new(current_user: @user)
      end
    
      def create
        user = current_user
        reviewForm = ReviewForm.new(params: params_review, current_user: user)
        reviewForm.submit
        reviewForm.save ? (render json: {status: 200}) : (render json: reviewForm.errors, status: :unprocessable_entity)
      end
    
      private
    
      def params_review
        params.require(:review_book).permit(:rating_ratings, :review_book_theme, :review_book_text)
      end
    end
    
```

```haml
# HTML FORM (Haml)
example name of attributes: name_model_name_atribute (e.g. review_book and theme => review_book_theme)

      = form_for @reviewForm, url: reviews_path, method: 'POST', html: {class: 'form-control'} do |f|
        = f.number_field :rating_ratings,    placeholder: "Rating", class: 'form-control input-checkout'
        = f.text_field   :review_book_theme, placeholder: "Theme",  class: 'form-control input-checkout'
        = f.text_field   :review_book_text,  placeholder: "Text",   class: 'form-control input-checkout'
        = f.submit 'Create review',                                 class: 'form-control btn btn-success'

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/slim_form_object.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

