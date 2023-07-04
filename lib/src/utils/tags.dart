// FIXME: replace by common library

class HfTag {
  String uid;

  HfTag(this.uid);

  @override
  String toString() {
    return uid;
  }
}

class UhfTag {
  String epc;
  String tid;
  int rssi;

  UhfTag(this.epc, this.tid, this.rssi);

  @override
  String toString() {
    return "[EPC=$epc,TID=$tid,RSSI=$rssi]";
  }
}
