require_relative 'watcher/url.rb'
require_relative 'watcher/notifier.rb'

module Watcher
  SETTINGS = YAML.load_file('settings.yaml')

  def self.logger
    unless @logger
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime} [#{severity}]: #{msg}\n"
      end
    end
    @logger
  end

  def self.every(delay, &b)
    Thread.new do
      until $exit
        begin
          b.call
        rescue Exception => e
          Watcher.logger.info "Watcher.every #{e.message}\n#{e.backtrace}"
        end
        sleep delay.to_f
      end
    end
  end

  def self.run
    monitors = []
    SETTINGS[:watcher].each do |w|
      monitor = Url.new(w)
      every w[:interval] do
        monitor.watch
      end
      monitors << monitor
    end

    sleep 5 # Give first url check for each time to finish
    notifier = Notifier.new monitors
    every 60 do
      notifier.monitor
    end
    
    sleep 3600 until $exit
  end
end