# Kontrast

An automated testing tool for comparing visual differences between two versions of a website.

## Prerequisites

1. Install ImageMagick. You can do this on OS X via brew with:

		brew install imagemagick

2. Make sure you have Firefox or a different Selenium-compatible browser installed. By default, Firefox is used.

## Installation

Add this line to your application's Gemfile:

    gem 'kontrast'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kontrast

Then you'll need to generate a config file:

	$ bundle exec kontrast generate:config idk

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/harrystech/kontrast/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
