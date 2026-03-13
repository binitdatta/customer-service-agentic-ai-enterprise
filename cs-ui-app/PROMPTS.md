``` 
Create a new order for customer 1. Ship to 420 N LG Ave, Chicago, IL 60623 US. Items: SKU-RED-MUG x1, SKU-BLK-TSHIRT-M x2
```

8) Full cs-ui-app test prompt suite (copy/paste)

Below are realistic prompts to validate end-to-end: NL → extraction → clarify (if needed) → tool calls → final response.

A) Order creation

“Create a new order for customer 1. Ship to 1200 S Michigan Ave, Chicago, IL 60605 US. Items: SKU-RED-MUG x1, SKU-BLK-TSHIRT-M x3.”

“New order for customer 2, ship to 10 Main St, Naperville, IL 60540 US. SKU-RED-MUG x1, SKU-BLK-TSHIRT-M x1.”

``` 
DEBUG STATE: {
  "intent": "order_create",
  "entities": {
    "customer_id": 2,
    "lines": [
      {
        "sku": "SKU-RED-MUG",
        "qty": 1
      },
      {
        "sku": "SKU-BLK-TSHIRT-M",
        "qty": 1
      }
    ],
    "ship_to": {
      "line1": "10 Main St",
      "city": "Naperville",
      "region": "IL",
      "postal_code": "60540",
      "country": "US"
    },
    "ship_to_address_id": 10
  },
  "errors": [],
  "debug": {
    "extraction": {
      "intent": "order_create",
      "entities": {
        "customer_id": 2,
        "lines": [
          {
            "sku": "SKU-RED-MUG",
            "qty": 1
          },
          {
            "sku": "SKU-BLK-TSHIRT-M",
            "qty": 1
          }
        ],
        "ship_to": {
          "line1": "10 Main St",
          "city": "Naperville",
          "region": "IL",
          "postal_code": "60540",
          "country": "US"
        },
        "ship_to_address_id": 10
      }
    },
    "address_resolve": {
      "request_ship_to": {
        "line1": "10 Main St",
        "city": "Naperville",
        "region": "IL",
        "postal_code": "60540",
        "country": "US"
      },
      "raw_response": {
        "address_id": 10,
        "created": true,
        "raw": {
          "data": {
            "address_id": 10,
            "created": true
          }
        }
      },
      "extracted_address_id": 10
    }
  }
}

```

“Create an order. Customer 2. Ship to 1 Apple Park Way, Cupertino, CA 95014 US. SKU-BLK-TSHIRT-M qty 1.”

“Create order for customer 2. Ship to 200 W Adams St, Chicago, IL 60606 US. SKU-RED-MUG x4.”

"Order for customer 1, ship to 500 W Madison St Suite 1000, Chicago IL 60661. SKU-RED-MUG x2."

"New order customer 1. SKU-RED-MUG x1 SKU-BLK-TSHIRT-M x2. Ship to 401 N Michigan Ave Chicago IL 60611."

Creation clarifier tests
5. “Create a new order for customer 1001.” (should ask for ship-to + line items)
6. “Create an order shipping to 1200 S Michigan Ave, Chicago, IL 60605 US.” (should ask customer + line items)
7. “Create an order for customer 1001 with SKU-AAA.” (should ask qty and ship-to)

B) Order lookup

“Lookup order #88421.”

“Show me order 90014.”

“Find 88421.”

“Get order number: 88421.”

Lookup clarifier
12. “Can you lookup my order?” (should ask for order number)

C) Status update (explicit action)

“Update status of order #88421 to SHIPPED. Source OPS_TOOL. Notes: manual correction.”

“Set order 88421 to DELIVERED. Source DRIVER_APP.”

“Change order #90014 status to CANCELLED. Source SUPPORT_AGENT. Notes: customer requested cancellation.”

Status clarifier tests
16. “Update status for order #88421.” (should ask new status + source)
17. “Set it to SHIPPED.” (if session has prior order, use it; otherwise ask order number)

D) Shipping address update

“Change shipping address on order #88421 to 1200 S Michigan Ave, Chicago, IL 60605 US.”

“Update address for order 88421: ship to 10 Main St, Naperville, IL 60540 US.”

“Order #90014 shipped to wrong place—update ship to 200 W Adams St, Chicago, IL 60606 US.”

Address clarifier tests
21. “Update shipping address for order #88421.” (ask for new address)
22. “Ship it to 10 Main St, Naperville, IL 60540.” (ask order number)

E) Cancellation

“Cancel order #88421. Reason: customer request. Notes: changed mind.”

“Please cancel order 90014. Reason: duplicate order.”

“Cancel #88421 due to payment issue.”

Cancel clarifier tests
26. “Cancel my order #88421.” (ask reason if you enforce it)
27. “Cancel my order.” (ask order number + reason)

F) Replacement (wrong delivery / replacement request)

“My order #88421 was delivered to the wrong address. I want a replacement shipped overnight.”

“Replace order 88421. Replacement order number 88421-R1. Ship speed EXPEDITED.”

“I never received order #90014. Please send a replacement. Replacement order number 90014-R1.”

Replacement clarifier tests
31. “I need a replacement for order #88421.” (ask replacement order number + ship speed)
32. “My order was delivered to the wrong address.” (ask order number)

G) Timeline

“Show me the timeline for order #88421.”

“Order 90014 history / events please.”

H) Orders grid

“List recent orders.”

“Search orders with ‘884’.”

“Show orders with status SHIPPED.”

“Show up to 10 orders with status CREATED matching ‘CUST-1001’.”