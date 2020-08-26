# frozen_string_literal: true

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

      def additional_variables
        response_parser.additional_variables
      end

      def simplesepadirectdebit_collectdate
        response_parser.simplesepadirectdebit_collectdate
      end

      def simplesepadirectdebit_mandatereference
        response_parser.simplesepadirectdebit_mandatereference
      end

      def simplesepadirectdebit_reasoncode
        response_parser.simplesepadirectdebit_reasoncode
      end

      def simplesepadirectdebit_reasontext
        response_parser.simplesepadirectdebit_reasontext
      end

      def transactions
        response_parser.transactions
      end

      def amount
        response_parser.amount
      end

      def bic
        response_parser.bic
      end

      def iban
        response_parser.iban
      end

      def iban_converter_success?
        response_parser.iban_converter_success?
      end

      def invoicenumber
        response_parser.invoicenumber
      end

      def redirecturl
        response_parser.redirecturl
      end

      def relatedtransaction_reversal
        response_parser.relatedtransaction_reversal
      end

      def statuscode
        response_parser.statuscode
      end

      def test?
        response_parser.test?
      end

      # bpe3 status
      def status_amount_credit
        amount = BigDecimal("0")
        1.upto(99) do |i|
          str = format("brq_invoice_1_transactions_%<index>d_amountcredit", index: i)
          amount += BigDecimal(response_params[str]) if response_params[str]
        end
        amount
      end

      def status_amount_debit
        amount = BigDecimal("0")
        1.upto(99) do |i|
          str1 = format("brq_invoice_1_transactions_%<index>d_amountdebit", index: i)
          str2 = format("brq_invoice_1_transactions_%<index>d_status_success", index: i)
          if response_params[str1] && response_params[str2] && response_params[str2].casecmp("true").zero?
            amount += BigDecimal(response_params[str1])
          end
        end
        amount
      end

      def status_amount_invoice
        BigDecimal(@params["amount_invoice"].to_s)
      end

      def status_amount_paid
        (status_amount_debit - status_amount_credit)
      end

      def status_paid?
        status_amount_paid == status_amount_invoice
      end
    end
  end
end
