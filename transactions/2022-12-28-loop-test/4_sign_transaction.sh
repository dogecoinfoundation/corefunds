#!/bin/bash
dogecoin-cli walletprocesspsbt `cat 2_transaction_unsigned.psbt` | jq .psbt | cut -f 2 -d \"
