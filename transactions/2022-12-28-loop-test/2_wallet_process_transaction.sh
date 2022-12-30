#!/bin/bash
dogecoin-cli walletprocesspsbt `cat 1_transaction.psbt` false | jq .psbt | cut -f 2 -d \"
