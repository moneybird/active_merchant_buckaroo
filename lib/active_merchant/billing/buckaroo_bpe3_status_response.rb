module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BuckarooBPE3StatusResponse < Response
      
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


      def test?
        response_params['BRQ_TEST'] == "true"
      end

    end
  end
end
