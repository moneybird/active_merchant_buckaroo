require 'nokogiri'

module ActiveMerchant
  module Billing
    class BuckarooBPE3StatusGateway < Gateway

      # ==== Options
      # * <tt>:secretkey</tt> -- The Buckaroo Secret Key (REQUIRED)
      # * <tt>:websitekey</tt> -- The Buckaroo Websitekey (REQUIRED)
      def initialize(options = {})
        requires!(options, :secretkey, :websitekey)
        @options = options
        @options[:url] = ActiveMerchant::Billing::Base.test? ? "https://testcheckout.buckaroo.nl/nvp/" : "https://checkout.buckaroo.nl/nvp/"
        @options[:url] += "?op=InvoiceInfo"
        super
      end

      def status_for_invoicenumber(options)
        requires!(options, :invoicenumber)

        raise ArgumentError.new("invoicenumber should be max 20 chars long") if options[:invoicenumber].size > 20

        # make sure this is in alphabetical order and without signature
        post_params = {
          brq_invoicenumber: options[:invoicenumber],
          brq_websitekey: @options[:websitekey],
        }

        brq_signature = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(post_params, @options[:secretkey])
        post_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_post_data(post_params, brq_signature)

        response_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.commit(@options[:url], post_data)
        if !response_data.blank?
          response_params = Rack::Utils.parse_query(response_data)
          puts response_params.inspect
          
          check = ActiveMerchant::Billing::BuckarooBPE3Toolbox.check_signature(response_params, @options[:secretkey])
          puts check
          
          # TODO WORK IN PROGRESS
        end

      end

    end
  end
end
