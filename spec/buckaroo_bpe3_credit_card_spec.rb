require "spec_helper.rb"

describe "Buckaroo Credird Card implementation for ActiveMerchant" do
  
  it "should create a new billing gateway with a required merchantid and secretkey" do
    ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway.new( { secretkey: "1234", websitekey: "1234" } ).should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway.new( { secretkey: "1234" } )
    }.should raise_error(ArgumentError) 
  end
  
  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway.new( { websitekey: "1234" } )
    }.should raise_error(ArgumentError)
  end

  context "setup purchase" do
    
    before do
      @secretkey  = "secretkey"
      @websitekey = "websitekey"
      @gateway    = ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway.new( {
        secretkey:  @secretkey, 
        websitekey: @websitekey
      } )
      
      @amount         = 1.23
      @culture        = "EN"
      @currency       = "EUR"
      @description    = "Description"
      @invoicenumber  = "2013-0001"
      @payment_method = "mastercard"
      @return         = "http://localhost/returnurl"
    end
    
    context "ArgumentErrors" do

      it "should raise an ArumentError when culture is not DE, EN or NL" do
        @culture = "FR"

        lambda {
          @gateway.purchase(@amount, nil, {
            culture:        @culture,
            currency:       @currency,
            description:    @description,
            invoicenumber:  @invoicenumber,
            payment_method: @payment_method,
            return:         @return
          }) }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when currency is not EUR, GBP or USD" do
        @currency = "MYCURR"

        lambda {
          @gateway.purchase(@amount, nil, {
            culture:        @culture,
            currency:       @currency,
            description:    @description,
            invoicenumber:  @invoicenumber,
            payment_method: @payment_method,
            return:         @return
          }) }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of description is more than 40" do
        @description = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.purchase(@amount, nil, {
            culture:        @culture,
            currency:       @currency,
            description:    @description,
            invoicenumber:  @invoicenumber,
            payment_method: @payment_method,
            return:         @return
          }) }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of invoicenumber is more than 40" do
        @invoicenumber = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.purchase(@amount, nil, {
            culture:        @culture,
            currency:       @currency,
            description:    @description,
            invoicenumber:  @invoicenumber,
            payment_method: @payment_method,
            return:         @return
          }) }.should raise_error(ArgumentError)
      end
    
      it "should raise an ArumentError when string payment_method is not equal to mastercard or visa" do
        @payment_method = "myowncreditcard"

        lambda {
          @gateway.purchase(@amount, nil, {
            culture:        @culture,
            currency:       @currency,
            description:    @description,
            invoicenumber:  @invoicenumber,
            payment_method: @payment_method,
            return:         @return
          }) }.should raise_error(ArgumentError)
      end
    
    end

    it "should also work with visa cards" do

      @payment_method = "visa"

      @response = @gateway.purchase(@amount, nil, {
        culture:        @culture,
        currency:       @currency,
        description:    @description,
        invoicenumber:  @invoicenumber,
        payment_method: @payment_method,
        return:         @return
      })
      @response.post_params[:brq_payment_method].should == "visa"
    end
    
    it "should create a new purchase via the Buckaroo API" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_ACTIONREQUIRED=redirect&BRQ_AMOUNT=1.23&BRQ_APIRESULT=ActionRequired&BRQ_CURRENCY=EUR&BRQ_INVOICENUMBER=2013-0001&BRQ_MUTATIONTYPE=NotSet&BRQ_REDIRECTURL=https%3a%2f%2fcheckout.buckaroo.nl%2fhtml%2fredirect.ashx%3fr%3d44444BB28423418F555EDD866F59C880&BRQ_STATUSCODE=790&BRQ_STATUSMESSAGE=Pending+input&BRQ_TEST=false&BRQ_TIMESTAMP=2013-06-14+11%3a02%3a21&BRQ_TRANSACTIONS=7A6C58B91KJH4E66B53A91928NNN4D7F&BRQ_SIGNATURE=a1875c8ecd209b0173692ca83d002c4ed02785c2')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.purchase(@amount, nil, {
        culture:        @culture,
        currency:       @currency,
        description:    @description,
        invoicenumber:  @invoicenumber,
        payment_method: @payment_method,
        return:         @return
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.invoicenumber.should == @invoicenumber
      @response.redirecturl.should == "https://checkout.buckaroo.nl/html/redirect.ashx?r=44444BB28423418F555EDD866F59C880"
      @response.success?.should == true
      @response.statuscode.should == "790"
      @response.test?.should == false

      @response.response_data.should_not == ""
      @response.amount.should == @amount.to_s

      @response.post_params.should_not == nil
      @response.post_params[:brq_amount].should == @amount
      @response.post_params[:brq_culture].should == @culture
      @response.post_params[:brq_currency].should == @currency
      @response.post_params[:brq_description].should == @description
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
      @response.post_params[:brq_payment_method].should == @payment_method
      @response.post_params[:brq_return].should == @return
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
        culture:        @culture,
        currency:       @currency,
        description:    @description,
        invoicenumber:  @invoicenumber,
        payment_method: @payment_method,
        return:         @return
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should == ""
      @response.success?.should == false
      @response.statuscode.should == nil
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
        culture:        @culture,
        currency:       @currency,
        description:    @description,
        invoicenumber:  @invoicenumber,
        payment_method: @payment_method,
        return:         @return
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should == "this is a very nasty response"
      @response.success?.should == false
      @response.statuscode.should == nil
    end
  end

  context "setup recurring" do
    
    before do
      @secretkey  = "secretkey"
      @websitekey = "websitekey"
      @gateway    = ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway.new( {
        secretkey:  @secretkey, 
        websitekey: @websitekey
      } )
      
      @amount               = 1.23
      @currency             = "EUR"
      @description          = "Description"
      @invoicenumber        = "2013-0001"
      @originaltransaction  = "AAAABBBB"
      @payment_method       = "mastercard"
    end
    
    context "ArgumentErrors" do

      it "should raise an ArumentError when currency is not EUR, GBP or USD" do
        @currency = "MYCURR"

        lambda {
          @gateway.recurring(@amount, nil, {
            currency:             @currency,
            description:          @description,
            invoicenumber:        @invoicenumber,
            originaltransaction:  @originaltransaction,
            payment_method:       @payment_method,
          }) }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of description is more than 40" do
        @description = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.recurring(@amount, nil, {
            currency:             @currency,
            description:          @description,
            invoicenumber:        @invoicenumber,
            originaltransaction:  @originaltransaction,
            payment_method:       @payment_method,
          }) }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when string length of invoicenumber is more than 40" do
        @invoicenumber = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @gateway.recurring(@amount, nil, {
            currency:             @currency,
            description:          @description,
            invoicenumber:        @invoicenumber,
            originaltransaction:  @originaltransaction,
            payment_method:       @payment_method,
          }) }.should raise_error(ArgumentError)
      end
    
      it "should raise an ArumentError when string originaltransaction is not present" do
        lambda {
          @gateway.recurring(@amount, nil, {
            currency:             @currency,
            description:          @description,
            invoicenumber:        @invoicenumber,
            payment_method:       @payment_method,
          }) }.should raise_error(ArgumentError)
      end
    
      it "should raise an ArumentError when string payment_method is not equal to mastercard or visa" do
        @payment_method = "myowncreditcard"

        lambda {
          @gateway.recurring(@amount, nil, {
            currency:             @currency,
            description:          @description,
            invoicenumber:        @invoicenumber,
            originaltransaction:  @originaltransaction,
            payment_method:       @payment_method,
          }) }.should raise_error(ArgumentError)
      end
    
    end
    
    it "should also work with visa cards" do

      @payment_method = "visa"

      @response = @gateway.recurring(@amount, nil, {
        currency:             @currency,
        description:          @description,
        invoicenumber:        @invoicenumber,
        originaltransaction:  @originaltransaction,
        payment_method:       @payment_method,
      })
      @response.post_params[:brq_payment_method].should == "visa"
    end

    it "should create a new recurring via the Buckaroo API" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_AMOUNT=1.23&BRQ_APIRESULT=Success&BRQ_CURRENCY=EUR&BRQ_INVOICENUMBER=2013-0001&BRQ_PAYMENT=89E1B0F2793C22C0B62EE0F8E971AD21&BRQ_PAYMENT_METHOD=mastercard&BRQ_SERVICE_MASTERCARD_CARDNUMBERENDING=1111&BRQ_STATUSCODE=190&BRQ_STATUSCODE_DETAIL=S001&BRQ_STATUSMESSAGE=Payment+successfully+processed&BRQ_TEST=false&BRQ_TIMESTAMP=2013-06-14+14%3a59%3a36&BRQ_TRANSACTIONS=AABKKKE5810949444B92F51A4CAH8HDD&BRQ_SIGNATURE=b5956d4a3304218437cd15c85b539fa37420c56a')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.recurring(@amount, nil, {
        currency:             @currency,
        description:          @description,
        invoicenumber:        @invoicenumber,
        originaltransaction:  @originaltransaction,
        payment_method:       @payment_method,
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.invoicenumber.should == @invoicenumber
      @response.success?.should == true
      @response.statuscode.should == "190"
      @response.test?.should == false

      @response.response_data.should_not == ""
      @response.amount.should == @amount.to_s

      @response.post_params.should_not == nil
      @response.post_params[:brq_amount].should == @amount
      @response.post_params[:brq_currency].should == @currency
      @response.post_params[:brq_description].should == @description
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
      @response.post_params[:brq_originaltransaction].should == @originaltransaction
      @response.post_params[:brq_payment_method].should == @payment_method
    end

    it "should still work with empty response" do

      http_mock = mock(Net::HTTP)      
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return("")
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.recurring(@amount, nil, {
        currency:             @currency,
        description:          @description,
        invoicenumber:        @invoicenumber,
        originaltransaction:  @originaltransaction,
        payment_method:       @payment_method,
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should == ""
      @response.success?.should == false
      @response.statuscode.should == nil
    end

    it "should still work with crappy response" do

      http_mock = mock(Net::HTTP)      
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return("this is a very nasty response")
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.recurring(@amount, nil, {
        currency:             @currency,
        description:          @description,
        invoicenumber:        @invoicenumber,
        originaltransaction:  @originaltransaction,
        payment_method:       @payment_method,
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should == "this is a very nasty response"
      @response.success?.should == false
      @response.statuscode.should == nil
    end

  end

end
