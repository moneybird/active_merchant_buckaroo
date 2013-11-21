module ActiveMerchant
  module Billing
    class BuckarooBPE3SimpleSepaDirectDebitGateway < Gateway

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
      # * <tt>:collectdate</tt>         -- The date when it needs to be collected
      # * <tt>:culture</tt>             -- The language for the web interface, choices: DE, EN, NL. Default: EN (OPTIONAL)
      # * <tt>:curreny</tt>             -- The currency for the transaction, choices: EUR. Default: EUR (OPTIONAL)
      # * <tt>:customeraccountname</tt> -- The account name of the bank account
      # * <tt>:customerbic</tt>         -- The BIC code of the bank account
      # * <tt>:customeriban</tt>        -- The IBAN code of the bank account
      # * <tt>:description</tt>         -- The description for the transaction (REQUIRED)
      # * <tt>:invoicenumber</tt>       -- The invoicenumber for the transaction (REQUIRED)
      # * <tt>:mandatedate</tt>         -- The date of the mandate
      # * <tt>:mandatereference</tt>    -- The reference of the mandate
      def purchase(money, creditcard, options = {})
        requires!(options, :collectdate, :customeraccountname, :customerbic, :customeriban, :mandatedate, :mandatereference)

        raise ArgumentError.new("money should be more than 0") if money <= 0

        raise ArgumentError.new("accountname should be max 40 chars long") if options[:accountname].size > 40
        raise ArgumentError.new("accountnumber should be max 9 chars long") if options[:accountnumber].size > 9
        raise ArgumentError.new("invoicenumber should be max 40 chars long") if options[:invoicenumber].size > 40

        raise ArgumentError.new("culture should be DE, EN or NL") if options[:culture] and ![ "DE", "EN", "NL" ].include?(options[:culture])
        raise ArgumentError.new("currency should be EUR") if options[:currency] and ![ "EUR" ].include?(options[:currency])
        raise ArgumentError.new("description should be max 40 chars long") if options[:description].size > 40
        raise ArgumentError.new("invoicenumber should be max 40 chars long") if options[:invoicenumber].size > 40

        post_params = {
          brq_amount: money,
          brq_culture: options[:culture] ? options[:culture] : "EN",
          brq_currency: options[:currency] ? options[:currency] : "EUR",
          brq_description: options[:description],
          brq_invoicenumber: options[:invoicenumber],
          brq_payment_method: "simplesepadirectdebit",
          brq_service_simplesepadirectdebit_action: "Pay",
          brq_service_simplesepadirectdebit_customeraccountname: options[:customeraccountname],
          brq_service_simplesepadirectdebit_customerbic: options[:customerbic],
          brq_service_simplesepadirectdebit_customeriban: options[:customeriban],
          brq_websitekey: @options[:websitekey]
        }

        brq_signature = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(post_params, @options[:secretkey])
        post_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_post_data(post_params, brq_signature)

        response_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.commit(@options[:url], post_data)
        response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(response_data, @options[:secretkey])
        return_params = { 
          post_data: post_data,
          post_params: post_params,
          response_parser: response_parser
        }

        if response_parser.valid?
          # success = response_parser.statuscode == "791"
          success = response_parser.pending?
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(success, response_parser.statusmessage, return_params)
        else
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(false, "Invalid response", return_params)
        end

      end

    end

  end

end
