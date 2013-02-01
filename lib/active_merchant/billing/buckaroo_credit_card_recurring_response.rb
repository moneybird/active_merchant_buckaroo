module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BuckarooCreditCardRecurringResponse < Response
      
      def xml_received
        @params['xml_received']
      end
      
      def xml_sent
        @params['xml_sent']
      end
      
      def response_status
        @params['response_status']
      end      

    end
  end
end
