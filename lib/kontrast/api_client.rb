require 'faraday'

module Kontrast
    class ApiClient

        attr_reader :responses, :env
        attr_writer :headers

        def initialize(env, host, app_id, app_secret, headers: {})
            @env = env
            @host = host
            @app_id = app_id
            @app_secret = app_secret
            @connection = nil
            @responses = {}
            @headers = headers
        end

        def fetch(path, save_file: false, folder_name: "")
            response = connection.get(path) do |req|
                req.headers['Authorization'] = "Bearer #{token}"
                req.headers.merge!(@headers)
            end
            data = JSON.parse(response.body)
            if save_file
                open(File.join(Kontrast.path, folder_name, "#{@env}.json"), 'wb') do |file|
                    file << JSON.pretty_generate(data)
                end
            end
            @responses[path] = data
            return data
        end

        def token
            return @token || fetch_token
        end

        def fetch_token
            return @token if !@token.nil? && @token != ''

            response = connection.post(Kontrast.configuration.oauth_token_url, {
                grant_type: 'client_credentials',
                client_id: @app_id,
                client_secret: @app_secret,
            })
            @token = Kontrast.configuration.oauth_token_from_response.call(response.body)
        end

        def connection
            @connection ||= Faraday.new(url: @host) do |faraday|
                faraday.request :url_encoded
                faraday.adapter Faraday.default_adapter
            end
        end
    end
end
