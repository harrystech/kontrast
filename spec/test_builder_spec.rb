describe Kontrast::TestBuilder do
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
        expect(Kontrast.test_suite.tests).to eql({
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
