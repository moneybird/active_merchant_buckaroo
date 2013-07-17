require "spec_helper.rb"

describe "Buckaroo Status implementation for ActiveMerchant" do
  
  it "should create a new billing gateway with a required merchantid and secretkey" do
    ActiveMerchant::Billing::BuckarooBPE3StatusGateway.new( { secretkey: "1234", websitekey: "1234" } ).should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3StatusGateway)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3StatusGateway.new( { secretkey: "1234" } )
    }.should raise_error(ArgumentError) 
  end
  
  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3StatusGateway.new( { websitekey: "1234" } )
    }.should raise_error(ArgumentError)
  end

  context "status_for_invoicenumber" do
    
    before do
      @secretkey  = "secretkey"
      @websitekey = "websitekey"
      @gateway    = ActiveMerchant::Billing::BuckarooBPE3StatusGateway.new( {
        secretkey:  @secretkey, 
        websitekey: @websitekey
      } )
      
      @amount_invoice = 10
      @invoicenumber  = "2013-0001"
    end
    
    context "ArgumentErrors" do

      it "should raise an ArumentError when string length of invoicenumber is more than 40" do
        @invoicenumber = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

        lambda {
          @response = @gateway.status_for_invoicenumber({
            amount_invoice: @amount_invoice,
            invoicenumber:  @invoicenumber
          }) 
        }.should raise_error(ArgumentError)
      end
    end

    it "should return a descent response for a failed direct debit" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_APIRESULT=Success&BRQ_INVOICE_1_CREDITMANAGEMENT=False&BRQ_INVOICE_1_NUMBER=2013-0001&BRQ_INVOICE_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTDEBIT=10&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTREFUNDABLE=0&BRQ_INVOICE_1_TRANSACTIONS_1_CREATEDDATETIME=2013-07-03+15%3a54%3a54&BRQ_INVOICE_1_TRANSACTIONS_1_CURRENCY=EUR&BRQ_INVOICE_1_TRANSACTIONS_1_DESCRIPTION=MoneyBird+account&BRQ_INVOICE_1_TRANSACTIONS_1_ID=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_CODE=490&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_DATETIME=2013-07-05+08%3a37%3a25&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_MESSAGE=Failed&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_SUCCESS=False&BRQ_INVOICE_1_TRANSACTIONS_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_TYPE=C003&BRQ_INVOICE_1_TRANSACTIONS_1_TYPEDESCRIPTION=Doorlopende+machtiging&BRQ_SIGNATURE=3dcea2db154dcc7f955820f91c81d08090aadb21')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.status_for_invoicenumber({
        amount_invoice: @amount_invoice,
        invoicenumber:  @invoicenumber
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should == true
      @response.test?.should == false
      @response.status_paid?.should == false

      @response.status_amount_paid.should == 0

      @response.response_parser.valid?.should == true

      @response.response_data.should_not == ""

      @response.post_params.should_not == nil
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
    end

    it "should return a descent response for a succesful direct debit" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_APIRESULT=Success&BRQ_INVOICE_1_CREDITMANAGEMENT=False&BRQ_INVOICE_1_NUMBER=2013-0001&BRQ_INVOICE_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTDEBIT=10&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTREFUNDABLE=10&BRQ_INVOICE_1_TRANSACTIONS_1_CREATEDDATETIME=2013-07-03+14%3a24%3a17&BRQ_INVOICE_1_TRANSACTIONS_1_CURRENCY=EUR&BRQ_INVOICE_1_TRANSACTIONS_1_DESCRIPTION=MoneyBird+account&BRQ_INVOICE_1_TRANSACTIONS_1_ID=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_CODE=190&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_DATETIME=2013-07-05+08%3a38%3a33&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_MESSAGE=Success&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_SUCCESS=True&BRQ_INVOICE_1_TRANSACTIONS_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_TYPE=C003&BRQ_INVOICE_1_TRANSACTIONS_1_TYPEDESCRIPTION=Doorlopende+machtiging&BRQ_SIGNATURE=c40f9ab8f4e713284e5ee40ece9c7aad6bce86b2')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.status_for_invoicenumber({
        amount_invoice: @amount_invoice,
        invoicenumber:  @invoicenumber
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should == true
      @response.test?.should == false
      @response.status_paid?.should == true

      @response.status_amount_paid.should == 10

      @response.response_parser.valid?.should == true

      @response.response_data.should_not == ""

      @response.post_params.should_not == nil
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
    end

    it "should return a descent response for a succesful direct debit with reversal" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_APIRESULT=Success&BRQ_INVOICE_1_CREDITMANAGEMENT=False&BRQ_INVOICE_1_NUMBER=2013-00001&BRQ_INVOICE_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTDEBIT=10&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTREFUNDABLE=0&BRQ_INVOICE_1_TRANSACTIONS_1_CREATEDDATETIME=2013-07-03+14%3a25%3a57&BRQ_INVOICE_1_TRANSACTIONS_1_CURRENCY=EUR&BRQ_INVOICE_1_TRANSACTIONS_1_DESCRIPTION=MoneyBird+account&BRQ_INVOICE_1_TRANSACTIONS_1_ID=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&BRQ_INVOICE_1_TRANSACTIONS_1_REFUNDS_1_AMOUNT=10&BRQ_INVOICE_1_TRANSACTIONS_1_REFUNDS_1_ID=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&BRQ_INVOICE_1_TRANSACTIONS_1_REFUNDS_1_REFUNDDATE=2013-07-08+08%3a42%3a43&BRQ_INVOICE_1_TRANSACTIONS_1_REFUNDS_1_STATUS_CODE=605&BRQ_INVOICE_1_TRANSACTIONS_1_REFUNDS_1_STATUS_DATETIME=2013-07-08+08%3a42%3a43&BRQ_INVOICE_1_TRANSACTIONS_1_REFUNDS_1_STATUS_SUCCESS=False&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_CODE=190&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_DATETIME=2013-07-05+08%3a38%3a35&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_MESSAGE=Success&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_SUCCESS=True&BRQ_INVOICE_1_TRANSACTIONS_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_TYPE=C003&BRQ_INVOICE_1_TRANSACTIONS_1_TYPEDESCRIPTION=Doorlopende+machtiging&BRQ_INVOICE_1_TRANSACTIONS_2_AMOUNTCREDIT=10&BRQ_INVOICE_1_TRANSACTIONS_2_AMOUNTREFUNDABLE=0&BRQ_INVOICE_1_TRANSACTIONS_2_CREATEDDATETIME=2013-07-08+08%3a42%3a43&BRQ_INVOICE_1_TRANSACTIONS_2_CURRENCY=EUR&BRQ_INVOICE_1_TRANSACTIONS_2_DESCRIPTION=MoneyBird+account&BRQ_INVOICE_1_TRANSACTIONS_2_ID=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&BRQ_INVOICE_1_TRANSACTIONS_2_STATUS_CODE=190&BRQ_INVOICE_1_TRANSACTIONS_2_STATUS_DATETIME=2013-07-08+08%3a42%3a44&BRQ_INVOICE_1_TRANSACTIONS_2_STATUS_MESSAGE=Success&BRQ_INVOICE_1_TRANSACTIONS_2_STATUS_SUCCESS=True&BRQ_INVOICE_1_TRANSACTIONS_2_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_2_TYPE=C562&BRQ_INVOICE_1_TRANSACTIONS_2_TYPEDESCRIPTION=Stornering&BRQ_SIGNATURE=decab0150d4f134f96b0e487225f96f399baf1aa')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.status_for_invoicenumber({
        amount_invoice: @amount_invoice,
        invoicenumber:  @invoicenumber
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should == true
      @response.test?.should == false
      @response.status_paid?.should == false

      @response.response_parser.valid?.should == true

      @response.status_amount_paid.should == 0

      @response.response_data.should_not == ""

      @response.post_params.should_not == nil
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
    end

    it "should return a descent response for a succesful credit card" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_APIRESULT=Success&BRQ_INVOICE_1_CREDITMANAGEMENT=False&BRQ_INVOICE_1_NUMBER=2013-0001&BRQ_INVOICE_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTDEBIT=10&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTREFUNDABLE=10&BRQ_INVOICE_1_TRANSACTIONS_1_CREATEDDATETIME=2013-07-16+05%3a55%3a49&BRQ_INVOICE_1_TRANSACTIONS_1_CURRENCY=EUR&BRQ_INVOICE_1_TRANSACTIONS_1_DESCRIPTION=MoneyBird+creditcard+validation&BRQ_INVOICE_1_TRANSACTIONS_1_ID=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_CODE=190&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_DATETIME=2013-07-16+05%3a57%3a01&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_MESSAGE=Success&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_SUCCESS=True&BRQ_INVOICE_1_TRANSACTIONS_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_TYPE=V044&BRQ_INVOICE_1_TRANSACTIONS_1_TYPEDESCRIPTION=Creditcard+-+Visa+via+EMS&BRQ_SIGNATURE=a7d658edade2004a8c2700e007f444b14d0a2b86')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.status_for_invoicenumber({
        amount_invoice: @amount_invoice,
        invoicenumber:  @invoicenumber
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should == true
      @response.test?.should == false
      @response.status_paid?.should == true

      @response.response_parser.valid?.should == true

      @response.status_amount_paid.should == 10

      @response.response_data.should_not == ""

      @response.post_params.should_not == nil
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
    end

    it "should return a descent response for a failed credit card (old type, bpe2)" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_APIRESULT=Success&BRQ_INVOICE_1_CREDITMANAGEMENT=False&BRQ_INVOICE_1_NUMBER=2013-0001&BRQ_INVOICE_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTDEBIT=10&BRQ_INVOICE_1_TRANSACTIONS_1_AMOUNTREFUNDABLE=0&BRQ_INVOICE_1_TRANSACTIONS_1_CREATEDDATETIME=2013-07-03+21%3a21%3a02&BRQ_INVOICE_1_TRANSACTIONS_1_CURRENCY=EUR&BRQ_INVOICE_1_TRANSACTIONS_1_DESCRIPTION=MoneyBird+account&BRQ_INVOICE_1_TRANSACTIONS_1_ID=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_CODE=101&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_DATETIME=2013-07-03+21%3a21%3a03&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_MESSAGE=De+transactie+is+door+de+credit-maatschappij+afgekeurd.&BRQ_INVOICE_1_TRANSACTIONS_1_STATUS_SUCCESS=False&BRQ_INVOICE_1_TRANSACTIONS_1_TEST=False&BRQ_INVOICE_1_TRANSACTIONS_1_TYPE=N002&BRQ_INVOICE_1_TRANSACTIONS_1_TYPEDESCRIPTION=Creditcard+-+Visa&BRQ_SIGNATURE=167fba01d3f95aee4793b9643271de8b027bb64c')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.status_for_invoicenumber({
        amount_invoice: @amount_invoice,
        invoicenumber:  @invoicenumber
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.success?.should == true
      @response.test?.should == false
      @response.status_paid?.should == false

      @response.response_parser.valid?.should == true

      @response.status_amount_paid.should == 0

      @response.response_data.should_not == ""

      @response.post_params.should_not == nil
      @response.post_params[:brq_invoicenumber].should == @invoicenumber
    end

    it "should still work with empty response" do

      http_mock = mock(Net::HTTP)      
      http_mock.should_receive(:read_timeout=).once.with(300)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return("")
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.status_for_invoicenumber({
        amount_invoice: @amount_invoice,
        invoicenumber:  @invoicenumber
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
      
      @response = @gateway.status_for_invoicenumber({
        amount_invoice: @amount_invoice,
        invoicenumber:  @invoicenumber
      })

      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should == "this is a very nasty response"
      @response.success?.should == false
      @response.statuscode.should == nil
    end

  end

end
