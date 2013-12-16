module ActiveMerchant
  module Billing
    class BuckarooBPE3Toolbox

      def self.check_signature(params, secretkey)
        signature = params["brq_signature"] || params["BRQ_SIGNATURE"]
        new_params = {}
        params.each do |k,v|
          new_params[k] = v if k.kind_of?(String) and k.downcase != "brq_signature"
        end
        signature == BuckarooBPE3Toolbox.create_signature(new_params, secretkey)
      end

      def self.create_post_data(params, signature)
        Rack::Utils.build_query(params) + "&brq_signature=" + signature
      end

      def self.create_signature(params, secretkey)
        sorted_params = ActiveMerchant::Billing::BuckarooBPE3Toolbox.sort_hash(params)
        str_sig = sorted_params.map{|k,v| "#{k}=#{v}"}.join
        sig = Digest::SHA1.hexdigest(str_sig + secretkey)
        # TODO
        # puts sig
        sig
      end
      
      def self.commit(url, post_data, read_timeout = 300)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = read_timeout
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ActiveMerchant::Billing::Base.test?
        http.post(uri.request_uri, post_data, { 'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8' }).body
      end

      def self.sort_hash(params)
        params.sort_by { |f| f.first.downcase }
      end

      def self.hash_to_downcase_keys(the_hash)
        new_hash = {}
        the_hash.each do |key, value|
          if key.kind_of?(String)
            new_hash[key.downcase] = value
          else
            new_hash[key] = value
          end
        end
        new_hash
      end

    end

  end

end
