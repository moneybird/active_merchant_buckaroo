module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BuckarooBPE3Response < Response
      
      def post_data
        @params["post_data"]
      end
      
      def post_params
        @params["post_params"]
      end
      
      def response_parser
        @params["response_parser"]
      end

      def response_data
        response_parser.response_data
      end

      def response_params
        response_parser.response_params
      end


      def amount
        response_parser.amount
      end

      def invoicenumber
        response_parser.invoicenumber
      end
      
      def redirecturl
        response_parser.redirecturl
      end
      
      def statuscode
        response_parser.statuscode
      end

      def test?
        response_parser.test?
      end

    end

  end

end
