module Yabeda
  module Rails
    module Puma
      class MetricsReceiveMiddleware
        def initialize(app, _)
          @app = app
        end

        def call(env)
          req = Rack::Request.new(env)
          if req.post?
            json = JSON.parse( req.body.read )
            if json['action'] == 'register' && json['type'] == 'counter'
              Yabeda.configure do
                group :rails
                counter json['name'], comment: json['comment']
              end
            elsif json['action'] == 'perform' && json['type'] == 'counter'
              Yabeda.send(json['name']).increment(json['labels'])
            end
            [200, { "Content-Type" => "text/plain" }, ["ok\n"]]
          else
            @app.call(env)
          end
        end
      end
    end
  end
end
