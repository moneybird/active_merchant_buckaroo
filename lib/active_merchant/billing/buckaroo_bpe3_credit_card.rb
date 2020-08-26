# frozen_string_literal: true

module ActiveMerchant
  module Billing
    class BuckarooBPE3CreditCardGateway < Gateway
      self.supported_cardtypes = %i[master visa]

      # ==== Options
      # * <tt>:secretkey</tt>   -- The Buckaroo Secret Key (REQUIRED)
      # * <tt>:websitekey</tt>  -- The Buckaroo Websitekey (REQUIRED)
      def initialize(options={})
        requires!(options, :secretkey, :websitekey)
        @options = options
        super
      end

      # ==== Options
      # * <tt>:culture</tt>         -- The language for the web interface, choices: DE, EN, NL.
      #                                Default: EN (OPTIONAL)
      # * <tt>:curreny</tt>         -- The currency for the transaction, choices: EUR, GBP, USD.
      #                                Default: EUR (OPTIONAL)
      # * <tt>:description</tt>     -- The description for the transaction (REQUIRED)
      # * <tt>:invoicenumber</tt>   -- The invoicenumber for the transaction (REQUIRED)
      # * <tt>:payment_method</tt>  -- The payment method for the transaction, choices: mastercard
      #                                or visa (REQUIRED)
      # * <tt>:return</tt>          -- The return url for customer who paid or cancelled transaction
      #                                (OPTIONAL)
      # * <tt>:startrecurring</tt>  -- Should Buckaroo store the credit card information for future
      #                                use? Default: false (OPTIONAL)
      def purchase(money, _, options={})
        requires!(options, :description, :invoicenumber, :payment_method)
        buckaroo_validate(money, options, false)

        post_params = buckaroo_post_params_base(money, options)
        post_params[:brq_culture] = options[:culture] || "EN"

        case options[:payment_method]
        when "mastercard" then post_params[:brq_service_mastercard_action] = "Pay"
        when "visa" then post_params[:brq_service_visa_action] = "Pay"
        else raise ArgumentError, "payment_method should be mastercard or visa"
        end

        BuckarooBPE3Toolbox.call("TransactionRequest", post_params, @options[:secretkey], true)
      end

      # ==== Options same as purchase method above plus the following
      # * <tt>:originaltransaction</tt> -- The unique key of the original transaction (REQUIRED)
      def recurring(money, _, options={})
        requires!(options, :description, :invoicenumber, :originaltransaction, :payment_method)
        buckaroo_validate(money, options, true)

        post_params = buckaroo_post_params_base(money, options)
        post_params[:brq_originaltransaction] = options[:originaltransaction]

        case options[:payment_method]
        when "mastercard" then post_params[:brq_service_mastercard_action] = "PayRecurrent"
        when "visa" then post_params[:brq_service_visa_action] = "PayRecurrent"
        else raise ArgumentError, "payment_method should be mastercard or visa"
        end

        BuckarooBPE3Toolbox.call("TransactionRequest", post_params, @options[:secretkey], false)
      end

      private

      def buckaroo_validate(money, options, recurring)
        raise ArgumentError, "money should be more than 0" if money <= 0
        raise ArgumentError, "culture should be DE, EN or NL" if !recurring && options[:culture] && !%w[DE EN NL].include?(options[:culture])
        raise ArgumentError, "currency should be EUR, GBP or USD" if options[:currency] && !%w[EUR GBP USD].include?(options[:currency])
        raise ArgumentError, "description should be max 40 chars long" if options[:description].size > 40
        raise ArgumentError, "invoicenumber should be max 40 chars long" if options[:invoicenumber].size > 40
      end

      def buckaroo_post_params_base(money, options)
        post_params = {
          brq_amount: money,
          brq_currency: options[:currency] || "EUR",
          brq_description: options[:description],
          brq_invoicenumber: options[:invoicenumber],
          brq_payment_method: options[:payment_method],
          brq_startrecurrent: options[:startrecurring] ? "true" : "false",
          brq_websitekey: @options[:websitekey]
        }
        post_params[:brq_return] = options[:return] if options[:return]
        post_params
      end
    end
  end
end
