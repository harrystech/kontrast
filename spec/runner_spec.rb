describe WebDiff::Runner do
    before :all do
        WebDiff.configure do |config|
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
        @runner = WebDiff::Runner.new
    end

    describe "split_run" do
        it "return all tests when there is only one node" do
            expect(@runner.split_run(1, 0)).to eql(WebDiff.test_suite.tests)
        end

        it "returns a subset of the tests when there are multiple nodes" do
            tests = @runner.split_run(4, 0)

            expect(tests).not_to eql WebDiff.test_suite.tests
            expect(tests).to eql({
                1280 => {
                    "home" => "/"
                },
                320 => {}
            })
        end
    end
end