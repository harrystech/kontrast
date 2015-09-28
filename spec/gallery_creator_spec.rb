describe Kontrast::GalleryCreator do
    before :all do
        Kontrast.configure do |config|
        end
    end

    before :each do
        @page_comparator = Kontrast::PageComparator.new
        @gallery_creator = Kontrast::GalleryCreator.new(@page_comparator.path)
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

        File.open("#{@page_comparator.path}/manifest_0.json", 'w') do |outf|
            outf.write(manifest_1.to_json)
        end
        File.open("#{@page_comparator.path}/manifest_1.json", 'w') do |outf|
            outf.write(manifest_2.to_json)
        end

        # Test get_manifests while we're at it
        manifests = @gallery_creator.get_manifests
        expect(manifests).to include(@page_comparator.path + "/manifest_0.json", @page_comparator.path + "/manifest_1.json")

        # Parse
        parsed_manifests = @gallery_creator.parse_manifests(manifests)

        expect(parsed_manifests[:diffs]).to eql({
            "1280_home" => {
                "width" => 1280,
                "name" => "home",
                "diff" => 0.1337
            }
        })

        expect(parsed_manifests[:files]).to include("1280_home/diff.png",
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
                   "320_home/diff_thumb.png")
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


        groups, without_diffs, with_diffs = @gallery_creator.parse_directories(files, diffs)

        expect(groups).to eq(['1280', '320'])
        expect(without_diffs).to eql({
            "320" => {
                "home" => [
                  {:image=>"../320_home/test.png", :thumb=>"../320_home/test_thumb.png", :domain=>"test", :type=>'page'},
                  {:image=>"../320_home/production.png", :thumb=>"../320_home/production_thumb.png", :domain=>"production", :type=>'page'},
                  {:image=>"../320_home/diff.png", :thumb=>"../320_home/diff_thumb.png", :domain=>"diff", :type=>'page'},
                ],
            },
        })

        expect(with_diffs).to eql({
            "1280" => {
                "home" => [
                  {:image=>"../1280_home/test.png", :thumb=>"../1280_home/test_thumb.png", :domain=>"test", :type=>'page'},
                  {:image=>"../1280_home/production.png", :thumb=>"../1280_home/production_thumb.png", :domain=>"production", :type=>'page'},
                  {:image=>"../1280_home/diff.png", :thumb=>"../1280_home/diff_thumb.png", :domain=>"diff", :diff_amt=>0.1337, :type=>'page'}
                ],
            },
        })
    end
end
