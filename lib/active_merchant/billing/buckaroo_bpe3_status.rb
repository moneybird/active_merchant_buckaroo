# frozen_string_literal: true

require 'nokogiri'

module ActiveMerchant
  module Billing
    class BuckarooBPE3StatusGateway < Gateway
      # ==== Options
      # * <tt>:secretkey</tt>  -- The Buckaroo Secret Key (REQUIRED)
      # * <tt>:websitekey</tt> -- The Buckaroo Websitekey (REQUIRED)
      def initialize(options={})
        requires!(options, :secretkey, :websitekey)
        @options = options
        super
      end

      # ==== Options
      # * <tt>:amount_invoice</tt> -- Needed to check whether invoice is paid or not (REQUIRED)
      # * <tt>:invoicenumber</tt>  -- The invoice number (REQUIRED)
      def status_for_invoicenumber(options={})
        requires!(options, :amount_invoice, :invoicenumber)

        raise ArgumentError, "invoicenumber should be max 40 chars long" if options[:invoicenumber].size > 40

        # make sure this is in alphabetical order and without signature
        post_params = {
          brq_invoicenumber: options[:invoicenumber],
          brq_websitekey: @options[:websitekey]
        }
        return_params = {
          amount_invoice: options[:amount_invoice]
        }

        BuckarooBPE3Toolbox.call("InvoiceInfo", post_params, @options[:secretkey], false, return_params)
      end
    end
  end
end
