require 'puma/plugin'
require 'yabeda/rails'

Puma::Plugin.create do
  def start(launcher)
    require 'tmpdir'
    t = (Time.now.to_f * 1000).to_i
    path = "#{Dir.tmpdir}/yabeda-rails-#{t}-#{$$}"
    Yabeda::Rails.metrics_receive_url = path

    str = "unix://#{path}"
    uri = URI.parse str

    require 'yabeda/rails/puma/app'
    app = ::Yabeda::Rails::Puma::App.new launcher
    control = Puma::Server.new app, launcher.events
    control.min_threads = 0
    control.max_threads = 1

    path = "#{uri.host}#{uri.path}"

    control.add_unix_listener path, nil
    control.run
  end
end
