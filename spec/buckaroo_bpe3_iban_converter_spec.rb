require "spec_helper.rb"

describe "Buckaroo IBAN Converter implementation for ActiveMerchant" do
  
  it "should create a new billing gateway with a required merchantid and secretkey" do
    ActiveMerchant::Billing::BuckarooBPE3IbanConverterGateway.new(:secretkey => "1234", :websitekey => "1234").should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3IbanConverterGateway)
  end

  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3IbanConverterGateway.new(:secretkey => "1234")
    }.should raise_error(ArgumentError)
  end
  
  it "should throw an error if a gateway is created without merchantid or secretkey" do
    lambda {
      ActiveMerchant::Billing::BuckarooBPE3IbanConverterGateway.new(:websitekey => "1234")
    }.should raise_error(ArgumentError)
  end

  context "convert_to_iban" do
    
    before do
      @secretkey  = "secretkey"
      @websitekey = "websitekey"
      @gateway    = ActiveMerchant::Billing::BuckarooBPE3IbanConverterGateway.new(:secretkey => @secretkey, :websitekey => @websitekey)
      
      @accountnumber  = "7654321"
      @countryisocode = "NL"
    end
    
    context "ArgumentErrors" do

      it "should raise an ArumentError when countryisocode is not BE, DE, FR or NL" do
        @countryisocode = "GR"

        lambda {
          @gateway.convert_to_iban(@amount, nil, {
            countryisocode: @countryisocode
          }) }.should raise_error(ArgumentError)
      end

      it "should raise an ArumentError when countryisocode == DE and bankcode is not provided" do
        @countryisocode = "DE"
        @bankcode = nil

        lambda {
          @gateway.convert_to_iban(@amount, nil, {
            bankcode: @bankcode,
            countryisocode: @countryisocode
          }) }.should raise_error(ArgumentError)
      end
    
    end


    it "should return IBAN + BIC for old account number via the Buckaroo API" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(4)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_APIRESULT=Success&BRQ_BIC=INGBNL2A&BRQ_IBAN=NL36INGB0007654321&BRQ_SIGNATURE=a04ccac519677bdd9d52a90be3efa126480f248c')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.convert_to_iban({
        accountnumber: @accountnumber,
        countryisocode: @countryisocode
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should_not == ""
      @response.bic.should == "INGBNL2A"
      @response.iban.should == "NL36INGB0007654321"
      @response.success?.should == true
      @response.iban_converter_success?.should == true
      
      @response.post_params.should_not == nil
    end

    it "should return NO IBAN + BIC for old account number via the Buckaroo API if not valid" do

      http_mock = mock(Net::HTTP)
      http_mock.should_receive(:read_timeout=).once.with(4)
      http_mock.should_receive(:use_ssl=).once.with(true)
      Net::HTTP.should_receive(:new).with("checkout.buckaroo.nl", 443).and_return(http_mock)
      
      response_mock = mock(Net::HTTPResponse)
      response_mock.should_receive(:body).and_return('BRQ_APIRESULT=Success&BRQ_BIC=&BRQ_ERROR=No+Iban+or+BIC+was+returned.&BRQ_IBAN=&BRQ_SIGNATURE=25d2c2bd91de84b82c344bb9a5de02659e7de5e3')
      http_mock.should_receive(:post).and_return(response_mock)
      
      @response = @gateway.convert_to_iban({
        accountnumber: @accountnumber,
        countryisocode: @countryisocode
      })
      
      @response.should be_kind_of(ActiveMerchant::Billing::BuckarooBPE3Response)
      @response.response_data.should_not == ""
      @response.bic.should == ""
      @response.iban.should == ""
      @response.success?.should == true
      @response.iban_converter_success?.should == false
      
      @response.post_params.should_not == nil
    end
  end

  context "bic_for_iban" do

    before :each do
      @secretkey  = "secretkey"
      @websitekey = "websitekey"
      @gateway    = ActiveMerchant::Billing::BuckarooBPE3IbanConverterGateway.new(:secretkey => @secretkey, :websitekey => @websitekey)

      @countryisocode = "NL"
    end

    it "should return the BIC for ABNA bank account" do
      @accountnumber  = "NL00ABNA0000000000"
      bic = @gateway.bic_for_iban({ accountnumber: @accountnumber, countryisocode: @countryisocode })
      bic.should == "ABNANL2A"
    end

    it "should return the BIC for INGB bank account" do
      @accountnumber  = "NL00INGB0000000000"
      bic = @gateway.bic_for_iban({ accountnumber: @accountnumber, countryisocode: @countryisocode })
      bic.should == "INGBNL2A"
    end

    it "should return the BIC for RABO bank account" do
      @accountnumber  = "NL00RABO0000000000"
      bic = @gateway.bic_for_iban({ accountnumber: @accountnumber, countryisocode: @countryisocode })
      bic.should == "RABONL2U"
    end

  end

end
