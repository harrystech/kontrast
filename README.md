# Kontrast

An automated testing tool for comparing visual differences between two versions of a website.

## Prerequisites

1. Install ImageMagick. You can do this on OS X via brew with:

		$ brew install imagemagick

2. Make sure you have Firefox or a different Selenium-compatible browser installed. By default, Firefox is used.

## Installation

Add this line to your application's Gemfile:

    gem 'kontrast'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kontrast

Lastly, generate the config file:

	$ bundle exec kontrast generate_config

If you're in Rails, the config file will be generated in `config/initializers/kontrast.rb`.  
Otherwise, the config file will be generated in your current directory.

## Basic Configuration

Here's all the config you need to get started:

	Kontrast.configure do |config|
		# Set your test and production domains
		config.test_domain = "http://localhost:3000"
		config.production_domain = "http://www.example.com"

		# Build your test suite
		# These pages will open in a 1280px-wide browser
		config.pages(1280) do |page|
			page.home "/"
			page.about "/about"
		end

		# These pages will open in a 320px-wide browser
		config.pages(320) do |page|
			page.home "/"
			page.about "/about"
		end
	end

## Basic Usage
Run Kontrast (omit the --config flag if you're within a Rails app):

	$ bundle exec kontrast local_run --config /path/to/config.rb
	...
	...
	...
	Kontrast is all done!
	You can find the gallery at: /tmp/shots/1410309651/gallery/gallery.html

Review the gallery in your Favorite Browser:

	$ open /tmp/shots/1410309651/gallery/gallery.html

## Advanced Configuration

### Options
#### Some option

	# todo

### Hooks
#### before_run
Runs before the entire suite.

	config.before_run do
		WebMock.disable!
	end

#### after_run
Runs after the entire suite.

	config.after_run do
		WebMock.enable!
	end

#### before_gallery
Runs before the gallery creation step.

	config.before_gallery do
		WebMock.disable!
	end

#### after_gallery
Runs after the gallery creation step. The block provides a `diffs` hash and a `gallery_path` for you to use.

	config.after_gallery do |diffs, gallery_path|
		WebMock.enable!
		puts diffs, gallery_path
	end

#### before_screenshot
Runs on every test before Selenium takes a screenshot.
The block provides the test and production Selenium drivers for you to control.

	config.before_screenshot do |test_driver, production_driver|
		test_driver.find_element(:css, '.active')
		production_driver.find_element(:css, '.active')
	end

#### after_screenshot
Runs on every test after Selenium takes a screenshot. The block provides the test and production Selenium drivers for you to control.

	config.after_screenshot do |test_driver, production_driver|
		test_driver.find_element(:css, '.inactive')
		production_driver.find_element(:css, '.inactive')
	end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
