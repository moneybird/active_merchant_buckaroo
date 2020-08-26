# frozen_string_literal: true

require "spec_helper"

describe ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway, :vcr do
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

  context "when setup purchase" do
    let(:amount) { 1.23 }
    let(:options) do
      {
        culture: "EN",
        currency: "EUR",
        description: "Description",
        invoicenumber: "2013-0001",
        payment_method: "mastercard",
        return: "http://localhost/returnurl"
      }
    end

    it "raises an ArumentError when culture is not DE, EN or NL" do
      options[:culture] = "FR"

      expect { gateway.purchase(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when currency is not EUR, GBP or USD" do
      options[:currency] = "MYCURR"

      expect { gateway.purchase(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when string length of description is more than 40" do
      options[:description] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

      expect { gateway.purchase(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when string length of invoicenumber is more than 40" do
      options[:invoicenumber] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

      expect { gateway.purchase(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when string payment_method is not equal to mastercard or visa" do
      options[:payment_method] = "myowncreditcard"

      expect { gateway.purchase(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "also works with visa cards" do
      options[:payment_method] = "visa"

      response = gateway.purchase(amount, nil, options)
      expect(response.post_params[:brq_payment_method]).to eq("visa")
    end

    it "creates a new purchase via the Buckaroo API" do
      response = gateway.purchase(amount, nil, options)

      expect(response.invoicenumber).to eq(options[:invoicenumber])
      expect(response.redirecturl).to eq("https://checkout.buckaroo.nl/html/redirect.ashx?r=21DF69234D3246209C80AD0E43075CDB")
      expect(response).to be_success
      expect(response.statuscode).to eq("790")
      expect(response).not_to be_test

      expect(response.response_data).not_to be_empty
      expect(response.amount).to eq(amount.to_s)

      expect(response.post_params).to include(
        brq_amount: amount,
        brq_culture: options[:culture],
        brq_currency: options[:currency],
        brq_description: options[:description],
        brq_invoicenumber: options[:invoicenumber],
        brq_payment_method: options[:payment_method],
        brq_return: options[:return]
      )
    end

    it "still works with empty response" do
      response = gateway.purchase(amount, nil, options)

      expect(response.response_data).to be_empty
      expect(response.success?).to be(false)
      expect(response.statuscode).to be_nil
    end

    it "still works with crappy response" do
      response = gateway.purchase(amount, nil, options)

      expect(response.response_data).to eq('this is a very nasty response')
      expect(response.success?).to be(false)
      expect(response.statuscode).to be_nil
    end
  end

  context "when setup recurring" do
    let(:amount) { 1.23 }
    let(:options) do
      {
        currency: "EUR",
        description: "Description",
        invoicenumber: "2013-0001",
        originaltransaction: "AAAABBBB",
        payment_method: "mastercard"
      }
    end

    it "raises an ArumentError when currency is not EUR, GBP or USD" do
      options[:currency] = "MYCURR"

      expect { gateway.recurring(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when string length of description is more than 40" do
      options[:description] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

      expect { gateway.recurring(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when string length of invoicenumber is more than 40" do
      options[:invoicenumber] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

      expect { gateway.recurring(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when string originaltransaction is not present" do
      options.except!(:originaltransaction)

      expect { gateway.recurring(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when string payment_method is not equal to mastercard or visa" do
      options[:payment_method] = "myowncreditcard"

      expect { gateway.recurring(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "also works with visa cards" do
      options[:payment_method] = "visa"

      response = gateway.recurring(amount, nil, options)
      expect(response.post_params[:brq_payment_method]).to eq("visa")
    end

    it "creates a new recurring via the Buckaroo API" do
      response = gateway.recurring(amount, nil, options)

      expect(response.invoicenumber).to eq(options[:invoicenumber])
      expect(response).to be_success
      expect(response.statuscode).to eq("190")
      expect(response).not_to be_test

      expect(response.response_data).not_to be_empty
      expect(response.amount).to eq(amount.to_s)

      expect(response.post_params).to include(
        brq_amount: amount,
        brq_currency: options[:currency],
        brq_description: options[:description],
        brq_invoicenumber: options[:invoicenumber],
        brq_originaltransaction: options[:originaltransaction],
        brq_payment_method: options[:payment_method]
      )
    end

    it "still works with empty response" do
      response = gateway.recurring(amount, nil, options)

      expect(response.response_data).to be_empty
      expect(response.success?).to be(false)
      expect(response.statuscode).to be_nil
    end

    it "still works with crappy response" do
      response = gateway.recurring(amount, nil, options)

      expect(response.response_data).to eq('this is a very nasty response')
      expect(response.success?).to be(false)
      expect(response.statuscode).to be_nil
    end
  end
end
