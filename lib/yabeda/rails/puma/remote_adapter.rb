module Yabeda
  module Rails
    module Puma
      class RemoteAdapter < Yabeda::BaseAdapter
        def register_counter!(_metric)
          register_metric(_metric)
          send({
            action: :register,
            type: _metric.class.name.demodulize.downcase,
            args: _metric.class.dry_initializer.attributes(_metric)
          })
        end

        def perform_counter_increment!(_counter, _tags, _increment)
          send({
            action: :perform,
            type: :counter,
            name: "#{_counter.group}_#{_counter.name}",
            labels: _tags
          })
        end

        def register_gauge!(_metric)
          register_metric(_metric)
        end

        def perform_gauge_set!(_metric, _tags, _value)
          send({
            action: :perform,
            type: :gauge,
            name: "#{_metric.group}_#{_metric.name}",
            labels: _tags,
            value: _value
          })
        end

        def register_histogram!(_metric)
          register_metric(_metric)
        end

        def perform_histogram_measure!(_metric, _tags, _value)
          send({
            action: :perform,
            type: :histogram,
            name: "#{_metric.group}_#{_metric.name}",
            labels: _tags,
            value: _value
          })
        end

        private

        def register_metric(_metric)
          send({
            action: :register,
            type: _metric.class.name.demodulize.downcase,
            args: _metric.class.dry_initializer.attributes(_metric)
          })
 
        end
        def send(obj)
          message = obj.to_json

          Socket.unix(Yabeda::Rails.metrics_receive_url) do |socket|
            socket.write("POST /metric HTTP/1.1\r\n")
            socket.write("Host: #{@host}\r\n")
            socket.write("Connection: Close\r\n")
            socket.write("Content-Type: application/json\r\n")
            socket.write("Content-Length: #{message.bytesize}\r\n")

            socket.write("\r\n")
            socket.write(message)
            socket.write("\r\n")
          end
        end
      end
    end
  end
end

