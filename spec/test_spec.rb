describe Kontrast::Test do
    before :each do
        # Reset specs & tests
        Kontrast.get_spec_builder.clear!
        if !Kontrast.page_test_suite.nil?
            Kontrast.page_test_suite.clear!
        end

        # Add a spec and a test
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
        Kontrast.page_test_suite.bind_specs
    end

    it "can run a spec's callback" do
        test = Kontrast.page_test_suite.tests.first
        expect(test.run_callback(:before_screenshot, 1, 2, 3)).to eql("before! 1 2 3")
    end

    it "doesn't run a callback if it doesn't exist" do
        test = Kontrast.page_test_suite.tests.first
        expect { test.run_callback(:foo, 1) }.to raise_error(NoMethodError)
    end
end
