require "spec_helper.rb"

describe "Buckaroo Direct Debit implementation for ActiveMerchant" do
  
  it "should create a new billing gateway with a required merchantid and secretkey" do
    ActiveMerchant::Billing::BuckarooBPE3DirectDebitGateway.new(:secretkey => "1234", :websitekey => "1234").should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3DirectDebitGateway)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3DirectDebitGateway.new(:secretkey => "1234")
    }.should raise_error(ArgumentError)
  end
  
  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3DirectDebitGateway.new(:websitekey => "1234")
    }.should raise_error(ArgumentError)
  end

  context "setup purchase" do
    
    before do
      @secretkey  = "secretkey"
      @websitekey = "websitekey"
      @gateway    = ActiveMerchant::Billing::BuckarooBPE3DirectDebitGateway.new(:secretkey => @secretkey, :websitekey => @websitekey)
      
      @accountname    = "Berend Botje"
      @accountnumber  = "1234567"
      @amount         = 1.23
      @description    = "Description"
      @invoicenumber  = "2013-0001"
    end
    
    context "ArgumentErrors" do

      it "should raise an ArumentError when string length of accountname is more than 40" do
        @accountname = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.purchase(@amount, nil, {
          :accountname    => @accountname,
          :accountnumber  => @accountnumber,
          :description    => @description,
          :invoicenumber  => @invoicenumber,
          }) }.should raise_error(ArgumentError)
      end
    
      it "should raise an ArumentError when string length of accountnumber is more than 9" do
        @accountnumber = "1234567890"

        lambda {
          @gateway.purchase(@amount, nil, {
          :accountname    => @accountname,
          :accountnumber  => @accountnumber,
          :description    => @description,
          :invoicenumber  => @invoicenumber,
          }) }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of description is more than 40" do
        @description = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.purchase(@amount, nil, {
          :accountname    => @accountname,
          :accountnumber  => @accountnumber,
          :description    => @description,
          :invoicenumber  => @invoicenumber,
          }) }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of invoicenumber is more than 40" do
        @invoicenumber = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.purchase(@amount, nil, {
          :accountname    => @accountname,
          :accountnumber  => @accountnumber,
          :description    => @description,
          :invoicenumber  => @invoicenumber,
          }) }.should raise_error(ArgumentError)
      end
    
    end
    
    it "should create a new purchase via the Buckaroo API" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_AMOUNT=1.23&BRQ_APIRESULT=Pending&BRQ_CURRENCY=EUR&BRQ_INVOICENUMBER=2013-0001&BRQ_PAYMENT=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_PAYMENT_METHOD=directdebit&BRQ_STATUSCODE=791&BRQ_STATUSMESSAGE=Pending+processing&BRQ_TEST=false&BRQ_TIMESTAMP=2013-03-19+15%3a02%3a08&BRQ_TRANSACTIONS=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_SIGNATURE=dee5c83c666c9837051182d6d8866d2c1e5eb446')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, {
        :accountname    => @accountname,
        :accountnumber  => @accountnumber,
        :description    => @description,
        :invoicenumber  => @invoicenumber
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should_not == ""
      @response.success?.should == true
      @response.statuscode.should == "791"
      @response.amount.should == @amount.to_s
      @response.invoicenumber.should == @invoicenumber
      
      @response.post_params.should_not == nil
      @response.post_params[:brq_amount].should == @amount
      @response.post_params[:brq_description].should == @description
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
      @response.post_params[:brq_payment_method].should == "directdebit"
      @response.post_params[:brq_service_directdebit_customeraccountname].should == @accountname
      @response.post_params[:brq_service_directdebit_customeraccountnumber].should == @accountnumber
    end

    it "should create a new purchase via the Buckaroo API - recurring" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return("")
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, {
        :accountname    => @accountname,
        :accountnumber  => @accountnumber,
        :description    => @description,
        :invoicenumber  => @invoicenumber,
        :recurring      => true
      })

      @response.post_params.should_not == nil
      @response.post_params[:brq_amount].should == @amount
      @response.post_params[:brq_description].should == @description
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
      @response.post_params[:brq_payment_method].should == "directdebitrecurring"
      @response.post_params[:brq_service_directdebitrecurring_customeraccountname].should == @accountname
      @response.post_params[:brq_service_directdebitrecurring_customeraccountnumber].should == @accountnumber
    end

    it "should still work with empty response" do

      http_mock = mock(Net::HTTP)      
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return("")
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, {
        :accountname    => @accountname,
        :accountnumber  => @accountnumber,
        :description    => @description,
        :invoicenumber  => @invoicenumber,
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should == false
      @response.statuscode.should == nil
      @response.response_data.should == ""
    end

    it "should still work with crappy response" do

      http_mock = mock(Net::HTTP)      
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return("this is a very nasty response")
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, {
        :accountname    => @accountname,
        :accountnumber  => @accountnumber,
        :description    => @description,
        :invoicenumber  => @invoicenumber,
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should == false
      @response.statuscode.should == nil
      @response.response_data.should == "this is a very nasty response"
    end
  end
end
