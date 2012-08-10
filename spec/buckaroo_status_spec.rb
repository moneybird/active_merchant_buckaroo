require "spec_helper.rb"

describe "Buckaroo Status implementation for ActiveMerchant" do
  
  it "should create a new billing gateway with a required merchantid and secretkey" do
    ActiveMerchant::Billing::BuckarooStatusGateway.new(:merchantid => "1234", :soapkey => "1234").should be_kind_of(ActiveMerchant::Billing::BuckarooStatusGateway)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooStatusGateway.new(:merchantid => "1234")
    }.should raise_error(ArgumentError)
  end
  
  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooStatusGateway.new(:soapkey => "1234")
    }.should raise_error(ArgumentError)
  end
  
  it "should have these success status codes" do
    ActiveMerchant::Billing::BuckarooStatusGateway.success_status_codes.should == ["100","301","601"]
  end
  
  context "status" do
    
    before do
      @merchantid = "merchantid"
      @soapkey    = "soapkey"
      @gateway    = ActiveMerchant::Billing::BuckarooStatusGateway.new(:merchantid => @merchantid, :soapkey => @soapkey)
      
      @invoice_id = "2012-0001"
    end
    
    it "should create a new purchase via the Buckaroo API" do

      http_mock = mock(Net::HTTP)      
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("payment.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('<?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
          <soap:Body>
            <StatusRequestResponse xmlns="https://payment.buckaroo.nl/">
              <XMLMessage>
                <Payload xmlns="" VersionID="1.0">
                  <Control Language="NL">
                    <SenderSessionID/>
                    <Timestamp>2012-08-10 10:08:20</Timestamp>
                    <MerchantID>merchantid</MerchantID>
                  </Control>
                  <Content>
                    <Invoice Test="FALSE">
                      <Key>key</Key>
                      <InvoiceNumber>2012-0001</InvoiceNumber>
                      <Amount>1190</Amount>
                      <Reference/>
                      <Status>601</Status>
                      <StatusDateTime>2012-05-03 08:58:30</StatusDateTime>
                      <StatusDescription>ok</StatusDescription>
                      <AdditionalMessage>Eenmalige machtiging is met succes verwerkt.</AdditionalMessage>
                    </Invoice>
                  </Content>
                </Payload>
              </XMLMessage>
              <XMLSignature>
                <Signature xmlns="">
                  <Fingerprint>fingerprint</Fingerprint>
                  <DigestMethod>SHA-2</DigestMethod>
                  <CalculateMethod>199</CalculateMethod>
                  <SignatureValue>signaturevalue</SignatureValue>
                </Signature>
              </XMLSignature>
            </StatusRequestResponse>
          </soap:Body>
        </soap:Envelope>
      ')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.status_for_invoice_id(@invoice_id)
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooStatusResponse)
      @response.success?.should == true
      @response.status.should == "601"
      @response.message.should == "Eenmalige machtiging is met succes verwerkt."
      
      doc1 = Nokogiri.XML(@response.xml_sent)
      #puts doc1.to_xml
      doc1.at('Payload/Control/MerchantID').inner_text.should == @merchantid
      doc1.at('Payload/Content/Invoice').inner_text.should == @invoice_id
      
      doc2 = Nokogiri.XML(@response.xml_received)
      #puts doc2.to_xml
      doc2.at('Payload/Control/MerchantID').inner_text.should == @merchantid
      doc2.at('Payload/Content/Invoice/InvoiceNumber').inner_text.should == @invoice_id
      doc2.at('Payload/Content/Invoice/Status').inner_text.should == "601"
      doc2.at('Payload/Content/Invoice/AdditionalMessage').inner_text.should == "Eenmalige machtiging is met succes verwerkt."
    end
  end
end
