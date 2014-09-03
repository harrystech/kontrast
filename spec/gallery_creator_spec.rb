describe Chalcogen::GalleryCreator do
    before :all do
        Chalcogen.configure do |config|
        end
    end

    before :each do
        @image_handler = Chalcogen::ImageHandler.new
        @gallery_creator = Chalcogen::GalleryCreator.new(@image_handler.path)
    end

    it "can parse manifests" do
        # Create fake manifests
        manifest_1 = {
            files: ["1280_home/diff.png", "1280_home/diff_thumb.png", "1280_home/production.png", "1280_home/production_thumb.png", "1280_home/test.png", "1280_home/test_thumb.png"],
            diffs: {
                "1280_home" => {
                    width: 1280,
                    name: "home",
                    diff: 0.1337
                }
            }
        }

        manifest_2 = {
            files: ["320_home/production.png", "320_home/production_thumb.png", "320_home/test.png", "320_home/test_thumb.png", "320_home/diff.png", "320_home/diff_thumb.png"],
            diffs: {}
        }

        File.open("#{@image_handler.path}/manifest_0.json", 'w') do |outf|
            outf.write(manifest_1.to_json)
        end
        File.open("#{@image_handler.path}/manifest_1.json", 'w') do |outf|
            outf.write(manifest_2.to_json)
        end

        # Test get_manifests while we're at it
        manifests = @gallery_creator.get_manifests
        expect(manifests).to include(@image_handler.path + "/manifest_0.json", @image_handler.path + "/manifest_1.json")

        # Parse
        parsed_manifests = @gallery_creator.parse_manifests(manifests)
        expect(parsed_manifests).to eql({
            :files =>
                ["1280_home/diff.png",
                   "1280_home/diff_thumb.png",
                   "1280_home/production.png",
                   "1280_home/production_thumb.png",
                   "1280_home/test.png",
                   "1280_home/test_thumb.png",
                   "320_home/production.png",
                   "320_home/production_thumb.png",
                   "320_home/test.png",
                   "320_home/test_thumb.png",
                   "320_home/diff.png",
                   "320_home/diff_thumb.png"],
            :diffs => {
                "1280_home" => {
                    "width" => 1280,
                    "name" => "home",
                    "diff" => 0.1337
                }
            }
        })
    end

    it "can create the gallery hash" do
        files = ["1280_home/diff.png",
                   "1280_home/diff_thumb.png",
                   "1280_home/production.png",
                   "1280_home/production_thumb.png",
                   "1280_home/test.png",
                   "1280_home/test_thumb.png",
                   "320_home/production.png",
                   "320_home/production_thumb.png",
                   "320_home/test.png",
                   "320_home/test_thumb.png",
                   "320_home/diff.png",
                   "320_home/diff_thumb.png"]
        diffs = {
            "1280_home" => {
                "width" => 1280,
                "name" => "home",
                "diff" => 0.1337
            }
        }

        dirs = @gallery_creator.parse_directories(files, diffs)
        expect(dirs).to eql({
            "1280" => {
                "home" => {
                    :variants => [{:image=>"../1280_home/test.png", :thumb=>"../1280_home/test_thumb.png", :domain=>"test"},
                                {:image=>"../1280_home/production.png", :thumb=>"../1280_home/production_thumb.png", :domain=>"production"},
                                {:image=>"../1280_home/diff.png", :thumb=>"../1280_home/diff_thumb.png", :domain=>"diff", :diff_amt=>0.1337}]
                    }
                },
            "320" => {
                "home" => {
                    :variants => [{:image=>"../320_home/test.png", :thumb=>"../320_home/test_thumb.png", :domain=>"test"},
                                {:image=>"../320_home/production.png", :thumb=>"../320_home/production_thumb.png", :domain=>"production"},
                                {:image=>"../320_home/diff.png", :thumb=>"../320_home/diff_thumb.png", :domain=>"diff", :diff_amt=>0}]
                    }
            }
        })
    end
end
