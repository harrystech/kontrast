describe Kontrast::GlobalRunner do
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

        Kontrast.configuration.test_oauth_app_proc = proc { double('app', uid: '123', secret: 'abc') }
    end

    before :each do
        @page_comparator = Kontrast::PageComparator.new

        @page_runner = Kontrast::PageRunner.new
        @page_runner.instance_variable_set("@page_comparator", @page_comparator)

        @runner = Kontrast::GlobalRunner.new
        @runner.instance_variable_set("@page_runner", @page_runner)
    end

    it "can create a manifest for the current node" do
        # Create some files
        Kontrast.page_test_suite.tests.each do |test|
            test_name = "#{test.width}_#{test.name}"
            path = FileUtils.mkdir_p(@page_comparator.path + "/#{test_name}").join('')
            FileUtils.touch(File.join(path, 'diff_thumb.png'))
        end

        # Create a diff
        @page_runner.diffs["1280_home"] = {
            width: 1280,
            name: "home",
            diff: 0.1337
        }

        # Create the manifest
        contents = @runner.create_manifest

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
