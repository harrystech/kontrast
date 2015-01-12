describe Kontrast::Runner do
    before :all do
        Kontrast.configure do |config|
            # Set up some tests
            config.pages(1280) do |page|
                page.home "/"
                page.products "/products"
            end
            config.pages(320) do |page|
                page.home "/"
                page.products "/products"
            end
        end
    end

    before :each do
        @runner = Kontrast::Runner.new
    end

    describe "split_run" do
        it "return all tests when there is only one node" do
            suite = Kontrast::TestSuite.new
            @runner.split_run(1, 0).each { |t| suite << t }
            expect(suite.to_h).to eql(Kontrast.test_suite.to_h)
        end

        it "returns a subset of the tests when there are multiple nodes" do
            # Expect no split to be complete but all splits should combine into the total suite
            collector_hash = Hash.new
            (0..3).each do |i|
                tests = @runner.split_run(4, i)
                suite = Kontrast::TestSuite.new
                tests.each { |t| suite << t }
                expect(suite.to_h).to_not eql(Kontrast.test_suite.to_h)

                suite.tests.each do |test|
                    collector_hash[test.width] ||= {}
                    collector_hash[test.width][test.name] = test.path
                end
            end

            expect(collector_hash).to eql(Kontrast.test_suite.to_h)
        end
    end
end
