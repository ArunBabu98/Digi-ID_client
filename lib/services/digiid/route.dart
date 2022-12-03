import 'package:app/services/digiid/digiid.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DigiRouter {
  late BuildContext context;
  DigiRouter(BuildContext bcontext) {
    context = bcontext;
  }
  route(String data) async {
    var uri = Uri.parse(data);
    if (uri.scheme == "digiid") {
      bool result = await DigiID(data, context).sendData();
      if (result == true) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }
}
