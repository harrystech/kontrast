describe Kontrast::Test do
    before :each do
        Kontrast.describe("test") do |spec|
            spec.before_screenshot do |test_driver, production_driver, test|
                "before! #{test_driver} #{production_driver} #{test}"
            end
        end
        Kontrast.configure do |config|
            config.pages(1280) do |page|
                page.test "/"
            end
        end
        Kontrast.test_suite.bind_specs
    end

    it "can run a spec's callback" do
        test = Kontrast.test_suite.tests.first
        expect(test.run_callback(:before_screenshot, 1, 2, 3)).to eql("before! 1 2 3")
    end

    it "doesn't run a callback if it doesn't exist" do
        test = Kontrast.test_suite.tests.first
        expect { test.run_callback(:foo, 1) }.to raise_error(NoMethodError)
    end
end
