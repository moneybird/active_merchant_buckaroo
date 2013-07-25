require "spec_helper.rb"

describe "Buckaroo Response And Push Parser" do

  context "parse push" do

    before do
      @secretkey = "secretkey"
    end

    it "should parse a push correctly - directdebit" do

      params = {"brq_transactions"=>"BFC3BF022226471497CDDDDC90B88DE7", "brq_statuscode"=>"791", "brq_statusmessage"=>"Pending processing", "brq_transaction_type"=>"C002", "brq_mutationtype"=>"Collecting", "brq_invoicenumber"=>"2013-0001", "brq_amount"=>"1.23", "brq_currency"=>"EUR", "brq_test"=>"true", "brq_timestamp"=>"2013-03-19 14:06:23", "brq_transaction_method"=>"directdebit", "brq_signature"=>"36d9fb90b941e6f8930ace977df255dc5b4c8970"}
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)

      response_parser.directdebit?.should == true
      response_parser.pending?.should == true
      response_parser.test?.should == true
      response_parser.valid?.should == true

      response_parser.directdebitrecurring?.should == false
      response_parser.failure?.should == false
      response_parser.success?.should == false

      response_parser.amount.should == "1.23"
      response_parser.currency.should == "EUR"
      response_parser.invoicenumber.should == "2013-0001"
      response_parser.mutationtype.should == "Collecting"
      response_parser.signature.should == "36d9fb90b941e6f8930ace977df255dc5b4c8970"
      response_parser.statuscode.should == "791"
      response_parser.statusmessage.should == "Pending processing"
      response_parser.test.should == "true"
      response_parser.timestamp.should == "2013-03-19 14:06:23"
      response_parser.transaction_method.should == "directdebit"
      response_parser.transaction_type.should == "C002"
      response_parser.transactions.should == "BFC3BF022226471497CDDDDC90B88DE7"
    end

    it "should parse a push correctly - brq_test - 1" do
      params = { "brq_test" => "false" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.test.should == "false"
      response_parser.test?.should == false
    end

    it "should parse a push correctly - brq_test - 2" do
      params = { "brq_test" => "true" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.test.should == "true"
      response_parser.test?.should == true
    end


    it "should parse a push correctly - brq_transaction_method - 1 - directdebit" do
      params = { "brq_transaction_type" => "C002" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.creditcard?.should == false
      response_parser.directdebit?.should == true
      response_parser.directdebitrecurring?.should == false
      response_parser.reversal?.should == false
    end

    it "should parse a push correctly - brq_transaction_method - 2 - directdebitrecurring" do
      params = { "brq_transaction_type" => "C003" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.creditcard?.should == false
      response_parser.directdebit?.should == false
      response_parser.directdebitrecurring?.should == true
      response_parser.reversal?.should == false
    end

    it "should parse a push correctly - brq_transaction_method - 3 - reversal" do
      params = { "brq_transaction_type" => "C562" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.creditcard?.should == false
      response_parser.directdebit?.should == false
      response_parser.directdebitrecurring?.should == false
      response_parser.reversal?.should == true
    end

    it "should parse a push correctly - brq_transaction_method - 4 - mastercard" do
      params = { "brq_transaction_type" => "V043" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.creditcard?.should == true
      response_parser.directdebit?.should == false
      response_parser.directdebitrecurring?.should == false
      response_parser.mastercard?.should == true
      response_parser.reversal?.should == false
      response_parser.visa?.should == false
    end

    it "should parse a push correctly - brq_transaction_method - 5 - visa" do
      params = { "brq_transaction_type" => "V044" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.creditcard?.should == true
      response_parser.directdebit?.should == false
      response_parser.directdebitrecurring?.should == false
      response_parser.mastercard?.should == false
      response_parser.reversal?.should == false
      response_parser.visa?.should == true
    end


    it "should parse a push correctly - brq_statuscode - 1" do
      params = { "brq_statuscode" => "791" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.failure?.should == false
      response_parser.pending?.should == true
      response_parser.success?.should == false
    end

    it "should parse a push correctly - brq_statuscode - 2" do
      params = { "brq_statuscode" => "190" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.failure?.should == false
      response_parser.pending?.should == false
      response_parser.success?.should == true
    end

    it "should parse a push correctly - brq_statuscode - 3" do
      params = { "brq_statuscode" => "490" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.failure?.should == true
      response_parser.pending?.should == false
      response_parser.success?.should == false
    end

    it "should parse a push correctly - brq_statuscode - 4" do
      params = { "brq_statuscode" => "999" }
      response_parser = ActiveMerchant::Billing::BuckarooBPE3ResponseParser.new(params, @secretkey)
      response_parser.failure?.should == false
      response_parser.pending?.should == false
      response_parser.success?.should == false
    end

  end

end
