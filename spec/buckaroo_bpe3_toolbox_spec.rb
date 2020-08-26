# frozen_string_literal: true

require "spec_helper"

describe ActiveMerchant::Billing::BuckarooBPE3Toolbox do
  let(:secretkey) { "secretkey" }
  let(:signature) { "signature" }
  let(:params) do
    {
      brq_amount: 1.23,
      brq_culture: "NL",
      brq_currency: "EUR",
      brq_description: "MyInvoice",
      brq_invoicenumber: "2013-0001",
      brq_payment_method: "directdebit",
      brq_service_directdebit_action: "Pay",
      brq_service_directdebit_customeraccountname: "My Name",
      brq_service_directdebit_customeraccountnumber: "1234567",
      brq_websitekey: "websitekey"
    }
  end

  it "creates correct post data string" do
    expect(
      described_class.create_post_data(params, signature)
    ).to eq("brq_amount=1.23&brq_culture=NL&brq_currency=EUR&brq_description=MyInvoice&brq_invoicenumber=2013-0001&brq_payment_method=directdebit&brq_service_directdebit_action=Pay&brq_service_directdebit_customeraccountname=My+Name&brq_service_directdebit_customeraccountnumber=1234567&brq_websitekey=websitekey&brq_signature=signature")
  end

  it "creates a valid signature" do
    expect(
      described_class.create_signature(params, secretkey)
    ).to eq("ed6646396c285a6f9285ca29af4e78f3535f2fdb")
  end

  it "sorts the hash for signatures the right way (case insensitive)" do
    # should sort hash this way:
    # [["brq_a", 1], ["brq_B", 2], ["brq_c", 3]]
    # and not
    # [["brq_B", 2], ["brq_a", 1], ["brq_c", 3]]
    params = { "brq_d" => 4, "brq_B" => 2, "brq_a" => 1, "brq_c" => 3 }
    expect(
      described_class.sort_hash(params)
    ).to eq([["brq_a", 1], ["brq_B", 2], ["brq_c", 3], ["brq_d", 4]])
  end

  it "sorts the hash for signatures the right way (integer followed by string in string)" do
    # should sort hash this way:
    # [["brq_1_id", 1], ["brq_10_id", 1], ["brq_2_id", 1]]
    # and not
    # [["brq_10_id", 1], ["brq_1_id", 1], ["brq_2_id", 1]]
    params = { "brq_3_id" => 1, "brq_10_id" => 1, "brq_1_id" => 1, "brq_2_id" => 1 }
    expect(
      described_class.sort_hash(params)
    ).to eq([["brq_1_id", 1], ["brq_10_id", 1], ["brq_2_id", 1], ["brq_3_id", 1]])
  end

  it "correctly checks a signature" do
    str = "BRQ_AMOUNT=1.23&BRQ_APIRESULT=Pending&BRQ_CURRENCY=EUR&BRQ_INVOICENUMBER=2013-0001&BRQ_PAYMENT=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_PAYMENT_METHOD=directdebit&BRQ_STATUSCODE=791&BRQ_STATUSMESSAGE=Pending+processing&BRQ_TEST=false&BRQ_TIMESTAMP=2013-03-19+15%3a02%3a08&BRQ_TRANSACTIONS=1234567890ABCDEFGHIJKLMNOPQRSTUV&BRQ_SIGNATURE=dee5c83c666c9837051182d6d8866d2c1e5eb446"

    params = Rack::Utils.parse_query(str)
    expect(described_class.check_signature(params, secretkey)).to eq(true)
    # make sure the BRQ_SIGNATURE is not deleted from the original hash
    expect(params["BRQ_SIGNATURE"]).to eq("dee5c83c666c9837051182d6d8866d2c1e5eb446")
  end

  it "downcases the keys in hash" do
    params = { "BRQ_AMOUNT" => "1.23", "BRQ_TEST" => "true" }
    result = described_class.hash_to_downcase_keys(params)

    expect(result).to eq(
      "brq_amount" => "1.23",
      "brq_test" => "true"
    )
  end
end
