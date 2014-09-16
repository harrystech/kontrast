# This should get you up and running
# Check out the full list of config options at:
# https://github.com/harrystech/kontrast

Kontrast.configure do |config|

    # This is the address of your local server
    config.test_domain = "http://localhost:4000"

    # This is the address of your production server
    config.production_domain = "http://www.example.com"

    # Set this to true if you want Kontrast to return
    # an exit code of 1 if any diffs are found
    config.fail_build = false

    # These tests will open in a 1280px-wide browser window
    config.pages(1280) do |page|
        page.home "/"
        page.about "/about"
    end

    # These tests will open in a 320px-wide browser window
    config.pages(320) do |page|
        page.home "/"
        page.about "/about"
    end
end
