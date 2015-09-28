describe Kontrast::PageComparator do
    before :all do
        Kontrast.configure {}
    end

    let(:page_comparator) { Kontrast::PageComparator.new }
    let(:img1_path) { File.expand_path("./spec/support/fixtures/img1.jpg") }
    let(:img2_path) { File.expand_path("./spec/support/fixtures/img2.jpg") }
    let(:test) { double("Test", width: 1280, name: 'fake_test', to_s: '1280') }

    before do
        allow(page_comparator).to receive(:test_image_path).with(anything).and_return(img1_path)
        allow(page_comparator).to receive(:production_image_path).with(anything).and_return(img2_path)
    end

    it "can diff images" do

        page_comparator.diff(test)

        # The diff might be different on other systems
        diff = page_comparator.diffs['1280'].delete(:diff)
        expect(page_comparator.diffs).to eq({
            '1280' => {
                type: 'page',
                width: 1280,
                name: 'fake_test',
            }
        })
        expect(diff).to be_within(0.0001).of(0.1985086492134394)
    end
end
