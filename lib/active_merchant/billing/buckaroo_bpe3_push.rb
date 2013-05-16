module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BuckarooBPE3Push

      def initialize(params, secretkey)
        @params = params
        @secretkey = secretkey
      end

      def amount
        @params['brq_amount']
      end

      def currency
        @params['brq_currency']
      end

      def invoicenumber
        @params['brq_invoicenumber']
      end

      def mutationtype
        @params['brq_mutationtype']
      end

      def statuscode
        @params['brq_statuscode']
      end

      def statusmessage
        @params['brq_statusmessage']
      end

      def signature
        @params['brq_signature']
      end

      def test
        @params['brq_test']
      end

      def timestamp
        @params['brq_timestamp']
      end

      def transaction_method
        @params['brq_transaction_method']
      end

      def transaction_type
        @params['brq_transaction_type']
      end

      def transactions
        @params['brq_transactions']
      end


      def directdebit?
        #@params['brq_transaction_method'] == "directdebit"
        @params['brq_transaction_type'].upcase == "C002"
      end

      def directdebitrecurring?
        #@params['brq_transaction_method'] == "directdebitrecurring"
        @params['brq_transaction_type'].upcase == "C003"
      end

      def failure?
        [ "490", "491", "492", "890" ].include?(statuscode)
      end

      def pending?
        statuscode == "791"
      end

      def reversal?
        @params['brq_transaction_type'].upcase == "C562"
      end

      def success?
        statuscode == "190"
      end

      def test?
        @params['brq_test'] == "true"
      end

      def valid?
        ActiveMerchant::Billing::BuckarooBPE3Toolbox.check_signature(@params.dup, @secretkey)
      end

    end

  end

end
