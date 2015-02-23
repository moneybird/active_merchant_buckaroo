# Active Merchant Buckaroo


## Some arguments

Amount is the amount of money you want to charge. If you want to charge EUR 12.34, amount = 12.34 (or big decimal).
To test this gem, use the following code: ActiveMerchant::Billing::Base.mode = :test .


## Payment methods

Currently this gem supports two payment methods, credit cards and SEPA direct debits (simple version).


## Credit cards

### Single credit card payment

To initiate a single credit card payment, use the following code:

```
params = { secretkey: "mysecret", websitekey: "mywebsitekey" }
buckaroo = ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway.new(params)

params = {
  culture:              "EN",
  currency:             "EUR",
  description:          "Description on the receipt of the customer",
  invoicenumber:        "2015-1234",
  payment_method:       "mastercard",
  return:               "https://url/path/to/cancel/and/success/callback",
  startrecurring:       false,
}

response = buckaroo.purchase(amount, nil, params)
```

response in the above code examples is a BuckarooBPE3Response object, see below for more information.

### Recurring credit card payment

If you want to charge a credit card again without having the user to type in his credit card details again, change "startrecurring" to "true" in the above example. Later you can charge the credit card again this way:

```
params = { secretkey: "mysecret", websitekey: "mywebsitekey" }
buckaroo = ActiveMerchant::Billing::BuckarooBPE3CreditCardGateway.new(params)

params = {
  currency:             "EUR",
  description:          "Description on the receipt of the customer",
  invoicenumber:        "2015-1234",
  originaltransaction:  "abcdefgh1234",
  payment_method:       "mastercard",
  return:               "https://url/path/to/cancel/and/success/push",
}

response = buckaroo.recurring(amount, nil, params)
```

response in the above code examples is a BuckarooBPE3Response object, see below for more information.

## SEPA Direct Debit

This is the simple implementation of the SEPA Direct Debit payment method. You don't have to worry about the first (FRST) or recurring (RCUR) transaction, Buckaroo will handle that based on your "mandatedate" and "mandatereference" input.

Use the following code example to initiate a SEPA Direct Debit charge:

```
params = { secretkey: "mysecret", websitekey: "mywebsitekey" }
buckaroo = ActiveMerchant::Billing::BuckarooBPE3SimpleSepaDirectDebitGateway.new(params)

params = {
  collectdate: Date.today,
  customeraccountname: "John Doe",
  customerbic: "INGBNL2A",
  customeriban: "NL99INGB0123456789",
  description: "Description on the receipt of the customer",
  invoicenumber: "2015-1234",
  mandatedate: Date.yesterday,
  mandatereference: "unique reference to this customer in your administration",
}

response = buckaroo.purchase(amount, nil, params)
```
response in the above code examples is a BuckarooBPE3Response object, see below for more information.


## Check status of transaction

When you want to check te status of a previously started transaction, you can use the BuckarooBPE3StatusGateway. Hereby an example:

```
params = { secretkey: "mysecret", websitekey: "mywebsitekey" }
buckaroo = ActiveMerchant::Billing::BuckarooBPE3StatusGateway.new(params)

params = { 
  invoicenumber: "2015-1234", 
  amount_invoice: 12.34,
}

response = buckaroo.status_for_invoicenumber(params)
is_paid = response.status_paid?
```

is_paid is a boolean to check whether the invoice is paid or not. This is based on the amount_invoice you passed on in the above example and the transactions started / connected to this invoice number.


## What if it doesn't work?

More information can be found in the source, for example the BuckarooBPE3Response and BuckarooBPE3ResponseParser class provide a lot of convenience functions. BuckarooBPE3Response is the object returned to you when initiating a call, BuckarooBPE3ResponseParser will be used to parse the returned code from Buckaroo (response to call or push data).
