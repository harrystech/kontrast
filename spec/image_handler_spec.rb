describe WebDiff::ImageHandler do
    before :all do
        WebDiff.configure do |config|
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
        @image_handler = WebDiff::ImageHandler.new
    end

    it "can create a manifest for the current node" do
        # Create some files
        WebDiff.test_suite.tests.each do |size, tests|
            tests.each do |name, path|
                test_name = "#{size}_#{name}"
                path = FileUtils.mkdir_p(@image_handler.path + "/#{test_name}").join('')
                Dir.chdir(path)
                FileUtils.touch("diff_thumb.png")
            end
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
        expect(contents).to eql({
            :diffs => {
                "1280_home" => {
                    :width => 1280,
                    :name=> "home" ,
                    :diff => 0.1337
                }
            },
            :files => ["1280_home/diff_thumb.png", "1280_products/diff_thumb.png", "320_home/diff_thumb.png", "320_products/diff_thumb.png"]
        })
    end
end