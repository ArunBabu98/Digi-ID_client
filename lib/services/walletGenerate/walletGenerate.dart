import 'package:app/services/provider/provider.dart';
import 'package:flutter_bitcoin/flutter_bitcoin.dart' as bit;
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class GenerateWallet {
  generate(BuildContext context) {
    var mnemonic = bip39.generateMnemonic();
    Provider.of<WalletProvider>(context, listen: false).setMnemonics(mnemonic);
    var seed = bip39.mnemonicToSeed(mnemonic);
    bit.NetworkType network = bit.NetworkType(
        messagePrefix: '\x18DigiByte Signed Message:\n',
        bech32: 'dgb',
        bip32: bit.Bip32Type(public: 0x049d7cb2, private: 0x049d7878),
        pubKeyHash: 0x1e,
        scriptHash: 0x3F,
        wif: 0x80);
    var hdWallet = bit.HDWallet.fromSeed(seed, network: network);
    var zero_index = hdWallet.derivePath("m/44'/20'/0'/0/0");
    Provider.of<WalletProvider>(context, listen: false)
        .setAddressAndKey(zero_index.address!, zero_index.base58Priv!);
  }
}
