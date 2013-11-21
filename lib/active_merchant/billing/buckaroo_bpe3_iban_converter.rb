module ActiveMerchant
  module Billing
    class BuckarooBPE3IbanConverterGateway < Gateway

      # ==== Options
      # * <tt>:secretkey</tt> -- The Buckaroo Secret Key (REQUIRED)
      # * <tt>:websitekey</tt> -- The Buckaroo Websitekey (REQUIRED)
      def initialize(options = {})
        requires!(options, :secretkey, :websitekey)
        @options = options
        @options[:url] = ActiveMerchant::Billing::Base.test? ? "https://testcheckout.buckaroo.nl/nvp/" : "https://checkout.buckaroo.nl/nvp/"
        @options[:url] += "?op=IbanConverter"
        super
      end

      # ==== Options
      # * <tt>:accountnumber</tt>   -- The account number of the bank account
      # * <tt>:bankcode</tt>        -- Bank code, only required when countryisocode == "DE"
      # * <tt>:countryisocode</tt>  -- Country iso code, for example: "BE", "DE", "FR", "NL"
      def convert_to_iban(options = {})
        requires!(options, :accountnumber, :countryisocode)

        accountnumber   = options[:accountnumber]
        bankcode        = options[:bankcode]
        countryisocode  = options[:countryisocode].upcase

        raise ArgumentError.new("countryisocode must be BE, DE, FR or NL") if !["BE", "DE", "FR", "NL"].include?(countryisocode)
        raise ArgumentError.new("bankcode option must be provided when countryisocode is DE") if countryisocode == "DE" and bankcode.blank?

        post_params = {
          brq_accountnumber: accountnumber,
          brq_countryisocode: countryisocode,
          brq_websitekey: @options[:websitekey]
        }
        post_params[:brq_bankcode] = bankcode if bankcode

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
