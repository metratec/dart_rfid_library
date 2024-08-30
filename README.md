# Dart RFID Lib

The purpose of this library is to provide simpler access to Metratec Readers for Dart/Flutter applications.

## Design principle

At lowest level there is the Reader class. It just has a Parser class as member.
The parser manages the low level communication interface and implements the
gen1/gen2 protocol parsing. There are two parser implementations: The ParserAscii (gen1)
and the ParserAt (gen2). The Reader class gives access to the selected parsers functions
`sendCommand()`, `registerEvent()`, `connect()` and `disconnect()`. The reader class itself
is abstract, so it cant be instantiated directly. The Reader is extended by the reader classes
for HF and UHF readers.

### HF Reader

The abstract HfReader class extends the Reader class. It defines all functions that are supported
by HfReaders (even if they are not available on all HfReaders). The class itself is abstract to be
able to distinguish between gen1/gen2 products. The implementation of the functions is done in the
HfReaderGen1/HfReaderGen2 classes, which implement the functions for the according protocol. The parser
is selected at this level. Functions that every reader supports should be implemented at this level.
More specific functions need to be implemented here too but should throw a unimplemented exception.
These functions should be implemented by a class extending the ReaderGen1/HfReaderGen2 reader.

Supported readers are:

* DeskID NFC

### UHF Reader

The UhfReader class follows the same design principle as the HfReader class. Additionally it takes a UhfReaderSettings
class as argument to define different settings among the readers, e.g. power levels. This class is set
by the specific reader implementations. See ReaderQrg2 for example.

Supported readers are:

* PulsarLR
* PulsarFL
* DwarfG2 v2 Family (Mini, Standard, XR)
* QRG2 ETSI and FCC
* DeskID UHF v2 ETSI and FCC

### Examples

The example directory contains examples for HF/UHF readers.
