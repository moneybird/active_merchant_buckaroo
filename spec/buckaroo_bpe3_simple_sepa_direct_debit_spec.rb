
require "spec_helper.rb"

describe "Buckaroo Simple SEPA Direct Debit implementation for ActiveMerchant" do
  
  it "should create a new billing gateway with a required merchantid and secretkey" do
    ActiveMerchant::Billing::BuckarooBPE3SimpleSepaDirectDebitGateway.new(:secretkey => "1234", :websitekey => "1234").should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3SimpleSepaDirectDebitGateway)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3SimpleSepaDirectDebitGateway.new(:secretkey => "1234")
    }.should raise_error(ArgumentError)
  end
  
  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3SimpleSepaDirectDebitGateway.new(:websitekey => "1234")
    }.should raise_error(ArgumentError)
  end

  context "setup purchase" do
    
    before do
      @secretkey  = "secretkey"
      @websitekey = "websitekey"
      @gateway    = ActiveMerchant::Billing::BuckarooBPE3SimpleSepaDirectDebitGateway.new(:secretkey => @secretkey, :websitekey => @websitekey)
      
      @amount               = 1.23
      @collectdate          = Date.today
      @customeraccountname  = "Berend"
      @customerbic          = "INGBNL2A"
      @customeriban         = "NL20INGB0001234567"
      @description          = "Description"
      @invoicenumber        = "2013-0001"
      @mandatedate          = Date.today
      @mandatereference     = "000-TEST-000001"

      @params = {
        collectdate: @collectdate,
        customeraccountname: @customeraccountname,
        customerbic: @customerbic,
        customeriban: @customeriban,
        description: @description,
        invoicenumber: @invoicenumber,
        mandatedate: @mandatedate,
        mandatereference: @mandatereference
      }
    end
    
    context "ArgumentErrors" do

      it "should have no ArumentErrors with default params" do
        lambda {
          @gateway.purchase(@amount, nil, @params) 
        }.should_not raise_error(ArgumentError)
      end

      it "should raise an ArumentError when money is <= 0" do
        @amount = -1

        lambda {
          @gateway.purchase(@amount, nil, @params) 
        }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when collectdate is not a date" do
        @params[:collectdate] = "2013-12-16"

        lambda {
          @gateway.purchase(@amount, nil, @params) 
        }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of customeraccountname is more than 40" do
        @params[:customeraccountname] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.purchase(@amount, nil, @params) 
        }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when mandatedate is not a date" do
        @params[:mandatedate] = "2013-12-16"

        lambda {
          @gateway.purchase(@amount, nil, @params) 
        }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of description is more than 40" do
        @params[:description] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.purchase(@amount, nil, @params) 
        }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of invoicenumber is more than 40" do
        @params[:invoicenumber] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.purchase(@amount, nil, @params) 
        }.should raise_error(ArgumentError)
      end

    end
    
    it "should create a new purchase via the Buckaroo API" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_AMOUNT=1.23&BRQ_APIRESULT=Pending&BRQ_CURRENCY=EUR&BRQ_CUSTOMER_NAME=Berend&BRQ_INVOICENUMBER=2013-0001&BRQ_PAYMENT=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_PAYMENT_METHOD=SimpleSepaDirectDebit&BRQ_SERVICE_SIMPLESEPADIRECTDEBIT_COLLECTDATE=12%2f23%2f2013&BRQ_SERVICE_SIMPLESEPADIRECTDEBIT_CUSTOMERBIC=INGBNL2A&BRQ_SERVICE_SIMPLESEPADIRECTDEBIT_CUSTOMERIBAN=NL20INGB0001234567&BRQ_SERVICE_SIMPLESEPADIRECTDEBIT_MANDATEDATE=12%2f11%2f2013&BRQ_SERVICE_SIMPLESEPADIRECTDEBIT_MANDATEREFERENCE=000-TEST-000001&BRQ_STARTRECURRENT=True&BRQ_STATUSCODE=791&BRQ_STATUSCODE_DETAIL=C620&BRQ_STATUSMESSAGE=Awaiting+transfer+to+bank.&BRQ_TEST=false&BRQ_TIMESTAMP=2013-12-11+11%3a42%3a14&BRQ_TRANSACTIONS=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_WEBSITEKEY=XXXX&BRQ_SIGNATURE=05cd175951b40c221273fd6de516cdae15b02c53')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, @params)
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should_not == ""
      @response.success?.should be_true
      @response.test?.should be_false
      @response.statuscode.should == "791"
      @response.amount.should == @amount.to_s
      @response.invoicenumber.should == @invoicenumber

      @response.post_params.should_not be_nil
      @response.post_params[:brq_amount].should == @amount
      @response.post_params[:brq_description].should == @description
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
      @response.post_params[:brq_payment_method].should == "simplesepadirectdebit"
      @response.post_params[:brq_service_simplesepadirectdebit_customeraccountname].should == @customeraccountname
      @response.post_params[:brq_service_simplesepadirectdebit_customerbic].should == @customerbic
      @response.post_params[:brq_service_simplesepadirectdebit_customeriban].should == @customeriban
    end

    it "should handle an error with wrong IBAN number the right way" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_AMOUNT=1.23&BRQ_APIERRORMESSAGE=Parameter+%22CustomerIBAN%22+has+wrong+value&BRQ_CURRENCY=EUR&BRQ_INVOICENUMBER=2013-0001&BRQ_MUTATIONTYPE=NotSet&BRQ_STATUSCODE=491&BRQ_STATUSMESSAGE=Validation+failure&BRQ_TEST=false&BRQ_TIMESTAMP=2013-12-11+13%3a33%3a26&BRQ_TRANSACTIONS=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_WEBSITEKEY=XXXX&BRQ_SIGNATURE=2a99f87909ce3418a770c9964b16975e73ca84d3')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, @params)
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should_not == ""
      @response.success?.should be_false
      @response.test?.should be_false
      @response.statuscode.should == "491"
      @response.amount.should == @amount.to_s
      @response.invoicenumber.should == @invoicenumber

      @response.response_params.should_not be_nil
      @response.response_params["brq_apierrormessage"].should == 'Parameter "CustomerIBAN" has wrong value'
    end

    it "should still work with empty response" do

      http_mock = mock(Net::HTTP)      
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return("")
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, @params)
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should be_false
      @response.statuscode.should be_nil
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
      
      @response = @gateway.purchase(@amount, nil, @params)
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should be_false
      @response.statuscode.should be_nil
      @response.response_data.should == "this is a very nasty response"
    end
  end
end
