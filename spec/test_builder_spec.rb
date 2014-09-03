describe Chalcogen::TestBuilder do
    it "can build a test suite" do
        Chalcogen.configure do |config|
            config.pages(1280) do |page|
                page.home "/"
                page.products "/products"
            end
            config.pages(320) do |page|
                page.home "/"
                page.other_stuff = "/other-stuff"
            end
        end
        expect(Chalcogen.test_suite.tests).to eql({
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
end
