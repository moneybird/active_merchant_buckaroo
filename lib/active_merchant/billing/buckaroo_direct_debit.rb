require 'nokogiri'

module ActiveMerchant
  module Billing
    class BuckarooDirectDebitGateway < Gateway
      
      URL = "https://payment.buckaroo.nl/soap/soap.asmx"
      
      # ==== Options
      # * <tt>:merchantid</tt> -- The Buckaroo Merchant ID (REQUIRED)
      # * <tt>:soapkey</tt>  -- The Buckaroo Soap Key (REQUIRED)
      def initialize(options = {})
        requires!(options, :merchantid, :soapkey)
        @options = options
        @options[:soapkey_fingerprint] = Digest::MD5.hexdigest(options[:soapkey])
        super
      end

      def purchase(money, creditcard, options = {})
        requires!(options, :accountname, :accountnumber, :description, :email, :firstname, :invoice, :lastname, :reference)
        
        test = ActiveMerchant::Billing::Base.test?
        buckarootest = test ? "TRUE" : "FALSE"
        collectdate = Time.now.strftime("%Y-%m-%d")
        currency = "EUR"
        digestmethod = "SHA-2"
        calculatemethod = "111"

        signaturetemp = sprintf("%s%s%s%s%s%s%s%d%s%s%s", @options[:merchantid], options[:accountnumber], options[:accountname], collectdate, options[:invoice], options[:reference], currency, money, options[:description], buckarootest, @options[:soapkey])
        signature = Digest::SHA2.hexdigest(signaturetemp)

        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.Envelope("xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance") {
            xml.parent.namespace = xml.parent.namespace_definitions.first
            xml['soap'].Body {
              xml.EenmaligeMachtiging("xmlns" => "https://payment.buckaroo.nl/") {
                xml.XMLMessage {
                  xml.Payload("VersionID" => "1.0", "xmlns" => "") {
                    xml.Control("Language" => "NL", "Test" => buckarootest) {
                      xml.MerchantID @options[:merchantid]
                      xml.Timestamp Time.now.strftime("%Y-%m-%d %H:%M:%S")
                    }
                    xml.Content {
                      xml.Transaction {
                        xml.Customer {
                          xml.Firstname options[:firstname]
                          xml.Gender "9"
                          xml.Lastname options[:lastname]
                          xml.Mail options[:email]
                        }
                        xml.AccountName options[:accountname]
                        xml.AccountNumber options[:accountnumber]
                        xml.Amount money, { "Currency" => currency }
                        xml.Description options[:description]
                        xml.CollectDate collectdate
                        xml.Invoice options[:invoice]
                        xml.Reference options[:reference]                        
                      }
                    }
                  }
                }
                xml.XMLSignature {
                  xml.Signature("xmlns" => "") {
                    xml.CalculateMethod calculatemethod
                    xml.DigestMethod digestmethod
                    xml.Fingerprint @options[:soapkey_fingerprint]
                    xml.SignatureValue signature
                  }
                }
              }
            }
          }
        end
        xml = builder.to_xml

        response = commit(xml)
        
        doc = Nokogiri.XML(response)
        response_status = doc.at('Payload/Content/Transaction/ResponseStatus').inner_text
        message = doc.at('Payload/Content/Transaction/AdditionalMessage').inner_text
        if response_status == "600"
          return ActiveMerchant::Billing::BuckarooDirectDebitPurchaseResponse.new(true, "", { :response_status => response_status, :xml_received => response, :xml_sent => xml })
        else
          return ActiveMerchant::Billing::BuckarooDirectDebitPurchaseResponse.new(false, message, { :response_status => response_status, :xml_received => response, :xml_sent => xml })
        end
      end

      def commit(xml)
        uri   = URI.parse(URL)
        http  = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ActiveMerchant::Billing::Base.test?
        http.post(uri.request_uri, xml, { 'Content-Type' => 'text/xml; charset=utf-8' }).body
      end
    end
  end
end
