import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:app/services/provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:bip39/bip39.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:bsv/bsv.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_bitcoin/flutter_bitcoin.dart' as dc;
import 'package:provider/provider.dart';

class DigiID {
  late BuildContext context;
  late String callback;
  late String urlData;
  late Uri URI;
  final HIGHEST_BIT = 0x80000000;
  var variables;

  /// Takes qr code data as parameter.
  DigiID(String data, BuildContext bcontext) {
    context = bcontext;
    urlData = data;
    var uri = Uri.parse(data);
    URI = uri;
    var call = uri.queryParameters['u'] != null ? "http://" : "https://";
    call += uri.host + uri.path;
    Map variab = {};
    uri.queryParameters.forEach((key, value) {
      variab[key] = value;
    });
    callback = call;
    variables = variab;
  }

  /// sends the signed message to callback url and returns the status code
  Future<bool> sendData() async {
    Map<String, String> credentials = await sign();
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'charset': 'UTF-8',
    };
    var uri = Uri.parse(callback.toLowerCase());
    var res = await http.post(uri,
        headers: requestHeaders, body: json.encode(credentials));
    if (res.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// Sign the message to be sent to the callback url.
  sign({int index = 0}) async {
    var buffer = Uint8List(4).buffer;
    var bdata = ByteData.view(buffer);
    bdata.setUint32(0, index, Endian.little);
    var indexbuffer = bdata.buffer.asUint8List();
    List<int> codeUnits = utf8.encode(callback);
    List<int> toHash = List.from(indexbuffer)..addAll(codeUnits);
    var digest = sha256.convert(toHash);
    List<int> digestBytes = digest.bytes;
    List<int> A = digestBytes.sublist(0, 4);
    List<int> B = digestBytes.sublist(4, 8);
    List<int> C = digestBytes.sublist(8, 12);
    List<int> D = digestBytes.sublist(12, 16);
    String mnem = Provider.of<WalletProvider>(context, listen: false).mnemonics;
    Uint8List seed = mnemonicToSeed(mnem);
    ByteData ba = ByteData.sublistView(A as Uint8List);
    var a = ba.getUint32(0, Endian.little);
    ByteData bb = ByteData.sublistView(B as Uint8List);
    var b = bb.getUint32(0, Endian.little);
    ByteData bc = ByteData.sublistView(C as Uint8List);
    var c = bc.getUint32(0, Endian.little);
    ByteData bd = ByteData.sublistView(D as Uint8List);
    var d = bd.getUint32(0, Endian.little);
    int m = a >= HIGHEST_BIT ? a - HIGHEST_BIT : a;
    int n = b >= HIGHEST_BIT ? b - HIGHEST_BIT : b;
    int o = c >= HIGHEST_BIT ? c - HIGHEST_BIT : c;
    int p = d >= HIGHEST_BIT ? d - HIGHEST_BIT : d;
    dc.NetworkType digi = dc.NetworkType(
        messagePrefix: 'DigiByte Signed Message:\n',
        bech32: 'dgb',
        bip32: dc.Bip32Type(public: 0x049d7cb2, private: 0x049d7878),
        pubKeyHash: 0x1e,
        scriptHash: 0x3F,
        wif: 0x80);
    dc.HDWallet wallet = dc.HDWallet.fromSeed(seed, network: digi);
    dc.HDWallet child2 = wallet.derivePath("m/13'/${m}'/${n}'/${o}'/${p}'");
    String address = child2.address!;
    var hash2 = magicHash(urlData.toLowerCase(), digi);
    Sig sig = ecdsaSign(hash2, child2.wif, child2);
    var signature = base64Encode(sig.toCompact());

    Map<String, String> result = {
      "uri": URI.toString(),
      "address": address,
      "signature": signature,
    };
    return result;
  }

  /// elliptic curve signing algorithm
  ecdsaSign(hash, wif, dc.HDWallet child) {
    PrivKey key = PrivKey.fromWif(wif);
    KeyPair pair = KeyPair.fromPrivKey(key);
    var ecdsa = Ecdsa();
    ecdsa.hashBuf = hash;
    ecdsa.keyPair = pair;
    ecdsa.signRandomK();
    ecdsa.calcrecovery();
    ecdsa.endian = Endian.little;
    var signature = ecdsa.sig!;
    return signature;
  }

  /// claculation of magichash
  Uint8List magicHash(String message, dc.NetworkType network) {
    var magicBytes =
        Uint8List.fromList(utf8.encode('DigiByte Signed Message:\n'));
    var prefix1 = encode(magicBytes.length);
    var messageBuffer = Uint8List.fromList(utf8.encode(message));
    var prefix2 = encode(messageBuffer.length);
    var buf = BytesBuilder();
    buf.add(prefix1);
    buf.add(magicBytes);
    buf.add(prefix2);
    buf.add(messageBuffer);
    return hash256(buf.toBytes());
  }

  Uint8List hash256(Uint8List buffer) {
    Uint8List _tmp = SHA256Digest().process(buffer);
    return SHA256Digest().process(_tmp);
  }

  int encodingLength(int number) {
    if (!isUint(number, 53)) throw ArgumentError('Expected UInt53');
    return (number < 0xfd
        ? 1
        : number <= 0xffff
            ? 3
            : number <= 0xffffffff
                ? 5
                : 9);
  }

  bool isUint(int value, int bit) {
    return (value >= 0 && value <= pow(2, bit) - 1);
  }

  Uint8List encode(int number, [Uint8List? buffer, int? offset]) {
    if (!isUint(number, 53)) ;

    buffer = buffer ?? Uint8List(encodingLength(number));
    offset = offset ?? 0;
    var bytes = buffer.buffer.asByteData();
    // 8 bit
    if (number < 0xfd) {
      bytes.setUint8(offset, number);
      // 16 bit
    } else if (number <= 0xffff) {
      bytes.setUint8(offset, 0xfd);
      bytes.setUint16(offset + 1, number, Endian.little);

      // 32 bit
    } else if (number <= 0xffffffff) {
      bytes.setUint8(offset, 0xfe);
      bytes.setUint32(offset + 1, number, Endian.little);

      // 64 bit
    } else {
      bytes.setUint8(offset, 0xff);
      bytes.setUint32(offset + 1, number, Endian.little);
      bytes.setUint32(offset + 5, (number ~/ 0x100000000) | 0, Endian.little);
    }

    return buffer;
  }
}
