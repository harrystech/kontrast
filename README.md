# Kontrast

An automated testing tool for comparing visual differences between two versions of a website.

Kontrast lets you build a test suite to run against your test and production websites. It uses [Selenium](http://www.seleniumhq.org/) to take screenshots and [ImageMagick](http://www.imagemagick.org/) to compare them. Kontrast then produces a detailed gallery of its test results.

## Prerequisites

1. Ruby 2.0+

2. Install ImageMagick. You can do this on OS X via brew with:

        $ brew install imagemagick

3. Make sure you have Firefox or a different Selenium-compatible browser installed. By default, Firefox is used.

## Installation

Add this line to your application's Gemfile:

    gem 'kontrast'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kontrast

Lastly, generate the config file:

    $ kontrast generate_config

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
Run Kontrast (use `bundle exec` and omit the --config flag if you're within a Rails app):

    $ kontrast local_run --config ./kontrast_config.rb
    ...
    ...
    ...
    Kontrast is all done!
    You can find the gallery at: /tmp/shots/1410309651/gallery/gallery.html

Review the gallery in your Favorite Browser:

    $ open /tmp/shots/1410309651/gallery/gallery.html

## Parallelized Usage
We designed Kontrast from the very beginning to work with multiple nodes. At Harry's, we use CircleCI for testing and Kontrast works perfectly with CircleCI's multi-container features.

### Method of Action

Because we ultimately need to generate a gallery with all test results from all given nodes, Kontrast uploads the test images it creates plus a per-node manifest file to S3. After all the tests have run, a single node downloads the manifest files and parses them to create a single gallery.

Here's how to get set up:

### 1. Enable Parallelization

    config.run_parallel = true

### 2. Configure Nodes
Set how many nodes you have in total and the zero-based index of the current node. Kontrast will automatically split up tests among these nodes.

    config.total_nodes = 6
    config.current_node = 2

### 3. Configure Remote Options
Set your S3 details:

    config.aws_bucket = "kontrast-test-results"
    config.aws_key = ENV['AWS_KEY']
    config.aws_secret = ENV['AWS_SECRET']

Set the **local** path where output images will be stored before they are uploaded to S3. This is also where the gallery will be saved on the node that runs the `make_gallery` command. This path will be created if it doesn't already exist.

    config.local_path = "tmp/kontrast"

Set the **remote** path relative to your S3 bucket's root where Kontrast's output files will be uploaded to. It should be unique to every test.

    config.remote_path = "artifacts.#{ENV['BUILD_NUMBER']}"

### 4. Run the Tests
This command should run in parallel on every node. Use `bundle exec` and omit the --config flag if your app is `bundle`'d along with Rails.

    $ kontrast run_tests --config /path/to/config.rb

### 5. Create the Gallery
This command should only run on one node after all the other nodes have completed the previous command. Use `bundle exec` and omit the --config flag if your app is `bundle`'d along with Rails.

    $ kontrast make_gallery --config /path/to/config.rb

### 6. Review Your Results
At this point, the gallery should be saved to `config.local_path` and uploaded to `config.remote_path`. Check it out in your Favorite Browser.

### Sample circle.yml
Here's an example of how to run Kontrast within a Rails app using CircleCI:

    test:
        post:
            - bundle exec rails server:
                background: true
                parallel: true
            - bundle exec kontrast run_tests:
                parallel: true
            - bundle exec kontrast make_gallery

## Advanced Configuration

### Test Suite

#### fail_build
If you want Kontrast to exit with an error code (and fail your build) if an exception is raised while running, use this option:

    config.fail_build = true

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
To make Kontrast even more powerful, we provided a set of hooks that you can use in your configuration.

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
Runs after the gallery creation step.

    config.after_gallery do |diffs, gallery_path|
        # diffs is a hash containing all the differences that Kontrast found in your test suite
        # gallery_path is where Kontrast saved the gallery
    end

#### before_screenshot
Runs on every test before Selenium takes a screenshot.

    config.before_screenshot do |test_driver, production_driver, test_info|
        # test_driver and production_driver are instances of Selenium::WebDriver that you can control
        # test_info is a hash with the current test's name and width
    end

#### after_screenshot
Runs on every test after Selenium takes a screenshot.

    config.after_screenshot do |test_driver, production_driver, test_info|
        # same variables are available as with before_screenshot
    end

## Customizing Kontrast
Kontrast's hooks allow you to insert custom functionality into many parts of the test suite. Here are some examples of how we use hooks at Harry's:

### Integrating with HipChat
Once a build finishes, we let HipChat know if Kontrast found any diffs using the `hipchat` gem:

    config.after_gallery do |diffs, gallery_path|
        hipchat_room = "Kontrast Results"
        hipchat_user = "KontrastBot"

        if !diffs.empty?
            msg = "Kontrast Diffs: #{diffs.keys.join(', ')}. Don't push to production without reviewing these. You can find the gallery at #{gallery_path}."
            client = HipChat::Client.new(ENV["HIPCHAT_TOKEN"])
            client[hipchat_room].send(hipchat_user, msg, :color => "red")
        end
    end

### Setting Cookies
Testing our cart page required a bit more setup before we could take a screenshot of it:

    config.before_screenshot do |test_driver, production_driver, test|
        if test[:name] == "cart"
            # prepare our cookie value
            cookie_value = super_secret_magic_cart_cookie

            # write cookies using Mootools
            # http://mootools.net/docs/core/Utilities/Cookie
            test_driver.execute_script("Cookie.write('cart', '#{cookie_value}');")
            production_driver.execute_script("Cookie.write('cart', '#{cookie_value}');")

            # refresh the page
            test_driver.navigate.refresh
            production_driver.navigate.refresh
        end
    end

### Adding URL Parameters To All Pages
You may want to append a URL param to the end of every test path. To avoid doing something like this:

    config.pages(1280) do |page|
        page.home "/?mobile=1"
        page.about "/about?mobile=1"
    end

you can do this instead:

    config.pages(1280, { mobile: 1 }) do |page|
        page.home "/"
        page.about "/about"
    end

## Specs
To avoid cluttering up the Kontrast config with lots of per-test hook logic, we made an easy way for you to specify per-test hooks. We do this with specs, which are RSpec-inspired files that contain hooks which only run with their respective tests.

### How to Name Specs
The name of a spec is passed into the `Kontrast#describe` method. This spec is automatically bound to any test whose name includes the name of the spec. In the example below, this spec would only run on the `1280_home` test. But if you name your spec `home`, it will run on both the `320_home` and `1280_home` tests.

### How to Write Specs

    # 1280_home_spec.rb
    Kontrast.describe("1280_home") do |spec|
        spec.before_screenshot do |test_driver, production_driver, test|
            # Do some stuff before screenshotting the 1280_home page
        end

        spec.after_screenshot do |test_driver, production_driver, test|
            # Do some stuff after screenshotting the 1280_home page
        end
    end

### Where to Put Specs
Spec files should go into the `./kontrast_specs` folder by default and must end with `_spec.rb`. You can tell Kontrast to look for specs in a different path using the `--specs-path` flag. If you're using Rails and don't include the `--specs-path` flag, the specs should go in `"#{Rails.root}/kontrast_specs"`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
