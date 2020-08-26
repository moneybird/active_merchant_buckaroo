# frozen_string_literal: true

require "spec_helper"

describe ActiveMerchant::Billing::BuckarooBPE3ResponseParser do
  let(:secretkey) { "secretkey" }

  it "parses a direct debit push correctly" do
    params = {
      "brq_transactions" => "BFC3BF022226471497CDDDDC90B88DE7",
      "brq_statuscode" => "791",
      "brq_statusmessage" => "Pending processing",
      "brq_transaction_type" => "C002",
      "brq_mutationtype" => "Collecting",
      "brq_invoicenumber" => "2013-0001",
      "brq_amount" => "1.23",
      "brq_currency" => "EUR",
      "brq_test" => "true",
      "brq_timestamp" => "2013-03-19 14:06:23",
      "brq_transaction_method" => "directdebit",
      "brq_signature" => "36d9fb90b941e6f8930ace977df255dc5b4c8970"
    }
    response_parser = described_class.new(params, secretkey)

    expect(response_parser).to be_directdebit
    expect(response_parser).to be_pending
    expect(response_parser).to be_test
    expect(response_parser).to be_valid

    expect(response_parser).not_to be_directdebitrecurring
    expect(response_parser).not_to be_failure
    expect(response_parser).not_to be_success

    expect(response_parser.amount).to eq("1.23")
    expect(response_parser.currency).to eq("EUR")
    expect(response_parser.invoicenumber).to eq("2013-0001")
    expect(response_parser.mutationtype).to eq("Collecting")
    expect(response_parser.signature).to eq("36d9fb90b941e6f8930ace977df255dc5b4c8970")
    expect(response_parser.statuscode).to eq("791")
    expect(response_parser.statusmessage).to eq("Pending processing")
    expect(response_parser.test).to eq("true")
    expect(response_parser.timestamp).to eq("2013-03-19 14:06:23")
    expect(response_parser.transaction_method).to eq("directdebit")
    expect(response_parser.transaction_type).to eq("C002")
    expect(response_parser.transactions).to eq("BFC3BF022226471497CDDDDC90B88DE7")
  end

  it "parses the brq_test = false parameter correctly" do
    params = { "brq_test" => "false" }
    response_parser = described_class.new(params, secretkey)
    expect(response_parser.test).to eq("false")
    expect(response_parser).not_to be_test
  end

  it "parses the brq_test = true parameter correctly" do
    params = { "brq_test" => "true" }
    response_parser = described_class.new(params, secretkey)
    expect(response_parser.test).to eq("true")
    expect(response_parser).to be_test
  end

  context "with brq_transaction_type parameter" do
    it "parses 'transfer' type correctly" do
      params = { "brq_transaction_type" => "C001" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_creditcard
      expect(response_parser).not_to be_directdebit
      expect(response_parser).not_to be_directdebitrecurring
      expect(response_parser).not_to be_reversal
      expect(response_parser).not_to be_simplesepadirectdebit
      expect(response_parser).to be_transfer
    end

    it "parses 'directdebit' type correctly" do
      params = { "brq_transaction_type" => "C002" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_creditcard
      expect(response_parser).to be_directdebit
      expect(response_parser).not_to be_directdebitrecurring
      expect(response_parser).not_to be_reversal
      expect(response_parser).not_to be_simplesepadirectdebit
      expect(response_parser).not_to be_transfer
    end

    it "parses 'directdebitrecurring' type correctly" do
      params = { "brq_transaction_type" => "C003" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_creditcard
      expect(response_parser).not_to be_directdebit
      expect(response_parser).to be_directdebitrecurring
      expect(response_parser).not_to be_reversal
      expect(response_parser).not_to be_simplesepadirectdebit
      expect(response_parser).not_to be_transfer
    end

    it "parses 'simplesepadirectdebit' type correctly" do
      params = { "brq_transaction_type" => "C008" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_creditcard
      expect(response_parser).not_to be_directdebit
      expect(response_parser).not_to be_directdebitrecurring
      expect(response_parser).not_to be_reversal
      expect(response_parser).to be_simplesepadirectdebit
      expect(response_parser).not_to be_transfer
    end

    it "parses 'debit reversal' type correctly" do
      params = { "brq_transaction_type" => "C562" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_creditcard
      expect(response_parser).not_to be_directdebit
      expect(response_parser).not_to be_directdebitrecurring
      expect(response_parser).to be_reversal
      expect(response_parser).not_to be_simplesepadirectdebit
      expect(response_parser).not_to be_transfer
    end

    it "parses 'SEPA reversal' type correctly" do
      params = { "brq_transaction_type" => "C501" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_creditcard
      expect(response_parser).not_to be_directdebit
      expect(response_parser).not_to be_directdebitrecurring
      expect(response_parser).to be_reversal
      expect(response_parser).not_to be_simplesepadirectdebit
      expect(response_parser).not_to be_transfer
    end

    it "parses 'SEPA reversal' alternative type correctly" do
      params = { "brq_transaction_type" => "C502" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_creditcard
      expect(response_parser).not_to be_directdebit
      expect(response_parser).not_to be_directdebitrecurring
      expect(response_parser).to be_reversal
      expect(response_parser).not_to be_simplesepadirectdebit
      expect(response_parser).not_to be_transfer
    end

    it "parses 'mastercard' type correctly" do
      params = { "brq_transaction_type" => "V043" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).to be_creditcard
      expect(response_parser).not_to be_directdebit
      expect(response_parser).not_to be_directdebitrecurring
      expect(response_parser).to be_mastercard
      expect(response_parser).not_to be_reversal
      expect(response_parser).not_to be_simplesepadirectdebit
      expect(response_parser).not_to be_transfer
      expect(response_parser).not_to be_visa
    end

    it "parses 'visa' type correctly" do
      params = { "brq_transaction_type" => "V044" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).to be_creditcard
      expect(response_parser).not_to be_directdebit
      expect(response_parser).not_to be_directdebitrecurring
      expect(response_parser).not_to be_mastercard
      expect(response_parser).not_to be_reversal
      expect(response_parser).not_to be_simplesepadirectdebit
      expect(response_parser).not_to be_transfer
      expect(response_parser).to be_visa
    end
  end

  context "with brq_statuscode parameter" do
    it "parses '791' correctly" do
      params = { "brq_statuscode" => "791" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_failure
      expect(response_parser).to be_pending
      expect(response_parser).not_to be_success
    end

    it "parses '190' correctly" do
      params = { "brq_statuscode" => "190" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_failure
      expect(response_parser).not_to be_pending
      expect(response_parser).to be_success
    end

    it "parses '490' correctly" do
      params = { "brq_statuscode" => "490" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).to be_failure
      expect(response_parser).not_to be_pending
      expect(response_parser).not_to be_success
    end

    it "parses unknown status codes correctly" do
      params = { "brq_statuscode" => "999" }
      response_parser = described_class.new(params, secretkey)
      expect(response_parser).not_to be_failure
      expect(response_parser).not_to be_pending
      expect(response_parser).not_to be_success
    end
  end
end
