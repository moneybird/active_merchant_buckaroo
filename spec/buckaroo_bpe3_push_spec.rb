require "spec_helper.rb"

describe "Buckaroo Push" do

  context "parse push" do

    before do
      @secretkey = "secretkey"
    end

    it "should parse a push correctly" do

      params = {"brq_transactions"=>"BFC3BF022226471497CDDDDC90B88DE7", "brq_statuscode"=>"791", "brq_statusmessage"=>"Pending processing", "brq_transaction_type"=>"C002", "brq_mutationtype"=>"Collecting", "brq_invoicenumber"=>"2013-0001", "brq_amount"=>"1.23", "brq_currency"=>"EUR", "brq_test"=>"true", "brq_timestamp"=>"2013-03-19 14:06:23", "brq_transaction_method"=>"directdebit", "brq_signature"=>"36d9fb90b941e6f8930ace977df255dc5b4c8970"}
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)

      push.directdebit?.should == true
      push.pending?.should == true
      push.test?.should == true
      push.valid?.should == true

      push.directdebitrecurring?.should == false
      push.failure?.should == false
      push.success?.should == false

      push.amount.should == "1.23"
      push.currency.should == "EUR"
      push.invoicenumber.should == "2013-0001"
      push.mutationtype.should == "Collecting"
      push.signature.should == "36d9fb90b941e6f8930ace977df255dc5b4c8970"
      push.statuscode.should == "791"
      push.statusmessage.should == "Pending processing"
      push.test.should == "true"
      push.timestamp.should == "2013-03-19 14:06:23"
      push.transaction_method.should == "directdebit"
      push.transaction_type.should == "C002"
      push.transactions.should == "BFC3BF022226471497CDDDDC90B88DE7"
    end

    it "should parse a push correctly - brq_test - 1" do
      params = { "brq_test" => "false" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.test.should == "false"
      push.test?.should == false
    end

    it "should parse a push correctly - brq_test - 2" do
      params = { "brq_test" => "true" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.test.should == "true"
      push.test?.should == true
    end

    it "should parse a push correctly - brq_transaction_method - 1" do
      params = { "brq_transaction_type" => "C002" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.directdebit?.should == true
      push.directdebitrecurring?.should == false
      push.reversal?.should == false
    end

    it "should parse a push correctly - brq_transaction_method - 2" do
      params = { "brq_transaction_type" => "C003" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.directdebit?.should == false
      push.directdebitrecurring?.should == true
      push.reversal?.should == false
    end

    it "should parse a push correctly - brq_transaction_method - 3" do
      params = { "brq_transaction_type" => "C562" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.directdebit?.should == false
      push.directdebitrecurring?.should == false
      push.reversal?.should == true
    end

    it "should parse a push correctly - brq_statuscode - 1" do
      params = { "brq_statuscode" => "791" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.failure?.should == false
      push.pending?.should == true
      push.success?.should == false
    end

    it "should parse a push correctly - brq_statuscode - 2" do
      params = { "brq_statuscode" => "190" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.failure?.should == false
      push.pending?.should == false
      push.success?.should == true
    end

    it "should parse a push correctly - brq_statuscode - 3" do
      params = { "brq_statuscode" => "490" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.failure?.should == true
      push.pending?.should == false
      push.success?.should == false
    end

    it "should parse a push correctly - brq_statuscode - 4" do
      params = { "brq_statuscode" => "999" }
      push = ActiveMerchant::Billing::BuckarooBPE3Push.new(params, @secretkey)
      push.failure?.should == false
      push.pending?.should == false
      push.success?.should == false
    end

  end

end
