module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BuckarooBPE3ResponseParser

      def initialize(response_data, secretkey)
        if response_data.kind_of?(String)
          @response_data = response_data
          @response_params = Rack::Utils.parse_query(response_data)
        elsif response_data.kind_of?(Hash)
          @response_data = ""
          @response_params = response_data
        end
        @signature_valid = ActiveMerchant::Billing::BuckarooBPE3Toolbox.check_signature(@response_params, secretkey)
        # make sure all string keys in hash are downcase
        @response_params = ActiveMerchant::Billing::BuckarooBPE3Toolbox.hash_to_downcase_keys(@response_params)
      end

      def response_data
        @response_data
      end

      def response_params
        @response_params
      end


      def amount
        response_params["brq_amount"] || (-1 * BigDecimal(response_params["brq_amount_credit"])).to_s
      end

      def apiresult
        response_params["brq_apiresult"] || ""
      end

      def bic
        response_params["brq_bic"]
      end

      def cardnumberending
        response_params["brq_service_mastercard_cardnumberending"] || response_params["brq_service_visa_cardnumberending"]
      end

      def currency
        response_params["brq_currency"]
      end

      def error
        response_params["brq_error"] || ""
      end

      def iban
        response_params["brq_iban"]
      end

      def invoicenumber
        response_params["brq_invoicenumber"]
      end

      # Part of the PUSH
      def mutationtype
        response_params["brq_mutationtype"]
      end

      def payment_method
        response_params["brq_payment_method"] || ""
      end

      def redirecturl
        response_params["brq_redirecturl"]
      end

      def brq_relatedtransaction_refund
        response_params["brq_relatedtransaction_refund"]
      end

      def relatedtransaction_reversal
        response_params["brq_relatedtransaction_reversal"]
      end

      def signature
        response_params["brq_signature"]
      end

      def simplesepadirectdebit_collectdate
        response_params["brq_service_simplesepadirectdebit_collectdate"]
      end

      def simplesepadirectdebit_mandatereference
        response_params["brq_service_simplesepadirectdebit_mandatereference"]
      end

      def simplesepadirectdebit_reasoncode
        response_params["brq_service_simplesepadirectdebit_reasoncode"]
      end

      def simplesepadirectdebit_reasontext
        response_params["brq_service_simplesepadirectdebit_reasonexplanation"]
      end

      def statuscode
        response_params["brq_statuscode"]
      end

      def statusmessage
        response_params["brq_statusmessage"]
      end

      def test
        response_params["brq_test"] || ""
      end

      def timestamp
        response_params["brq_timestamp"]
      end

      def transaction_method
        response_params["brq_transaction_method"] || ""
      end

      def transaction_type
        response_params["brq_transaction_type"] || ""
      end

      def transactions
        response_params["brq_transactions"]
      end


      def apiresult_success?
        apiresult.downcase == "success"
      end

      def creditcard?
        mastercard? or visa?
      end

      def directdebit?
        # Only for BuckarooBPE3Push, not for BuckarooBPE3Response
        transaction_type.upcase == "C002"
      end

      def directdebitrecurring?
        # Only for BuckarooBPE3Push, not for BuckarooBPE3Response
        transaction_type.upcase == "C003"
      end

      def failure?
        [ "490", "491", "492", "690", "890", "891" ].include?(statuscode)
      end

      def iban_converter_success?
        error.blank?
      end

      def mastercard?
        transaction_type.upcase == "V043"
      end

      def pending?
        [ "790", "791", "792", "793" ].include?(statuscode)
      end

      def reversal?
        # Only for BuckarooBPE3Push, not for BuckarooBPE3Response
        # C501 for simplesepadirectdebit storno
        # C502 for simplesepadirectdebit reject
        # C562 is for directdebit
        ["C501", "C502", "C562"].include?(transaction_type.upcase)
      end

      def signature_valid?
        @signature_valid
      end

      def simplesepadirectdebit?
        transaction_type.upcase == "C008"
      end

      def success?
        statuscode == "190"
      end

      def test?
        test.downcase == "true"
      end

      def transfer?
        transaction_type.upcase == "C001" || transaction_type.upcase == "C101"
      end

      def valid?
        @signature_valid
      end

      def visa?
        transaction_type.upcase == "V044"
      end

    end

  end

end
