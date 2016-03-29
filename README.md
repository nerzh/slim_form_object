# SlimFormObject
[![Build Status](https://travis-ci.org/woodcrust/slim_form_object.svg?branch=master)](https://travis-ci.org/woodcrust/slim_form_object)

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/slim_form_object`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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
      include ActiveModel::Model
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
        self.user             = current_user if current_user
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
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/slim_form_object.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

