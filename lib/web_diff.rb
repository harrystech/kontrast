# Load classes
require "web_diff/configuration"
require "web_diff/selenium_handler"
require "web_diff/image_handler"
require "web_diff/gallery_creator"
require "web_diff/runner"

require "web_diff/version"

module WebDiff
    class << self
        def root
            File.expand_path('../..', __FILE__)
        end

        def run
            runner = Runner.new
            runner.run
        end
    end
end

# Load tasks
Dir.glob(WebDiff.root + '/lib/tasks/*.rake').each { |r| import r }