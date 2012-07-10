require "spec_helper.rb"

describe "Buckaroo Direct Debit implementation for ActiveMerchant" do
  
  it "should create a new billing gateway with a required merchantid and secretkey" do
    ActiveMerchant::Billing::BuckarooDirectDebitGateway.new(:merchantid => "1234", :soapkey => "1234").should be_kind_of(ActiveMerchant::Billing::BuckarooDirectDebitGateway)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooDirectDebitGateway.new(:merchantid => "1234")
    }.should raise_error(ArgumentError)
  end
  
  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooDirectDebitGateway.new(:soapkey => "1234")
    }.should raise_error(ArgumentError)
  end
  
  context "setup purchase" do
    
    before do
      @merchantid = "merchantid"
      @soapkey    = "soapkey"
      @gateway    = ActiveMerchant::Billing::BuckarooDirectDebitGateway.new(:merchantid => @merchantid, :soapkey => @soapkey)
      
      @accountname    = "Berend Botje"
      @accountnumber  = "1234567"
      @amount         = 1000
      @description    = "Description"
      @email          = "info@example.com"
      @firstname      = "Berend"
      @invoice        = "2012-0001"
      @lastname       = "Botje"
      @reference      = "noref"
    end
    
    it "should create a new purchase via the Buckaroo API" do

      http_mock = mock(Net::HTTP)      
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("payment.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('<?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
          <soap:Body>
            <EenmaligeMachtigingResponse xmlns="https://payment.buckaroo.nl/">
              <XMLMessage>
                <Payload VersionID="1.0" xmlns="">
                  <Control Language="NL" Test="True">
                    <SenderSessionID></SenderSessionID>
                    <Timestamp>2012-07-10 11:58:32</Timestamp>
                    <MerchantID>merchantid</MerchantID>
                  </Control>
                  <Content>
                    <Transaction Id="">
                      <TransactionKey>transactionkey</TransactionKey>
                      <Amount Currency="EUR">1000</Amount>
                      <Invoice>2012-0001</Invoice>
                      <CollectDate>2012-07-10</CollectDate>
                      <Reference>noref</Reference>
                      <Description>Description</Description>
                      <ResponseStatus>600</ResponseStatus>
                      <ResponseStatusDescription>ok</ResponseStatusDescription>
                      <AdditionalMessage>Eenmalige machtiging is nog niet verwerkt.</AdditionalMessage>
                    </Transaction>
                  </Content>
                </Payload>
              </XMLMessage>
              <XMLSignature>
                <Signature xmlns="">
                  <Fingerprint>fingerprint</Fingerprint>
                  <DigestMethod>SHA-2</DigestMethod>
                  <CalculateMethod>111</CalculateMethod>
                  <SignatureValue>signaturevalue</SignatureValue>
                </Signature>
              </XMLSignature>
            </EenmaligeMachtigingResponse>
          </soap:Body>
        </soap:Envelope>')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, {
        :accountname    => @accountname,
        :accountnumber  => @accountnumber,
        :description    => @description,
        :email          => @email,
        :firstname      => @firstname,
        :invoice        => @invoice,
        :lastname       => @lastname,
        :reference      => @reference
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooDirectDebitPurchaseResponse)
      @response.success?.should == true
      @response.response_status.should == "600"
      
      doc1 = Nokogiri.XML(@response.xml_sent)
      #puts doc1.to_xml
      doc1.at('Payload/Control/MerchantID').inner_text.should == @merchantid
      doc1.at('Payload/Content/Transaction/Customer/Firstname').inner_text.should == @firstname
      doc1.at('Payload/Content/Transaction/Customer/Gender').inner_text.should == "9"
      doc1.at('Payload/Content/Transaction/Customer/Lastname').inner_text.should == @lastname
      doc1.at('Payload/Content/Transaction/Customer/Mail').inner_text.should == @email
      doc1.at('Payload/Content/Transaction/AccountName').inner_text.should == @accountname
      doc1.at('Payload/Content/Transaction/AccountNumber').inner_text.should == @accountnumber
      doc1.at('Payload/Content/Transaction/Amount').inner_text.should == @amount.to_s
      doc1.at('Payload/Content/Transaction/Description').inner_text.should == @description
      doc1.at('Payload/Content/Transaction/Invoice').inner_text.should == @invoice
      doc1.at('Payload/Content/Transaction/Reference').inner_text.should == @reference
      
      doc2 = Nokogiri.XML(@response.xml_received)
      #puts doc2.to_xml
      doc2.at('Payload/Control/MerchantID').inner_text.should == @merchantid
      doc2.at('Payload/Content/Transaction/Amount').inner_text.should == @amount.to_s
      doc2.at('Payload/Content/Transaction/Description').inner_text.should == @description
      doc2.at('Payload/Content/Transaction/Invoice').inner_text.should == @invoice
      doc2.at('Payload/Content/Transaction/Reference').inner_text.should == @reference
      doc2.at('Payload/Content/Transaction/ResponseStatus').inner_text.should == "600"
      doc2.at('Payload/Content/Transaction/TransactionKey').inner_text.should == "transactionkey"
    end
  end
end
