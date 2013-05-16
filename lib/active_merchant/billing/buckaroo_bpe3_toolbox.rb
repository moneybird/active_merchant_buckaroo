module ActiveMerchant
  module Billing
    class BuckarooBPE3Toolbox

      def self.check_signature(params, secretkey)
        signature = params.delete("BRQ_SIGNATURE") || params.delete("brq_signature")
        signature == BuckarooBPE3Toolbox.create_signature(params, secretkey)
      end

      def self.create_post_data(params, signature)
        Rack::Utils.build_query(params) + "&brq_signature=" + signature
      end

      def self.create_signature(params, secretkey)
        str_sig = params.sort.map{|k,v| "#{k}=#{v}"}.join
        Digest::SHA1.hexdigest(str_sig + secretkey)
      end
      
      def self.commit(url, post_data)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 300
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ActiveMerchant::Billing::Base.test?
        http.post(uri.request_uri, post_data, { 'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8' }).body
      end
    end
  end
end
