# frozen_string_literal: true

require "spec_helper"

describe ActiveMerchant::Billing::BuckarooBPE3SimpleSepaDirectDebitGateway, :vcr do
  let(:secretkey) { ENV['BUCKAROO_SECRET_KEY'] }
  let(:websitekey) { ENV['BUCKAROO_WEBSITE_KEY'] }
  let(:gateway) do
    described_class.new(
      secretkey: secretkey,
      websitekey: websitekey,
      sepa_mandate_prefix: "000"
    )
  end

  it "creates a new billing gateway with a required websitekey and secretkey" do
    expect(
      described_class.new(secretkey: "1234", websitekey: "1234", sepa_mandate_prefix: "000")
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
        collectdate: Date.today,
        customeraccountname: "Berend",
        customerbic: "INGBNL2A",
        customeriban: "NL20INGB0001234567",
        description: "Description",
        invoicenumber: "2013-0001",
        mandatedate: Date.today,
        mandatereference: "TEST-000001"
      }
    end

    it "returns with no ArumentErrors with default options" do
      expect { gateway.purchase(amount, nil, options) }.not_to raise_error
    end

    it "raises an ArumentError when money is <= 0" do
      amount = -1

      expect { gateway.purchase(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when collectdate is not a date" do
      options[:collectdate] = "2013-12-16"

      expect { gateway.purchase(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when string length of customeraccountname is more than 40" do
      options[:customeraccountname] = "AAAAABBBBBCCCCCDDDDDAAAAABBBBBCCCCCDDDDDE"

      expect { gateway.purchase(amount, nil, options) }.to raise_error(ArgumentError)
    end

    it "raises an ArumentError when mandatedate is not a date" do
      options[:mandatedate] = "2013-12-16"

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

    it "supports sepa mandate prefix in mandatereference (old situation)" do
      gateway = described_class.new({ secretkey: secretkey, websitekey: websitekey })
      options[:mandatereference] = "000-TEST-000003"
      response = gateway.purchase(amount, nil, options)

      expect(response.post_params).not_to be_nil
      expect(
        response.post_params[:brq_service_simplesepadirectdebit_mandatereference]
      ).to eq("000-TEST-000003")
    end

    it "supports sepa mandate prefix as gateway argument (new situation)" do
      options[:mandatereference] = "TEST-000004"
      response = gateway.purchase(amount, nil, options)

      expect(response.post_params).not_to be_nil
      expect(
        response.post_params[:brq_service_simplesepadirectdebit_mandatereference]
      ).to eq("000-TEST-000004")
    end

    it "creates a new purchase via the Buckaroo API" do
      response = gateway.purchase(amount, nil, options)

      expect(response.response_data).not_to be_empty
      expect(response).to be_success
      expect(response).not_to be_test
      expect(response.statuscode).to eq("791")
      expect(response.amount).to eq(amount.to_s)
      expect(response.invoicenumber).to eq(options[:invoicenumber])
      expect(response.simplesepadirectdebit_collectdate).to eq("2013-12-23")
      expect(response.simplesepadirectdebit_mandatereference).to eq("000-TEST-000001")

      expect(response.post_params).to include(
        brq_amount: amount,
        brq_channel: "CALLCENTER",
        brq_description: options[:description],
        brq_invoicenumber: options[:invoicenumber],
        brq_payment_method: "simplesepadirectdebit",
        brq_service_simplesepadirectdebit_customeraccountname: options[:customeraccountname],
        brq_service_simplesepadirectdebit_customerbic: options[:customerbic],
        brq_service_simplesepadirectdebit_customeriban: options[:customeriban]
      )
    end

    it "supports sending additional variables with request" do
      new_options = options.merge(add_test: "someValue", add_diff: "differentValue")
      response = gateway.purchase(amount, nil, new_options)

      expect(response).to be_success
      expect(response).not_to be_test
      expect(response.statuscode).to eq("791")
      expect(response.additional_variables).to eq(
        "add_test" => new_options[:add_test],
        "add_diff" => new_options[:add_diff]
      )
    end

    it "handles an error with wrong IBAN number the right way" do
      response = gateway.purchase(amount, nil, options)

      expect(response.response_data).not_to be_empty
      expect(response).not_to be_success
      expect(response).not_to be_test
      expect(response.statuscode).to eq("491")
      expect(response.amount).to eq(amount.to_s)
      expect(response.invoicenumber).to eq(options[:invoicenumber])

      expect(response.post_params).not_to be_nil
      expect(
        response.response_params["brq_apierrormessage"]
      ).to eq('Parameter "CustomerIBAN" has wrong value')
    end

    it "still works with empty response" do
      response = gateway.purchase(amount, nil, options)

      expect(response).not_to be_success
      expect(response.statuscode).to be_nil
      expect(response.response_data).to be_empty
    end

    it "still works with crappy response" do
      response = gateway.purchase(amount, nil, options)

      expect(response).not_to be_success
      expect(response.statuscode).to be_nil
      expect(response.response_data).to eq("this is a very nasty response")
    end
  end
end
