module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BuckarooBPE3DirectDebitPurchaseResponse < Response
      
      def post_params
        @params['post_params']
      end
      
      def response_data
        @params['response_data']
      end

      def response_params
        @params['response_params']
      end
      
      def statuscode
        @params['statuscode']
      end

    end
  end
end
