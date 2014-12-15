describe Kontrast::TestBuilder do
    before :each do
        # Reset the test suite
        if !Kontrast.test_suite.nil?
            Kontrast.test_suite.send(:clear)
        end
    end

    it "can build a test suite" do
        Kontrast.configure do |config|
            config.pages(1280) do |page|
                page.home "/"
                page.products "/products"
            end
            config.pages(320) do |page|
                page.home "/"
                page.other_stuff = "/other-stuff"
            end
        end

        expect(Kontrast.test_suite.to_h).to eql({
            1280 => {
                "home" => "/",
                "products" => "/products"
            },
            320 => {
                "home" => "/",
                "other_stuff=" => "/other-stuff"
            }
        })
    end

    it "can build a test suite with only one set of pages" do
        Kontrast.configure do |config|
            config.pages(1280) do |page|
                page.home "/"
            end
        end
        expect(Kontrast.test_suite.to_h).to eql({
            1280 => {
                "home" => "/"
            }
        })
    end

    it "does not accept the test name 'tests'" do
        expect {
            Kontrast.configure do |config|
                config.pages(1280) do |page|
                    page.tests "/"
                end
            end
        }.to raise_error(/not a valid name/)
    end
end
