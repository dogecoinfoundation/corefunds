# Signing Notes

Writing up my notes on the transaction creation and signing process so they're
readily available to refer to later, and because they may be useful to others.

All of this is tested on an experimental branch of Dogecoin 1.21; the theory is
generally applicable but other tools will have different interfaces.

## Pre-requisites

In order to sign the output transaction, the PSBT needs to include the details
of the input transaction(s). As nodes do not track transactions unless they're
relevant to an address the node is watching, the address the transaction is to
needs to be watched.

This only needs to be done once, as the transaction creator can add these to
the PSBT and then circulate the expanded PSBT.

If this is done before the address receives any funds, you can avoid rescanning,
but as the address now exists the node needs to rescan the blockchain, which
takes around an hour.

I ran the following to add the address:

```shell
$ dogecoin-cli importaddress 9xEP9voiNLw7Y7DS87M8QRqKM43r6r5KM5 "corefunds" true
```

The following will then return a non-empty list:

```shell
$ dogecoin-cli listunspent 1 9999999 "[\"9xEP9voiNLw7Y7DS87M8QRqKM43r6r5KM5\"]"
```

## Creating the transaction

Creating the transaction involves defining its inputs, and the amounts to send.
This generates a very bare PSBT which isn't very useful until it's processed
by a node with a wallet.

The following uses the [createpsbt](https://bitcoincore.org/en/doc/0.17.0/rpc/rawtransactions/createpsbt/)
command to generate a new transaction which consumes input #1 (the second) of
transaction
`169a73cf972fbc1ff9d480474e5de7db03d63c243f4b57d25cdd09ba56ff2738`, which was
10 Dogecoins, and sends 9.9 Dogecoins back to
`9xEP9voiNLw7Y7DS87M8QRqKM43r6r5KM5`. The remaining 0.1 Dogecoins are burnt
as a (somewhat high) transaction fee.

```shell
dogecoin-cli createpsbt "[{\"txid\":\"169a73cf972fbc1ff9d480474e5de7db03d63c243f4b57d25cdd09ba56ff2738\",\"vout\":1}]" "[{\"9xEP9voiNLw7Y7DS87M8QRqKM43r6r5KM5\":9.9}]"
```

This creates the following PSBT, which you'll see as inputs to later examples:

```
cHNidP8BAFMCAAAAATgn/1a6Cd1c0ldLPyQ81gPb511OR4DU+R+8L5fPc5oWAQAAAAD/////AYAzAjsAAAAAF6kUP5EutQN3mspXxZVmYkhcTKkTMK2HAAAAAAAAAA==
```

You can decode the resulting PSBT to check its contents, we'll discuss
this in detail later.

```shell
$ dogecoin-cli decodepsbt cHNidP8BAFMCAAAAATgn/1a6Cd1c0ldLPyQ81gPb511OR4DU+R+8L5fPc5oWAQAAAAD/////AYAzAjsAAAAAF6kUP5EutQN3mspXxZVmYkhcTKkTMK2HAAAAAAAAAA==
```

## Wallet Processing the Transaction

The next step is to add the required details to the PSBT can be signed. For
this we'll use [walletprocesspsbt](https://bitcoincore.org/en/doc/0.17.0/rpc/wallet/walletprocesspsbt/), as below:

```
$ dogecoin-cli walletprocesspsbt cHNidP8BAFMCAAAAATgn/1a6Cd1c0ldLPyQ81gPb511OR4DU+R+8L5fPc5oWAQAAAAD/////AYAzAjsAAAAAF6kUP5EutQN3mspXxZVmYkhcTKkTMK2HAAAAAAAAAA==
```

If the wallet has the address watched correctly, decoding the resulting PSBT
will show it includes the transaction inputs (i.e. pipe it to `| jq .inputs`).

If this is done on a wallet with an available signing key, by default
it will add a signature to the PSBT too. The process I follow involves
a node which does not have the key, and then moving the PSBT to an isolated
machine for signing.

## Signing the Transaction

Signing the transaction is identical to wallet processing, except performed
on a node with one of the signing keys present. It will then update the
PSBT with the signature from that signing key.

Before signing, it's important to `decodepsbt` the PSBT to check what is
being signed. This produces an output such as that below (note this is
trimmed to focus on just the "tx" and "fee"):

```
$ dogecoin-cli decodepsbt <psbt after wallet processing>
{
  "tx": {
    "txid": "e80a06fb189acef79e98ffd86ceea78ff7504e434f4aea0a86c50373327ddd98",
    "hash": "e80a06fb189acef79e98ffd86ceea78ff7504e434f4aea0a86c50373327ddd98",
    "version": 2,
    "size": 83,
    "vsize": 83,
    "weight": 332,
    "locktime": 0,
    "vin": [
      {
        "txid": "169a73cf972fbc1ff9d480474e5de7db03d63c243f4b57d25cdd09ba56ff2738",
        "vout": 1,
        "scriptSig": {
          "asm": "",
          "hex": ""
        },
        "sequence": 4294967295
      }
    ],
    "vout": [
      {
        "value": 9.90000000,
        "n": 0,
        "scriptPubKey": {
          "asm": "OP_HASH160 3f912eb503779aca57c5956662485c4ca91330ad OP_EQUAL",
          "hex": "a9143f912eb503779aca57c5956662485c4ca91330ad87",
          "reqSigs": 1,
          "type": "scripthash",
          "addresses": [
            "9xEP9voiNLw7Y7DS87M8QRqKM43r6r5KM5"
          ]
        }
      }
    ]
  },
  ...
  "fee": 0.10000000
}
```

The "tx" is the transaction being built. Within it, "vin" is the inputs (what
is being spent) and "vout" is the outputs. Here you can see it has a single
output of 9.9 Dogecoins being sent to `9xEP9voiNLw7Y7DS87M8QRqKM43r6r5KM5`.
The fee is then calculated based on the total input value, minus the total
output value, and in this case is 0.1 Dogecoins.

## Finalizing the Transaction

Once you have enough signatures, you can assemble the transaction. Note
"can" does not mean "should" - getting a signature from every signer
is definitely preferable. That said, conventionally only sufficient
signatures to meet the threshold are relayed, so the other signatures
should be kept for audit purposes elsewhere.

Depending how the signing has happened, if each person has passed the
PSBT along to the next in turn, you should be able to call
[finalizepsbt](https://bitcoincore.org/en/doc/0.17.0/rpc/rawtransactions/finalizepsbt/)
directly. Alternatively, if they were signed independently then the
signatures need assembling, [combinepsbt](https://bitcoincore.org/en/doc/0.17.0/rpc/rawtransactions/combinepsbt/)
can put the PSBTs together and return the assembled set ready to pass in to
finalizepsbt.

finalizepsbt returns a fully signed transaction, but does not relay it.
Before relaying, it's a good idea to [decoderawtransaction](https://bitcoincore.org/en/doc/0.17.0/rpc/rawtransactions/decoderawtransaction/)
the transaction to verify it is correct.

## Relaying the Transaction

Once the finalized transaction is verified, it can be relayed with
`sendrawtransaction`, which will relay it to the P2P network for mining.
