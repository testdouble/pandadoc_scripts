# PandaDoc Scripts

## Install

You'll need a working Ruby environment on your machine (I use
[rbenv](https://github.com/rbenv/rbenv) to manage mine). From there:

```
$ bundle
```

You'll be asked for your PandaDoc access token, which you can create in the
[integraions tab](https://app.pandadoc.com/a/#/settings/integrations/) of your
account settings.

## Detect partially-signed documents

It's hard to get a notification from PandaDoc when a customer/external recipient
signs a document, which can result in forgetting to sign it yourself. This
script will review all your outstanding documents to identify ones where
external recipients have signed but not all internal recipients have yet.

```
$ ./script/detect_partially_signed_documents
```

It will ask for your PandaDoc API Key (and then save it in your keychain
for subsequent runs), as well as your company's e-mail domain (to separate
internal signers and external recipients).

If any documents need to be signed by internal signers, the script output
will look like this:

```
$ ./script/detect_partially_signed_documents --internal-domain testdouble.com
-> Fetching details on 15 unsigned documents
-> API request throttled, waiting 54 seconds
-> Warning: Document "NDA - FAKE TESTING ONLY"
     has been signed by recipient(s) searls@example.com,
     but has NOT been signed by firstname.lastname@testdouble.com

   Document URL:
   https://app.pandadoc.com/a/#/documents/asodjsado908
```

The script can also be run non-interactively with command line options like this:

```
$ ./script/detect_partially_signed_documents --api-key abcdef1234 --internal-domain testdouble.com
```

You can see available command-line options with the `--help` option:
