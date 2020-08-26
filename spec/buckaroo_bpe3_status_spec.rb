# frozen_string_literal: true

require "spec_helper"

describe ActiveMerchant::Billing::BuckarooBPE3StatusGateway, :vcr do
  let(:secretkey) { ENV['BUCKAROO_SECRET_KEY'] }
  let(:websitekey) { ENV['BUCKAROO_WEBSITE_KEY'] }
  let(:gateway) do
    described_class.new(
      secretkey: secretkey,
      websitekey: websitekey
    )
  end

  it "creates a new billing gateway with a required websitekey and secretkey" do
    expect(
      described_class.new(secretkey: "1234", websitekey: "1234")
    ).to be_kind_of(described_class)
  end

  it "throws an error if a gateway is created without website key" do
    expect { described_class.new(secretkey: "1234") }.to raise_error(ArgumentError)
  end

  it "throws an error if a gateway is created without secret key" do
    expect { described_class.new(websitekey: "1234") }.to raise_error(ArgumentError)
  end

  context "when requesting status for invoice" do
    let(:options) do
      {
        amount_invoice: 10,
        invoicenumber: "2013-0001"
      }
    end

    it "raises an ArumentError when string length of invoicenumber is more than 40" do
      options[:invoicenumber] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

      expect { gateway.status_for_invoicenumber(options) }.to raise_error(ArgumentError)
    end

    it "returns a decent response for a failed direct debit" do
      response = gateway.status_for_invoicenumber(options)

      expect(response).to be_success
      expect(response).not_to be_test
      expect(response).not_to be_status_paid

      expect(response.status_amount_paid).to eq(0)

      expect(response.response_parser).to be_valid
      expect(response.response_data).not_to be_empty
      expect(response.post_params).to include(brq_invoicenumber: options[:invoicenumber])
    end

    it "returns a decent response for a successful direct debit" do
      response = gateway.status_for_invoicenumber(options)

      expect(response).to be_success
      expect(response).not_to be_test
      expect(response).to be_status_paid

      expect(response.status_amount_paid).to eq(10)

      expect(response.response_parser).to be_valid
      expect(response.response_data).not_to be_empty
      expect(response.post_params).to include(brq_invoicenumber: options[:invoicenumber])
    end

    it "returns a decent response for a successful direct debit with reversal" do
      response = gateway.status_for_invoicenumber(options)

      expect(response).to be_success
      expect(response).not_to be_test
      expect(response).not_to be_status_paid

      expect(response.status_amount_paid).to eq(0)

      expect(response.response_parser).to be_valid
      expect(response.response_data).not_to be_empty
      expect(response.post_params).to include(brq_invoicenumber: options[:invoicenumber])
    end

    it "returns a decent response for a successful credit card" do
      response = gateway.status_for_invoicenumber(options)

      expect(response).to be_success
      expect(response).not_to be_test
      expect(response).to be_status_paid

      expect(response.status_amount_paid).to eq(10)

      expect(response.response_parser).to be_valid
      expect(response.response_data).not_to be_empty
      expect(response.post_params).to include(brq_invoicenumber: options[:invoicenumber])
    end

    it "returns a decent response for a failed credit card (old type, bpe2)" do
      response = gateway.status_for_invoicenumber(options)

      expect(response).to be_success
      expect(response).not_to be_test
      expect(response).not_to be_status_paid

      expect(response.status_amount_paid).to eq(0)

      expect(response.response_parser).to be_valid
      expect(response.response_data).not_to be_empty
      expect(response.post_params).to include(brq_invoicenumber: options[:invoicenumber])
    end

    it "returns a decent response for an invoice doesnt exist" do
      response = gateway.status_for_invoicenumber(options)

      expect(response).to be_success
      expect(response).not_to be_test
      expect(response).not_to be_status_paid

      expect(response.status_amount_paid).to eq(0)

      expect(response.response_parser).to be_valid
      expect(response.response_data).not_to be_empty
      expect(response.post_params).to include(brq_invoicenumber: options[:invoicenumber])
    end

    it "still works with empty response" do
      response = gateway.status_for_invoicenumber(options)

      expect(response.response_data).to be_empty
      expect(response).not_to be_success
      expect(response.statuscode).to eq(nil)
    end

    it "still works with crappy response" do
      response = gateway.status_for_invoicenumber(options)

      expect(response.response_data).to eq("this is a very nasty response")
      expect(response).not_to be_success
      expect(response.statuscode).to eq(nil)
    end
  end
end
