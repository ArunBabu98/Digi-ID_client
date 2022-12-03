import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletProvider extends ChangeNotifier {
  String mnemonics = "";

  void setMnemonics(String mnem) {
    mnemonics = mnem;
    notifyListeners();
  }

  String address = "";
  String key = "";

  void setAddressAndKey(String addr, String prvKey) {
    address = addr;
    key = prvKey;
    notifyListeners();
  }

  String scanData = "";

  void setScanData(String data) {
    scanData = data;
    notifyListeners();
  }
}
