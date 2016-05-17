require 'spec_helper'

describe Kontrast::ApiEndpointComparator do
    let(:app_id) { '123' }
    let(:app_secret) { '123' }
    let(:comparator) { Kontrast::ApiEndpointComparator.new }
    let(:access_token_response) { {'token' => {'access_token' => '123'}} }
    let(:test_client_connection) {
        Faraday.new do |builder|
            builder.adapter :test do |stub|
                stub.post('/api/v2/oauth/token') { |env| [ 200, {}, access_token_response.to_json ]}
                stub.get('/api/v2/screen/home') { |env| [ 200, {}, {'foo' => 'bar'}.to_json ]}
                stub.get('/api/v2/screen/products') { |env| [ 200, {}, {}.to_json ]}
            end
        end
    }
    let(:fake_test) { double('test', to_s: 'fake_test', headers: {}, path: '/screen/home', name: 'home') }

    let(:prod_client_connection) {
        Faraday.new do |builder|
            builder.adapter :test do |stub|
                stub.post('/api/v2/oauth/token') { |env| [ 200, {}, access_token_response.to_json ]}
                stub.get('/api/v2/screen/home') { |env| [ 200, {}, {'foo' => 'bar'}.to_json ]}
                stub.get('/api/v2/screen/products') { |env| [ 200, {}, {}.to_json ]}
            end
        end
    }

    before do
        Kontrast.configure {}
        Kontrast.configuration.test_oauth_app_proc = proc { double('app', uid: '123', secret: 'abc') }
    end

    context 'text data' do
        context 'with similar data' do
            it "returns true" do
                test_home_response = {'foo' => 'bar', 'nested' => {'data' => {'should' => 'work'}}}
                allow(comparator.test_client).to receive(:fetch_token)
                allow(comparator.test_client).to receive(:fetch).with('/screen/home', anything)
                allow(comparator.test_client.responses).to receive(:[]).with('/screen/home').and_return(test_home_response)

                prod_home_response = {'foo' => 'bar', 'nested' => {'data' => {'should' => 'work'}}}
                allow(comparator.prod_client).to receive(:fetch_token)
                allow(comparator.prod_client).to receive(:fetch).with('/screen/home', anything)
                allow(comparator.prod_client.responses).to receive(:[]).with('/screen/home').and_return(prod_home_response)

                expect(comparator.diff(fake_test)).to eq({images: []})
            end
        end

        context 'with different data' do
            it "returns the diff" do
                test_home_response = {'foo' => 'bar'}
                allow(comparator.test_client).to receive(:fetch_token)
                allow(comparator.test_client).to receive(:fetch).with('/screen/home', anything)
                allow(comparator.test_client.responses).to receive(:[]).with('/screen/home').and_return(test_home_response)

                prod_home_response = {'foo' => 'baz'}
                allow(comparator.prod_client).to receive(:fetch_token)
                allow(comparator.prod_client).to receive(:fetch).with('/screen/home', anything).and_return(prod_home_response)
                allow(comparator.prod_client.responses).to receive(:[]).with('/screen/home').and_return(prod_home_response)

                expect(comparator.diff(fake_test)).to eq({type: 'api_endpoint', images: [], name: 'home', diff: 1})
            end
        end
    end

    context 'images' do
        let(:test_home_response) {
            {
                'foo' => 'bar',
                'nested' => {
                    'data' => {
                        'should' => 'work',
                        'image' => image1.path,
                    }
                },
                'array1' => [1, 2, 'foo', {'a' => 'b'}, image1.path],
                'array2' => [1,2,3],
            }
        }

        let(:prod_home_response) {
            {
                'foo' => 'bar',
                'nested' => {
                    'data' => {
                        'should' => 'work',
                        'image' => image2.path,
                    }
                },
                'array1' => [1, 2, 'foo', {'a' => 'b'}, image2.path],
                'array2' => [1,2,3],
            }
        }

        before do
            allow(comparator.test_client).to receive(:fetch_token)
            allow(comparator.test_client).to receive(:fetch).with('/screen/home', anything)
            allow(comparator.test_client.responses).to receive(:[]).with('/screen/home').and_return(test_home_response)

            allow(comparator.prod_client).to receive(:fetch_token)
            allow(comparator.prod_client).to receive(:fetch).with('/screen/home', anything)
            allow(comparator.prod_client.responses).to receive(:[]).with('/screen/home').and_return(prod_home_response)
        end

        context 'with similar data' do
            let(:image1) { File.new(File.expand_path("./spec/support/fixtures/image.jpg")) }
            let(:image2) { File.new(File.expand_path("./spec/support/fixtures/image_clone.jpg")) }

            it "returns true" do
                expect(comparator.diff(fake_test)).to eq({images: []})
            end
        end

        context 'with different data' do
            let(:image1) { File.new(File.expand_path("./spec/support/fixtures/image.jpg")) }
            let(:image2) { File.new(File.expand_path("./spec/support/fixtures/other_image.jpg")) }

            it "returns false" do
                expect(comparator.diff(fake_test)).to eq({type: 'api_endpoint', images: [{:index=>0}, {:index=>1}], name: 'home', diff: 1})
            end
        end
    end

    context 'load_image_file' do
        it "retries if downloading image failed"
    end
end
