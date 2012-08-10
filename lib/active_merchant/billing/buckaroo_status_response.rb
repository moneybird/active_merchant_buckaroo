module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class BuckarooStatusResponse < Response
      
      def xml_received
        @params['xml_received']
      end
      
      def xml_sent
        @params['xml_sent']
      end
      
      def status
        @params['status']
      end      
    end
  end
end
