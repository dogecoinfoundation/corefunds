This document is intended to provide a framework for the keyholders for a 3/5
multisig address to individually and collectively verify the integrity of the
address. There are five key steps to this:

1. Ensure all parties have access to every other party's GPG keys. Ideally
   these have been shared in advance, however I'm aware in some cases they may
   have not.
2. Create a new public/private key pair.
3. Sign the new public key with your GPG key, and distribute the signed key to
   the others.
4. Verify the public keys of the other keyholders, using their GPG keys.
5. Assemble the keys into an address, and sign the address to confirm its
   validity.

At the end, 5 keyholders should each have recreated the same multisig address
from 5 public keys. These signatures will then be published to given the
community a way to validate the address.

## 1: Publish GPG Keys

Please ensure your GPG key is published on your GitHub profile. You can add
this under https://github.com/settings/keys . Alternatively you can upload
your key to https://github.com/dogecoin/dogecoin/tree/1.14.7-dev/contrib/gitian-keys

## 2: Create Dogecoin Key Pair

This guide uses Dogecoin Core for key generation. You are of course welcome to
use other tools, however as we understand the process for Dogecoin Core, and
have validated multisig transaction preparation and signing processes based
around Dogecoin Core, it is highly recommended.

Run the “getnewaddress” command  to generate a new single-key address:

```shell
$ dogecoin-cli getnewaddress
```

Then use “validateaddress” (or "getaddressinfo" on 1.21) to extract the
public key from the newly generated address:

```shell
$ dogecoin-cli validateaddress <address>
```

You should get an output like:

```
{
  "isvalid": true,
  "address": "D5GhCoTsCirLSCWN7YCMHzWH3djCtAv6eB",
  "scriptPubKey": "76a914016fd925f47ef94eec9b598d5622156a51ee76e988ac",
  "ismine": true,
  "iswatchonly": false,
  "isscript": false,
  "pubkey": "023e4dd516c1b3d05740e482578ad35c7026ae861ffa6630ad782ae92cf6267a7f",
  "iscompressed": true,
  "account": "Core Funds",
  "timestamp": 1671820051,
  "hdkeypath": "m/0'/3'/1'",
  "hdmasterkeyid": "2552dd0e0c3fc4016a38f0c6307cce8623fa2c30"
}
```

The critical part is "pubkey", however please provide the full output.

## 3: Sign Dogecoin Key Pair

Put the public key from step 2 into a text file, and add text to describe its
intended use, so it's clear what you are signing. This avoids any risk of a
previously signed public key being substituted.

Sign the key with a command such as:

```shell
$ gpg --clearsign <username>.txt
```

This will create a file called .txt.asc, which you can now add to the pull
request. Raise the pull request against
https://github.com/dogecoinfoundation/corefunds with your signed public key.

## 4: Verify Others Keys

Verify the Dogecoin keys of the other keyholders once they're added to the
repository. You can download the other keyholder's GPG keys from their GitHub
profile or the Dogecoin Core repository. Let the other keyholders know if there
are any anomalies at this point.

## 5: Generate Multisig Address

Take all of the keys and create a multisignature address. Multisignature address
creation is deterministic if keys ordering is defined, so sort the keys to
generate the address.

The command to make an address is “createmultisig” followed by the number of
required keys, followed by the keys, so the command should look like:

```shell
$ cat <publickeys> | sort | xargs dogecoin-cli createmultisig 3
```

Copy the command you used, along with the full output from the command and the
following text into a new text file:

"I have verified the 5 keys used to create this address and confirm that to the
best of my knowledge they belong to the correct keyholders for the 3/5
multisignature address. I have created the multisignature address below using
these keys."

Sign the text file and raise a pull request to add a copy to
https://github.com/dogecoinfoundation/corefunds.
