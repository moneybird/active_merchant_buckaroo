require "spec_helper.rb"

describe "Buckaroo BPE3 Toolbox" do
  
  context "test all functions" do
    
    before do
      @secretkey = "secretkey"
      @signature = "signature"
      @websitekey = "websitekey"

      @params = { 
        brq_amount: 1.23,
        brq_culture: "NL",
        brq_currency: "EUR",
        brq_description: "MyInvoice",
        brq_invoicenumber: "2013-0001",
        brq_payment_method: "directdebit",
        brq_service_directdebit_action: "Pay",
        brq_service_directdebit_customeraccountname: "My Name",
        brq_service_directdebit_customeraccountnumber: "1234567",
        brq_websitekey: @websitekey,
      }
    end
    
    it "should create good post data string" do
      ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_post_data(@params, @signature).should == "brq_amount=1.23&brq_culture=NL&brq_currency=EUR&brq_description=MyInvoice&brq_invoicenumber=2013-0001&brq_payment_method=directdebit&brq_service_directdebit_action=Pay&brq_service_directdebit_customeraccountname=My+Name&brq_service_directdebit_customeraccountnumber=1234567&brq_websitekey=websitekey&brq_signature=signature"
    end
    
    it "should create a valid signature" do
      ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(@params, @secretkey).should == "ed6646396c285a6f9285ca29af4e78f3535f2fdb"
    end

    it "should sort the hash for signatures the right way (case insensitive)" do
      # should sort hash this way:
      # [["brq_a", 1], ["brq_B", 2], ["brq_c", 3]]
      # and not
      # [["brq_B", 2], ["brq_a", 1], ["brq_c", 3]]
      params = { "brq_a" => 1, "brq_B" => 2, "brq_c" => 3 }
      ActiveMerchant::Billing::BuckarooBPE3Toolbox.sort_hash(params).should == [["brq_a", 1], ["brq_B", 2], ["brq_c", 3]]
    end
    
    it "should sort the hash for signatures the right way (integer followed by string in string)" do
      # should sort hash this way:
      # [["brq_1_id", 1], ["brq_10_id", 1], ["brq_2_id", 1]]
      # and not
      # [["brq_10_id", 1], ["brq_1_id", 1], ["brq_2_id", 1]]
      params = { "brq_1_id" => 1, "brq_10_id" => 1, "brq_2_id" => 1 }
      ActiveMerchant::Billing::BuckarooBPE3Toolbox.sort_hash(params).should == [["brq_1_id", 1], ["brq_10_id", 1], ["brq_2_id", 1]]
    end
    
    it "should correctly check a signature" do
      str = "BRQ_AMOUNT=1.23&BRQ_APIRESULT=Pending&BRQ_CURRENCY=EUR&BRQ_INVOICENUMBER=2013-0001&BRQ_PAYMENT=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_PAYMENT_METHOD=directdebit&BRQ_STATUSCODE=791&BRQ_STATUSMESSAGE=Pending+processing&BRQ_TEST=false&BRQ_TIMESTAMP=2013-03-19+15%3a02%3a08&BRQ_TRANSACTIONS=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_SIGNATURE=dee5c83c666c9837051182d6d8866d2c1e5eb446"
      
      params = Rack::Utils.parse_query(str)
      ActiveMerchant::Billing::BuckarooBPE3Toolbox.check_signature(params, @secretkey).should == true
      # make sure the BRQ_SIGNATURE is not deleted from the original hash
      params["BRQ_SIGNATURE"].should == "dee5c83c666c9837051182d6d8866d2c1e5eb446"
    end

    it "should downcase the keys in hash" do

      params = { "BRQ_AMOUNT" => "1.23", "BRQ_TEST" => "true" }
      result = ActiveMerchant::Billing::BuckarooBPE3Toolbox.hash_to_downcase_keys(params)

      result["BRQ_AMOUNT"].should == nil
      result["brq_amount"].should == "1.23"
      result["BRQ_TEST"].should == nil
      result["brq_test"].should == "true"
    end

    it "unescapes the string value when creating the signature" do
      params_1 = { "brq_statusmessage"=>"Transaction+successfully+processed" }
      params_2 = { "brq_statusmessage"=>"Transaction successfully processed" }

      expect(ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(params_1, @secretkey)).to eq(
        ActiveMerchant::Billing::BuckarooBPE3Toolbox.create_signature(params_2, @secretkey)
      )
    end

  end

end
