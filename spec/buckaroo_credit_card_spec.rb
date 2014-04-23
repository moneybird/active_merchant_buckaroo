require "spec_helper.rb"

describe "Buckaroo Credit Card implementation for ActiveMerchant" do

  it "should create a new billing gateway with a required merchantid and secretkey" do
    ActiveMerchant::Billing::BuckarooCreditCardGateway.new(:merchantid => "1234", :secretkey => "1234").should be_kind_of(ActiveMerchant::Billing::BuckarooCreditCardGateway)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooCreditCardGateway.new(:merchantid => "1234")
    }.should raise_error(ArgumentError)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooCreditCardGateway.new(:secretkey => "1234")
    }.should raise_error(ArgumentError)
  end

  context "setup recurring" do

    before do
      @merchantid   = "merchantid"
      @secretkey    = "secretkey"
      @gateway      = ActiveMerchant::Billing::BuckarooCreditCardGateway.new(:merchantid => @merchantid, :secretkey => @secretkey)

      @amount       = 1000
      @batchid      = "1"
      @customerid   = "company_1"
      @description  = "Description"
      @invoice      = "2012-0001"
      @responseurl  = "http://www.example.com/buckaroo/return"
    end

    it "should create a new recurring via the Buckaroo API" do
      http_mock = double(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("payment.buckaroo.nl", 443).and_return(http_mock)

      response_mock = double(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('<?xml version="1.0"?>
        <PayMessage Channel="batch" VersionID="1.0">
          <Control Language="NL" Test="TRUE">
            <SenderSessionID>sendersessionid</SenderSessionID>
            <Date>2012-07-05</Date>
            <Time>16:01:17</Time>
            <MerchantID>merchantid</MerchantID>
            <BatchID>1</BatchID>
            <Signature>signature</Signature>
            <MessageID>BatchDeliveryResponse</MessageID>
          </Control>
          <Content>
            <BatchDelivery>
              <ResponseStatus>700</ResponseStatus>
              <ResponseStatusDescription>ok</ResponseStatusDescription>
              <AdditionalMessage>
                <Info>ok</Info>
                <BatchKey></BatchKey>
                <Schedule>
                  <Date>2012-07-05</Date>
                  <Time>16:02:17</Time>
                </Schedule>
                <ResponseURL>http://www.example.com/buckaroo/return</ResponseURL>
                <Transactions>1</Transactions>
                <Duration validation="estimate" unit="seconds">60</Duration>
                <ETR>
                  <Date>2012-07-05</Date>
                  <Time>17:02:17</Time>
                </ETR>
              </AdditionalMessage>
            </BatchDelivery>
         </Content>
      </PayMessage>')
      http_mock.should_receive(:post).and_return(response_mock)

      @response = @gateway.recurring(@amount, nil, {
        :batchid      => @batchid,
        :customerid   => @customerid,
        :description  => @description,
        :invoice      => @invoice,
        :responseurl  => @responseurl
      })

      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooCreditCardRecurringResponse)
      @response.success?.should == true

      doc1 = Nokogiri.XML(@response.xml_sent)
      doc1.search('/PayMessage/Content/Transaction/Amount').first.inner_text.should == @amount.to_s
      doc1.search('/PayMessage/Content/Transaction/CustomerID').first.inner_text.should == @customerid
      doc1.search('/PayMessage/Content/Transaction/Description').first.inner_text.should == @description
      doc1.search('/PayMessage/Content/Transaction/Invoice').first.inner_text.should == @invoice

      doc2 = Nokogiri.XML(@response.xml_received)
      doc2.search('/PayMessage/Content/BatchDelivery/AdditionalMessage/ResponseURL').first.inner_text.should == @responseurl
    end

    it "should still work with empty response" do
      http_mock = double(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("payment.buckaroo.nl", 443).and_return(http_mock)

      response_mock = double(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('')
      http_mock.should_receive(:post).and_return(response_mock)

      @response = @gateway.recurring(@amount, nil, {
        :batchid      => @batchid,
        :customerid   => @customerid,
        :description  => @description,
        :invoice      => @invoice,
        :responseurl  => @responseurl
      })

      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooCreditCardRecurringResponse)
      @response.success?.should == false
      @response.response_status.should == nil
      @response.xml_received.should == ""
    end
  end
end
