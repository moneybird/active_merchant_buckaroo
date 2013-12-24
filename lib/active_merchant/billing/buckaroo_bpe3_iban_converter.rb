module ActiveMerchant
  module Billing
    class BuckarooBPE3IbanConverterGateway < Gateway

      # ==== Options
      # * <tt>:secretkey</tt> -- The Buckaroo Secret Key (REQUIRED)
      # * <tt>:websitekey</tt> -- The Buckaroo Websitekey (REQUIRED)
      def initialize(options = {})
        requires!(options, :secretkey, :websitekey)
        @options = options
        @options[:read_timeout] ||= 4
        @options[:url] = ActiveMerchant::Billing::Base.test? ? "https://testcheckout.buckaroo.nl/nvp/" : "https://checkout.buckaroo.nl/nvp/"
        @options[:url] += "?op=IbanConverter"
        super
      end

      def bic_for_iban(options = {})
        requires!(options, :accountnumber, :countryisocode)

        accountnumber = options[:accountnumber]
        countryisocode = options[:countryisocode]

        raise ArgumentError.new("accountnumber must be in format NL00XXXX0123456789") if !accountnumber =~ /^NL[0-9]{2}[A-Z]{4}[0-9]{10}$/i
        raise ArgumentError.new("countryisocode must be NL") if !["NL"].include?(countryisocode)

        bank_name = accountnumber[4..7].upcase
        bic = case bank_name
        when "ABNA"
          "ABNANL2A"
        when "ASNB"
          "ASNBNL21"
        when "FRBK"
          "FRBKNL2L"
        when "FVLB"
          "FVLBNL22"
        when "INGB"
          "INGBNL2A"
        when "RABO"
          "RABONL2U"
        when "RBRB"
          "RBRBNL21"
        when "SNSB"
          "SNSBNL2A"
        when "TRIO"
          "TRIONL2U"
        else
          ""
        end

        if bic.blank?
          resp = convert_to_iban({ accountnumber: accountnumber[8..-1], countryisocode: countryisocode })
          if resp.success?
            bic = resp.bic
          else
            raise "bic_for_iban: convertion to bic failed"
          end
        end

        bic
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
          brq_channel: "CALLCENTER",
          brq_countryisocode: countryisocode,
          brq_websitekey: @options[:websitekey]
        }
        post_params[:brq_bankcode] = bankcode if bankcode

        brq_signature = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(post_params, @options[:secretkey])
        post_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_post_data(post_params, brq_signature)

        response_data = ActiveMerchant::Billing::BuckarooBPE3Toolbox.commit(@options[:url], post_data, @options[:read_timeout])
        response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(response_data, @options[:secretkey])
        return_params = { 
          post_data: post_data,
          post_params: post_params,
          response_parser: response_parser,
        }

        if response_parser.valid?
          success = response_parser.apiresult_success?
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(success, response_parser.statusmessage, return_params)
        else
          return ActiveMerchant::Billing::BuckarooBPE3Response.new(false, "Invalid response", return_params)
        end

      end

    end

  end

end
