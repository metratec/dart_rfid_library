<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

The purpose of this library is to provide simpler access to Metratec Readers.

## Design principle

At lowest level there is the BaseReader class. It manages the low level communication interface
and dispatches received data to the protocol abstractions. The protocol abstractions are implemented
by the AtReader class and by the, not yet implemented, AsciiReader class.

### BaseReader

The base reader takes care of connecting to the communication interface and reading/writing it. It also provides a stream
for continuous inventories. More specific functionalities are
implemented by the protocol specific reader implementations.
The functions `write()` and `handleRxData()` should never be
called from a user application. The BaseReader is abstract
so it can never be instantiated as a entity on its own.

### AtReader

The AtReader extends the BaseReader and implements a 
command queue that is able to send AtCommands and handle
responses. Furthermore URCs can be registered at the reader
to handle events that can be sent from the reader at any time. 
It is used as a parer for any AT based products.
The only functions that are needed to send AtCommands and
handle URCs are `sendAtCommand()` abd `registerUrc()`.

`sendAtCommand()` takes a command to send, a timeout and
a list of possible responses to the command. A `AtRsp`
takes a prefix to match in the response and a callback that
is called with the received data. A command is considered
complete if either a `OK` or `ERROR` is received or a timeout
occurred. On a timeout all pending commands in the queue
will be terminated. `sendAtCommand()` takes a list of possible
responses since there are some commands that have multiple
responses that do not match the command sent e.g. `ATI`.

`registerUrc()` takes a `AtUrc` as argument. It consists
of a prefix to match and a data callback.

The AtReader itself is also an abstract class. All At based
products should use the `AtReaderCommon` class as base. It
implements At commands that are common between all At based
products. Take inspiration from the implementation of common
commands to add your own reader.

### AsciiReader

TODO: implement

### Examples

The example directory contains a example that demonstrates
a write/read with a Mifare Classic card. Furthermore a
continuous inventory is demonstrated.
