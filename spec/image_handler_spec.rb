describe Kontrast::ImageHandler do
    before :all do
        Kontrast.configure do |config|
            # Set up some tests
            config.pages(1280) do |page|
                page.home "/"
                page.products "/"
            end
            config.pages(320) do |page|
                page.home "/"
                page.products "/"
            end
        end
    end

    before :each do
        @image_handler = Kontrast::ImageHandler.new
    end

    it "can create a manifest for the current node" do
        # Create some files
        Kontrast.test_suite.tests.each do |test|
            test_name = "#{test.width}_#{test.name}"
            path = FileUtils.mkdir_p(@image_handler.path + "/#{test_name}").join('')
            Dir.chdir(path)
            FileUtils.touch("diff_thumb.png")
        end

        # Create a diff
        @image_handler.diffs["1280_home"] = {
            width: 1280,
            name: "home",
            diff: 0.1337
        }

        # Create the manifest
        contents = @image_handler.create_manifest(0)

        # Expectations
        expect(contents[:diffs]).to eql({
            "1280_home" => {
                :width => 1280,
                :name=> "home" ,
                :diff => 0.1337
            }
        })

        expect(contents[:files]).to include("1280_home/diff_thumb.png", "1280_products/diff_thumb.png", "320_home/diff_thumb.png", "320_products/diff_thumb.png")
    end
end