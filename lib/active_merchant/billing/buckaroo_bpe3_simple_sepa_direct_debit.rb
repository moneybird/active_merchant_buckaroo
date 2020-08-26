# frozen_string_literal: true

module ActiveMerchant
  module Billing
    class BuckarooBPE3SimpleSepaDirectDebitGateway < Gateway
      # ==== Options
      # * <tt>:secretkey</tt> -- The Buckaroo Secret Key (REQUIRED)
      # * <tt>:websitekey</tt> -- The Buckaroo Websitekey (REQUIRED)
      # * <tt>:sepa_mandate_prefix</tt> -- The Buckaroo Prefix for SEPA transactions (ie: "12F")
      #                                    (OPTIONAL)
      def initialize(options={})
        requires!(options, :secretkey, :websitekey)
        @options = options
        super
      end

      # ==== Options
      # * <tt>:collectdate</tt>         -- The date when it needs to be collected (REQUIRED)
      # * <tt>:culture</tt>             -- The language for the web interface, choices: DE, EN, NL.
      #                                    Default: EN (OPTIONAL)
      # * <tt>:curreny</tt>             -- The currency for the transaction, choices: EUR.
      #                                    Default: EUR (OPTIONAL)
      # * <tt>:customeraccountname</tt> -- The account name of the bank account (REQUIRED)
      # * <tt>:customerbic</tt>         -- The BIC code of the bank account (REQUIRED)
      # * <tt>:customeriban</tt>        -- The IBAN code of the bank account (REQUIRED)
      # * <tt>:description</tt>         -- The description for the transaction (REQUIRED)
      # * <tt>:invoicenumber</tt>       -- The invoicenumber for the transaction (REQUIRED)
      # * <tt>:mandatedate</tt>         -- The date of the mandate (REQUIRED)
      # * <tt>:mandatereference</tt>    -- The reference of the mandate (REQUIRED)
      def purchase(money, _, options={})
        requires!(options, :collectdate, :customeraccountname, :customerbic, :customeriban, :description, :invoicenumber, :mandatedate, :mandatereference)
        buckaroo_validate(money, options)

        mandatereference = options[:mandatereference]
        mandatereference = "#{@options[:sepa_mandate_prefix]}-#{mandatereference}" if @options[:sepa_mandate_prefix]

        post_params = {
          brq_amount: money,
          brq_channel: "CALLCENTER",
          brq_culture: options[:culture] ? options[:culture] : "EN",
          brq_currency: options[:currency] ? options[:currency] : "EUR",
          brq_description: options[:description],
          brq_invoicenumber: options[:invoicenumber],
          brq_payment_method: "simplesepadirectdebit",
          brq_service_simplesepadirectdebit_action: "Pay",
          brq_service_simplesepadirectdebit_collectdate: options[:collectdate].strftime("%Y-%m-%d"),
          brq_service_simplesepadirectdebit_customeraccountname: options[:customeraccountname],
          brq_service_simplesepadirectdebit_customerbic: options[:customerbic],
          brq_service_simplesepadirectdebit_customeriban: options[:customeriban],
          brq_service_simplesepadirectdebit_mandatedate: options[:mandatedate].strftime("%Y-%m-%d"),
          brq_service_simplesepadirectdebit_mandatereference: mandatereference,
          brq_startrecurrent: true,
          brq_websitekey: @options[:websitekey]
        }

        BuckarooBPE3Toolbox.call("TransactionRequest", post_params, @options[:secretkey], true)
      end

      private

      def buckaroo_validate(money, options)
        raise ArgumentError, "money should be more than 0" if money <= 0
        raise ArgumentError, "collectdate should be Date object" if options[:collectdate].class != Date
        raise ArgumentError, "customeraccountname should be max 40 chars long" if options[:customeraccountname].size > 40
        raise ArgumentError, "mandatedate should be Date object" if options[:mandatedate].class != Date
        raise ArgumentError, "culture should be DE, EN or NL" if options[:culture] && ![ "DE", "EN", "NL" ].include?(options[:culture])
        raise ArgumentError, "currency should be EUR" if options[:currency] && options[:currency] != "EUR"
        raise ArgumentError, "description should be max 40 chars long" if options[:description].size > 40
        raise ArgumentError, "invoicenumber should be max 40 chars long" if options[:invoicenumber].size > 40
      end
    end
  end
end
