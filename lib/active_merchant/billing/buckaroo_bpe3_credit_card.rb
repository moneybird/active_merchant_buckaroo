module ActiveMerchant
  module Billing
    class BuckarooBPE3CreditCardGateway < Gateway
      
      self.supported_cardtypes = [:master, :visa]
      
      # ==== Options
      # * <tt>:secretkey</tt>   -- The Buckaroo Secret Key (REQUIRED)
      # * <tt>:websitekey</tt>  -- The Buckaroo Websitekey (REQUIRED)
      def initialize(options = {})
        requires!(options, :secretkey, :websitekey)
        @options = options
        @options[:url] = ActiveMerchant::Billing::Base.test? ? "https://testcheckout.buckaroo.nl/nvp/" : "https://checkout.buckaroo.nl/nvp/"
        @options[:url] += "?op=TransactionRequest"
        super
      end

      # ==== Options
      # * <tt>:culture</tt>         -- The language for the web interface, choices: DE, EN, NL. Default: EN (OPTIONAL)
      # * <tt>:curreny</tt>         -- The currency for the transaction, choices: EUR, GBP, USD. Default: EUR (OPTIONAL)
      # * <tt>:description</tt>     -- The description for the transaction (REQUIRED)
      # * <tt>:invoicenumber</tt>   -- The invoicenumber for the transaction (REQUIRED)
      # * <tt>:payment_method</tt>  -- The payment method for the transaction, choices: mastercard or visa (REQUIRED)
      # * <tt>:return</tt>          -- The return url for customer who paid or cancelled transaction (OPTIONAL)
      # * <tt>:startrecurring</tt>  -- Should Buckaroo store the credit card information for future use? Default: false (OPTIONAL)
      def purchase(money, creditcard, options = {})
        requires!(options, :description, :invoicenumber, :payment_method)

        raise ArgumentError.new("money should be more than 0") if money <= 0
        
        raise ArgumentError.new("culture should be DE, EN or NL") if options[:culture] and ![ "DE", "EN", "NL" ].include?(options[:culture])
        raise ArgumentError.new("currency should be EUR, GBP or USD") if options[:currency] and ![ "EUR", "GBP", "USD" ].include?(options[:currency])
        raise ArgumentError.new("description should be max 40 chars long") if options[:description].size > 40
        raise ArgumentError.new("invoicenumber should be max 40 chars long") if options[:invoicenumber].size > 40
        raise ArgumentError.new("payment_method should be mastercard or visa") if options[:payment_method].blank? or ![ "mastercard", "visa" ].include?(options[:payment_method])

        post_params = {
          brq_amount: money,
          brq_culture: options[:culture] ? options[:culture] : "EN",
          brq_currency: options[:currency] ? options[:currency] : "EUR",
          brq_description: options[:description],
          brq_invoicenumber: options[:invoicenumber],
          brq_payment_method: options[:payment_method],
          brq_startrecurrent: options[:startrecurring] ? "true" : "false",
          brq_websitekey: @options[:websitekey]
        }
        post_params[:brq_return] = options[:return] if options[:return]
        post_params[:brq_service_mastercard_action] = "Pay" if options[:payment_method] == "mastercard"
        post_params[:brq_service_visa_action]       = "Pay" if options[:payment_method] == "visa"

        brq_signature = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(post_params, @options[:secretkey])
        post_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_post_data(post_params, brq_signature)

        response_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.commit(@options[:url], post_data)
        response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(response_data, @options[:secretkey])
        return_params = { 
          post_data: post_data,
          post_params: post_params,
          response_parser: response_parser,
        }

        if response_parser.valid?
          success = response_parser.pending?
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(success, response_parser.statusmessage, return_params)
        else
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(false, "Invalid response", return_params)
        end

      end

      # ==== Options same as purchase method above plus the following
      # * <tt>:originaltransaction</tt> -- The unique key of the original transaction (REQUIRED)
      def recurring(money, creditcard, options = {})
        requires!(options, :description, :invoicenumber, :originaltransaction, :payment_method)

        raise ArgumentError.new("money should be more than 0") if money <= 0

        raise ArgumentError.new("currency should be EUR, GBP or USD") if options[:currency] and ![ "EUR", "GBP", "USD" ].include?(options[:currency])
        raise ArgumentError.new("description should be max 40 chars long") if options[:description].size > 40
        raise ArgumentError.new("invoicenumber should be max 40 chars long") if options[:invoicenumber].size > 40
        raise ArgumentError.new("payment_method should be mastercard or visa") if options[:payment_method].blank? or ![ "mastercard", "visa" ].include?(options[:payment_method])

        post_params = {
          brq_amount: money,
          brq_currency: options[:currency] ? options[:currency] : "EUR",
          brq_description: options[:description],
          brq_invoicenumber: options[:invoicenumber],
          brq_originaltransaction: options[:originaltransaction],
          brq_payment_method: options[:payment_method],
          brq_websitekey: @options[:websitekey]
        }
        post_params[:brq_return] = options[:return] if options[:return]
        post_params[:brq_service_mastercard_action] = "PayRecurrent" if options[:payment_method] == "mastercard"
        post_params[:brq_service_visa_action]       = "PayRecurrent" if options[:payment_method] == "visa"

        brq_signature = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(post_params, @options[:secretkey])
        post_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_post_data(post_params, brq_signature)

        response_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.commit(@options[:url], post_data)
        response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(response_data, @options[:secretkey])
        return_params = { 
          post_data: post_data,
          post_params: post_params,
          response_parser: response_parser,
        }

        if response_parser.valid?
          success = response_parser.success?
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(success, response_parser.statusmessage, return_params)
        else
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(false, "Invalid response", return_params)
        end

      end

    end

  end

end
