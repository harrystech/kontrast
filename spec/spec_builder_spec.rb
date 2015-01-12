describe Kontrast::SpecBuilder do
    before :each do
        # Reset the spec suite
        Kontrast.get_spec_builder.clear!
    end

    context "with a spec description" do
        before :each do
            Kontrast.describe("test_spec") do |spec|
                spec.before_screenshot do |test_driver, production_driver, test|
                    "before! #{test_driver} #{production_driver} #{test}"
                end
                spec.after_screenshot do |test_driver, production_driver, test|
                    "after! #{test_driver} #{production_driver} #{test}"
                end
            end
        end

        it "can build a spec" do
            expect(Kontrast.get_spec_builder.specs.length).to eql 1
            expect(Kontrast.get_spec_builder.specs.first.name).to eql "test_spec"
        end

        it "can run the spec's callbacks along with arguments" do
            before_response = Kontrast.get_spec_builder.specs.first.before_screenshot(1, 2, 3)
            expect(before_response).to eql("before! 1 2 3")

            after_response = Kontrast.get_spec_builder.specs.first.after_screenshot(1, 2, 3)
            expect(after_response).to eql("after! 1 2 3")
        end
    end
end
