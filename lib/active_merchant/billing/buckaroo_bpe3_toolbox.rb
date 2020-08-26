# frozen_string_literal: true

module ActiveMerchant
  module Billing
    class BuckarooBPE3Toolbox
      def self.buckaroo_url
        if ActiveMerchant::Billing::Base.test?
          "https://testcheckout.buckaroo.nl/nvp/"
        else
          "https://checkout.buckaroo.nl/nvp/"
        end
      end

      def self.call(operation, post_params, secretkey, pending, return_params={})
        brq_signature = create_signature(post_params, secretkey)
        post_data = create_post_data(post_params, brq_signature)

        response_data = commit("#{buckaroo_url}?op=#{operation}", post_data)
        response_parser = BuckarooBPE3ResponseParser.new(response_data, secretkey)
        return_params.merge!(
          {
            post_data: post_data,
            post_params: post_params,
            response_parser: response_parser
          }
        )

        if response_parser.valid?
          success = pending ? response_parser.pending? : response_parser.success?
          BuckarooBPE3Response.new(success, response_parser.statusmessage, return_params)
        else
          BuckarooBPE3Response.new(false, "Invalid response", return_params)
        end
      end

      def self.check_signature(params, secretkey)
        signature = params["brq_signature"] || params["BRQ_SIGNATURE"]
        new_params = params.select do |key, *|
          key.respond_to?(:casecmp) && !key.casecmp('brq_signature').zero?
        end
        signature == create_signature(new_params, secretkey)
      end

      def self.create_post_data(params, signature)
        "#{Rack::Utils.build_query(params)}&brq_signature=#{signature}"
      end

      def self.create_signature(params, secretkey)
        sorted_params = sort_hash(params)
        str_sig = sorted_params.map{|k, v| "#{k}=#{v}" }.join
        Digest::SHA1.hexdigest(str_sig + secretkey)
      end

      def self.commit(url, post_data, read_timeout=300)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = read_timeout
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ActiveMerchant::Billing::Base.test?
        headers = { 'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8' }
        http.post(uri.request_uri, post_data, headers).body
      end

      def self.hash_to_downcase_keys(the_hash)
        the_hash.transform_keys do |key|
          key.respond_to?(:downcase) ? key.downcase : key
        end
      end

      def self.sort_hash(params)
        params.sort_by {|f| f.first.downcase.to_s.split('_') }
      end
    end
  end
end
