module ActiveMerchant
  module Billing
    class BuckarooBPE3DirectDebitGateway < Gateway

      # ==== Options
      # * <tt>:secretkey</tt> -- The Buckaroo Secret Key (REQUIRED)
      # * <tt>:websitekey</tt> -- The Buckaroo Websitekey (REQUIRED)
      def initialize(options = {})
        requires!(options, :secretkey, :websitekey)
        @options = options
        @options[:url] = ActiveMerchant::Billing::Base.test? ? "https://testcheckout.buckaroo.nl/nvp/" : "https://checkout.buckaroo.nl/nvp/"
        @options[:url] += "?op=TransactionRequest"
        super
      end

      # ==== Options
      # * <tt>:recurring</tt> -- Whether the purchase is a normal direct debit or recurring direct debit, DEFAULT: false (OPTIONAL)
      def purchase(money, creditcard, options = {})
        requires!(options, :accountname, :accountnumber, :description, :invoicenumber)

        raise ArgumentError.new("money should be more than 0") if money <= 0

        raise ArgumentError.new("accountname should be max 40 chars long") if options[:accountname].size > 40
        raise ArgumentError.new("accountnumber should be max 9 chars long") if options[:accountnumber].size > 9
        raise ArgumentError.new("description should be max 40 chars long") if options[:description].size > 40
        raise ArgumentError.new("invoicenumber should be max 40 chars long") if options[:invoicenumber].size > 40

        recurring = options[:recurring] || false

        # make sure this is in alphabetical order and without signature
        if recurring
          post_params = {
            brq_amount: money,
            brq_culture: "NL",
            brq_currency: "EUR",
            brq_description: options[:description],
            brq_invoicenumber: options[:invoicenumber],
            brq_payment_method: "directdebitrecurring",
            brq_service_directdebitrecurring_action: "Pay",
            brq_service_directdebitrecurring_customeraccountname: options[:accountname],
            brq_service_directdebitrecurring_customeraccountnumber: options[:accountnumber],
            brq_websitekey: @options[:websitekey]
          }
        else
          post_params = {
            brq_amount: money,
            brq_culture: "NL",
            brq_currency: "EUR",
            brq_description: options[:description],
            brq_invoicenumber: options[:invoicenumber],
            brq_payment_method: "directdebit",
            brq_service_directdebit_action: "Pay",
            brq_service_directdebit_customeraccountname: options[:accountname],
            brq_service_directdebit_customeraccountnumber: options[:accountnumber],
            brq_websitekey: @options[:websitekey]
          }
        end

        brq_signature = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(post_params, @options[:secretkey])
        post_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_post_data(post_params, brq_signature)

        response_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.commit(@options[:url], post_data)
        if !response_data.blank?
          response_params = Rack::Utils.parse_query(response_data)
          statuscode = response_params["BRQ_STATUSCODE"]
          return_params = { 
            post_data: post_data,
            post_params: post_params,
            response_data: response_data,
            response_params: response_params,
            statuscode: statuscode,
          }
          
          check = ActiveMerchant::Billing::BuckarooBPE3Toolbox.check_signature(response_params, @options[:secretkey])
          if !check
            return ActiveMerchant::Billing::BuckarooBPE3DirectDebitPurchaseResponse.new(false, "Signature validation error", return_params)
          end
          
          if statuscode == "791"
            return ActiveMerchant::Billing::BuckarooBPE3DirectDebitPurchaseResponse.new(true, response_params["BRQ_STATUSMESSAGE"], return_params)
          else
            return ActiveMerchant::Billing::BuckarooBPE3DirectDebitPurchaseResponse.new(false, response_params["BRQ_STATUSMESSAGE"], return_params)
          end
        else
          return ActiveMerchant::Billing::BuckarooBPE3DirectDebitPurchaseResponse.new(false, "Emptry response", { post_data: post_data, post_params: post_params })
        end

      end

    end
  end
end
