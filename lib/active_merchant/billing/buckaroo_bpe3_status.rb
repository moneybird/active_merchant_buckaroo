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

      def status_for_invoicenumber(options = {})
        requires!(options, :amount_invoice)
        requires!(options, :invoicenumber)

        raise ArgumentError.new("invoicenumber should be max 40 chars long") if options[:invoicenumber].size > 40

        # make sure this is in alphabetical order and without signature
        post_params = {
          brq_invoicenumber: options[:invoicenumber],
          brq_websitekey: @options[:websitekey],
        }

        brq_signature = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(post_params, @options[:secretkey])
        post_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_post_data(post_params, brq_signature)

        response_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.commit(@options[:url], post_data)
        # puts response_data
        response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(response_data, @options[:secretkey])
        return_params = { 
          post_data: post_data,
          post_params: post_params,
          response_parser: response_parser,
          amount_invoice: options[:amount_invoice]
        }

        if response_parser.valid?
          success = response_parser.response_params["brq_apiresult"].downcase == "success"
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(success, response_parser.statusmessage, return_params)
        else
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(false, "Invalid response", return_params)
        end

      end

    end
  end
end
