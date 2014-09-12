# Kontrast

An automated testing tool for comparing visual differences between two versions of a website.

Kontrast lets you build a test suite to run against your test and production servers. It uses [Selenium](http://www.seleniumhq.org/) to take screenshots of both versions and then uses [ImageMagick](http://www.imagemagick.org/) to visually compare the screenshots. Finally, Kontrast collects its results into a detailed gallery.

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
	
## Parallelized Usage
We designed Kontrast from the very beginning to work with multiple containers on our CI server. Our CI setup can extend to any parallelized testing setup with some simple configuration.

### Method of Action

Because we ultimately need to generate a gallery with all test results from all given nodes, Kontrast uploads the test images it creates plus a per-node manifest file to S3. After all the tests have run, a single node downloads all the manifest files and parses them to create a single gallery.

Here's how to get set up:

### Enable Parallelization

	config.remote = true

### Configure Nodes
Set how many nodes you have in total and the zero-based index of the current node. Kontrast will automatically split up tests among these nodes.

	config.total_nodes = 6
    config.current_node = 2
    
### Configure Remote Options
Set your S3 details:

    config.aws_bucket = "kontrast-test-results"
    config.aws_key = ENV['AWS_KEY']
    config.aws_secret = ENV['AWS_SECRET']
    
This is the **local** path where output images will be stored on a node before they are uploaded to S3. This path will be created if it doesn't already exist.

    config.local_path = "tmp/kontrast"
    
This is the **remote** path relative to your S3 bucket's root where test images and manifest files will be uploaded to. It should be unique to the current running test.

    config.remote_path = "artifacts.#{ENV['BUILD_NUMBER']}"

This is the **local** path where the gallery will be saved to on the node that creates the gallery. This is usually the artifacts path on a CI server.

    config.gallery_path = ENV["ARTIFACTS_PATH"]
    
### Run the Tests
This command should run in parallel on every node. Omit the config flag if your app is `bundle`'d along with Rails.

	$ bundle exec kontrast run_tests --config /path/to/config.rb

### Create the Gallery
This command should only run on one node after all the other nodes have completed the previous command. Omit the config flag if your app is `bundle`'d along with Rails.

	$ bundle exec kontrast make_gallery --config /path/to/config.rb

## Advanced Configuration

### Selenium Driver
#### browser_driver
Choose which Selenium driver you'd like to use. Kontrast has only been tested on the default Firefox driver but we would love feedback and/or pull requests for other drivers.

	config.browser_driver = "firefox"
	
#### browser_profile
You may set a driver's profile options in this hash.

	config.browser_profile = {
        "general.useragent.override" => "Some Cool Kontrast User Agent",
        "image.animation_mode" => "none"
    }

### Image Comparisons
#### distortion_metric
See [http://www.imagemagick.org/RMagick/doc/constants.html#MetricType]() for available values.

	config.distortion_metric = "MeanAbsoluteErrorMetric"
	
#### highlight_color
The ImageMagick comparison tool emphasizes differences with this color.
Valid options are an RMagick color name or pixel.

	config.highlight_color = "blue"
	
#### lowlight_color
The ImageMagick comparison tool deemphasizes differences with this color.
Valid options are an RMagick color name or pixel.

	config.lowlight_color = "rgba(255, 255, 255, 0.3)"

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
