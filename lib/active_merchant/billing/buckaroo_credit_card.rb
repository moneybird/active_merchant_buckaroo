require 'nokogiri'

module ActiveMerchant
  module Billing
    class BuckarooCreditCardGateway < Gateway
      
      self.money_format = :cents
      self.supported_cardtypes = [:master, :visa]
      URL = "https://payment.buckaroo.nl/batch/batch_delivery.asp"
      
      # ==== Options
      # * <tt>:merchantid</tt> -- The Buckaroo Merchant ID (REQUIRED)
      # * <tt>:secretkey</tt>  -- The Buckaroo Secret Key (REQUIRED)
      def initialize(options = {})
        requires!(options, :merchantid, :secretkey)
        @options = options
        super
      end
      
      # ==== Parameters
      # * <tt>money</tt>      -- The amount to be purchased. Integer value in cents
      # * <tt>creditcard</tt> -- The CreditCard details for the transaction, should be nil
      # * <tt>options</tt>    -- A hash of optional parameters.
      # ==== Options
      # * <tt>:batchid</tt>     -- Batch ID (REQUIRED)
      # * <tt>:customerid</tt>  -- Customer ID (unique) for Buckaroo to fetch CreditCard info (REQUIRED)
      # * <tt>:description</tt> -- Discription for invoice (REQUIRED)
      # * <tt>:invoice</tt>     -- Invoice number (REQUIRED)
      # * <tt>:notify</tt>      -- E-mail adddress for notification when batch is processed (OPTIONAL)
      # * <tt>:responseurl</tt> -- The URL for the Buckaroo push (REQUIRED)
      def recurring(money, creditcard, options = {})
        requires!(options, :batchid, :customerid, :description, :invoice, :responseurl)

        signaturetmp = sprintf("%s%s%s", @options[:merchantid], options[:batchid], @options[:secretkey])
        signature = Digest::MD5.hexdigest(signaturetmp)
        test = ActiveMerchant::Billing::Base.test?

        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.PayMessage("Channel" => "batch", "VersionID" => "1.0") {
            xml.Control("Language" => "NL", "Test" => test ? "TRUE" : "FALSE") {
              xml.BatchID options[:batchid]
              xml.Date Time.now.strftime("%Y-%m-%d")
              xml.MerchantID @options[:merchantid]
              xml.MessageID "BatchDeliveryRequest"
              xml.Notify options[:notify]
              if options[:responseurl]
                if options[:responseurl][0..4] == "https"
                  xml.ResponseURL options[:responseurl], { "SSL" => options[:responseurl] }
                else
                  xml.ResponseURL options[:responseurl]
                end
              end
              xml.SenderSessionID "sendersessionid"
              xml.Signature signature
              xml.Time Time.now.strftime("%H:%M:%S")
            }
            xml.Content {
              xml.Transaction {
                xml.Amount money, { "Currency" => "EUR" }
                xml.CustomerID options[:customerid]
                xml.Description options[:description]
                xml.Invoice options[:invoice]
              }
            }
          }
        end
        xml = builder.to_xml
        
        # Do call to remote webserver
        response = commit(xml)
        
        # Process response
        doc = Nokogiri.XML(response)
        response_status = doc.at('/PayMessage/Content/BatchDelivery/ResponseStatus').inner_text
        message = doc.at('/PayMessage/Content/BatchDelivery/AdditionalMessage').inner_text
        if response_status == "700"
          return ActiveMerchant::Billing::BuckarooCreditCardRecurringResponse.new(true, "", { :xml_received => response, :xml_sent => xml })
        else
          return ActiveMerchant::Billing::BuckarooCreditCardRecurringResponse.new(false, message, { :xml_received => response, :xml_sent => xml })
        end
      end
      
      def commit(xml)
        uri   = URI.parse(URL)
        http  = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ActiveMerchant::Billing::Base.test?
        http.post(uri.request_uri, xml).body
      end
    end
  end
end
