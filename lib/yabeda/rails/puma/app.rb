module Yabeda
  module Rails
    module Puma
      class App
        def initialize(cli)
          @cli = cli
        end

        def call(env)
          req = Rack::Request.new(env)
          if env['REQUEST_PATH'] == '/metric' && req.post?
            json = JSON.parse(req.body.read)
            if json['action'] == 'register'
              params = json['args'].symbolize_keys.keep_if { |k, v| k != :name }
              ::Yabeda.configure do
                group json['args']['group']
                if json['type'] == 'counter'
                  counter json['args']['name'], **params
                elsif json['type'] == 'gauge'
                  gauge json['args']['name'], **params
                elsif json['type'] == 'histogram'
                  histogram json['args']['name'], **params
                end
              end
            elsif json['action'] == 'perform'
              if json['type'] == 'counter'
                ::Yabeda.send(json['name']).increment(json['labels'].symbolize_keys)
              elsif json['type'] == 'gauge'
                ::Yabeda.send(json['name']).set(json['labels'].symbolize_keys, json['value'])
              elsif json['type'] == 'histogram'
                ::Yabeda.send(json['name']).measure(json['labels'].symbolize_keys, json['value'])
              end
            end
            return rack_response(200, 'ok')
          else
            rack_response 404, "Unsupported action", 'text/plain'
          end
        end

        private

        def rack_response(status, body, content_type='application/json')
          headers = {
            'Content-Type' => content_type,
            'Content-Length' => body.bytesize.to_s
          }

          [status, headers, [body]]
        end
      end
    end
  end
end
 
