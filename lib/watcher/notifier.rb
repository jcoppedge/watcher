module Watcher
  class Notifier
    def initialize(monitors)
      @monitors = monitors
      @oksent = true
    end

    def monitor
      messages = []
      allok = true
      @monitors.each do |m|
        if m.notify_failed?
          messages << m.name
          allok = false
        end

        if m.notify_restored?
          messages << m.name+"*0"
        end
      
        if m.failed?
          allok = false
        end
      
      end
    
      if allok && !@oksent
        @oksent = true
        message = "OK"
      elsif !messages.empty?
        @oksent = false
        message = "#{messages.join(' ')}"
      end

      Watcher.logger.info "Notifier.monitor #{message}"
      send(message) if message

    end

    def send(message)
      response = RestClient.post SETTINGS[:mailgun][:api_url]+"/messages", 
          :from => SETTINGS[:notification][:email][:from],
          :to => SETTINGS[:notification][:email][:to],
          :bcc => SETTINGS[:notification][:email][:bcc],
          :subject => SETTINGS[:notification][:email][:subject],
          :text => message
      Watcher.logger.info "Notifier.send response:\n#{response}"
    end
  end
end