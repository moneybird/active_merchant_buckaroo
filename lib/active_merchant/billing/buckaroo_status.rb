require 'nokogiri'

module ActiveMerchant
  module Billing
    class BuckarooStatusGateway < Gateway
      
      URL = "https://payment.buckaroo.nl/soap/soap.asmx"
      
      def self.success_status_codes
        # 100 = Credit card success
        # 301 = Bank transfer success
        # 601 = Direct debit success
        ["100","301","601"]
      end
      
      # ==== Options
      # * <tt>:merchantid</tt> -- The Buckaroo Merchant ID (REQUIRED)
      # * <tt>:soapkey</tt>  -- The Buckaroo Soap Key (REQUIRED)
      def initialize(options = {})
        requires!(options, :merchantid, :soapkey)
        @options = options
        @options[:soapkey_fingerprint] = Digest::MD5.hexdigest(options[:soapkey])
        super
      end

      def status_for_invoice_id(invoice_id)
        
        # Calculate signature
        calculatemethod = "199"
        digestmethod = "SHA-2"
        argforsignature = sprintf("%s%s", @options[:merchantid], @options[:soapkey])
        signaturevalue = Digest::SHA2.hexdigest(argforsignature)

        # Build XML
        xml  = sprintf("<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n")
        xml += sprintf("<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\r\n")
        xml += sprintf("  <soap:Body>\r\n")
        xml += sprintf("    <StatusRequest xmlns=\"https://payment.buckaroo.nl/\">\r\n")
        xml += sprintf("      <XMLMessage>\r\n")
        xml += sprintf("        <Payload VersionID=\"1.0\" xmlns=\"\">\r\n")
        xml += sprintf("          <Control Language=\"NL\">\r\n")
        xml += sprintf("            <Timestamp>%s</Timestamp>\r\n", Time.now.strftime("%Y-%m-%d %H:%M:%S"))
        xml += sprintf("            <MerchantID>%s</MerchantID>\r\n", @options[:merchantid])
        xml += sprintf("          </Control>\r\n")
        xml += sprintf("          <Content>\r\n")
        xml += sprintf("            <Invoice>%s</Invoice>\r\n", invoice_id)
        xml += sprintf("          </Content>\r\n")
        xml += sprintf("        </Payload>\r\n")
        xml += sprintf("      </XMLMessage>\r\n")
        xml += sprintf("      <XMLSignature>\r\n")
        xml += sprintf("        <Signature xmlns=\"\">\r\n")
        xml += sprintf("          <Fingerprint>%s</Fingerprint>\r\n", @options[:soapkey_fingerprint])
        xml += sprintf("          <DigestMethod>%s</DigestMethod>\r\n", digestmethod)
        xml += sprintf("          <CalculateMethod>%s</CalculateMethod>\r\n", calculatemethod)
        xml += sprintf("          <SignatureValue>%s</SignatureValue>\r\n", signaturevalue)
        xml += sprintf("        </Signature>\r\n")
        xml += sprintf("      </XMLSignature>\r\n")
        xml += sprintf("    </StatusRequest>\r\n")    
        xml += sprintf("  </soap:Body>\r\n")
        xml += sprintf("</soap:Envelope>\r\n")

        response = commit(xml)
        
        doc = Nokogiri.XML(response)
        status = doc.at('Status').inner_text
        message = doc.at('AdditionalMessage').inner_text
        if BuckarooStatusGateway.success_status_codes.include?(status)
          return ActiveMerchant::Billing::BuckarooStatusResponse.new(true, message, { :status => status, :xml_received => response, :xml_sent => xml })
        else
          return ActiveMerchant::Billing::BuckarooStatusResponse.new(false, message, { :status => status, :xml_received => response, :xml_sent => xml })
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
