module Watcher
  class Url
    attr_accessor :url, :expected, :interval, :name

    def initialize(attribs)
      attribs.each do |k, v|
        self.send("#{k}=", v) if [:url, :expected, :interval, :name].include? k
      end
      @current_status = :ok
    end
  
    def watch
      @previous_status = @current_status

      check = begin
        # Alternate solutions, however for this we need not redirect and not throw an error message
        # doc = Nokogiri::HTML(open('http://www.gusto.com'))
        # !!open(@url, :read_timeout => 3, :redirect => false).read.match(@expected)
      
        uri = URI.parse @url
        http = Net::HTTP.new uri.host, uri.port
        http.read_timeout = 3
        ### Reference
        ### http://stackoverflow.com/questions/4528101/ssl-connect-returned-1-errno-0-state-sslv3-read-server-certificate-b-certificat
        ### http://andre.arko.net/2012/02/19/openssl-certificate-validation-on-engine-yard/
        ### http://martinottenwaelter.fr/2010/12/ruby19-and-the-ssl-error/
        ### SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if uri.port == 443
        # http.verify_mode = OpenSSL::SSL::VERIFY_PEER if uri.port == 443
        # http.ca_file = 'ca-bundle.crt' if uri.port == 443
        http.use_ssl = true if uri.port == 443
        response = http.get uri.path.empty? ? '/' : uri.path
        !!response.body.match(@expected)
      
      rescue Exception => e
        error_message = e.message
        false
      end

      if check
        @current_status = :ok
      else
        @current_status = fail
      end
      Watcher.logger.info "Url.watch #{@url} #{@current_status.to_s} #{@previous_status.to_s} #{error_message}"
    end
  
    def fail
      case @previous_status
      when :ok
        :warn
      when :warn
        :fail
      when :fail
        :fail
      end
    end
    
    def notify?
      (@previous_status == :warn && @current_status == :fail) || (@previous_status == :fail && @current_status == :ok)
    end
  
    def failed?
      @current_status == :warn || @current_status == :fail
    end

    def notify_failed?
      @current_status == :fail && @previous_status == :warn
    end

    def notify_restored?
      @current_status == :ok && @previous_status == :fail
    end
  end
end