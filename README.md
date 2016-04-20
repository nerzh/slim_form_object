# SlimFormObject
[![Build Status](https://travis-ci.org/woodcrust/slim_form_object.svg?branch=master)](https://travis-ci.org/woodcrust/slim_form_object) [![Code Climate](https://codeclimate.com/github/woodcrust/slim_form_object/badges/gpa.svg)](https://codeclimate.com/github/woodcrust/slim_form_object)

Welcome to your new gem for fast save data of html attributes your forms .

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

# e.g. Model User
    class User < ActiveRecord::Base
      has_many :review_books
      has_many :ratings
      
      has_and_belongs_to_many :addresses
      validates :addresses,  presence: true
    end

# e.g. Model ReviewBook
    class ReviewBook < ActiveRecord::Base
      belongs_to :user
      has_one    :rating, dependent: :delete
    
      validates :text,  presence: true, length: { maximum: 400 }
      validates :theme, presence: true, length: { maximum: 150 }
    end

# e.g. model Rating
    class Rating < ActiveRecord::Base
      belongs_to :user
      belongs_to :review_book
    
      validates  :ratings, presence: true
    end

# e.g. model Address
    class Address < ActiveRecord::Base
      has_and_belongs_to_many :users
    end

# EXAMPLE CLASS OF Form Object

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
    
# EXAMPLE CONTROLLER review_controller
 
    class ReviewController < ApplicationController

      def new
        @reviewForm = ReviewForm.new(current_user: current_user)
      end
    
      def create
        reviewForm = ReviewForm.new(params: params_review, current_user: current_user)
        reviewForm.submit
        reviewForm.save ? (render json: {status: 200}) : (render json: reviewForm.errors, status: :unprocessable_entity)
      end
    
      private
    
      def params_review
        params.require(:review_book).permit(:rating_ratings, :review_book_theme, :review_book_text, :user_address_ids => [])
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

        # For collection you must to use _ids in your name attributes, e.g. :
        = f.collection_select(:user_address_ids, Address.all, :id, :column_name, {selected: @settings_form.user.address_ids}, {multiple: true, class: "form-control input-address"})

        = f.submit 'Create review',                                 class: 'form-control btn btn-success'

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

