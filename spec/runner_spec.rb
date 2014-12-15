describe Kontrast::Runner do
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
    end

    before :each do
        @runner = Kontrast::Runner.new
    end

    describe "split_run" do
        it "return all tests when there is only one node" do
            expect(@runner.split_run(1, 0).to_h).to eql(Kontrast.test_suite.to_h)
        end

        it "returns a subset of the tests when there are multiple nodes" do
            tests = @runner.split_run(4, 0)

            expect(tests).not_to eql Kontrast.test_suite.tests
            expect(tests.to_h).to eql({
                1280 => {
                    "home" => "/"
                }
            })
        end
    end
end
