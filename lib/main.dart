import 'package:app/services/walletGenerate/walletGenerate.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'services/digiid/route.dart';
import 'services/provider/provider.dart';

void main() {
  runApp((MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => WalletProvider()),
    ],
    child: const MyApp(),
  )));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digi-ID Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Digi-ID Scanner Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // checkQrData();
  }

  // checkQrData() {
  //   if (Provider.of<WalletProvider>(context, listen: false).scanData != "") {
  //     DigiRouter(context)
  //         .route(Provider.of<WalletProvider>(context, listen: false).scanData);
  //   }
  // }

  generateWallet() {
    GenerateWallet().generate(context);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: 50),
              child:
                  Provider.of<WalletProvider>(context, listen: false).address ==
                          ""
                      ? Text("Wallet Offline",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600))
                      : Text("Wallet Online",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w600)),
            ),
            Text(
              'Scan Digi-Id',
              style: Theme.of(context).textTheme.headline2,
            ),
            Container(
              margin: EdgeInsets.only(top: 50),
              height: 50,
              child: Provider.of<WalletProvider>(context, listen: false)
                          .address ==
                      ""
                  ? Text("Wallet Not Generated",
                      style: TextStyle(color: Colors.redAccent, fontSize: 25))
                  : Text(
                      'Address: ${Provider.of<WalletProvider>(context, listen: false).address}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          backgroundColor: Colors.green),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Provider.of<WalletProvider>(context, listen: false)
                  .address ==
              ""
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  generateWallet();
                });
              },
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () async {
                String res = "";
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MobileScanner(
                          allowDuplicates: false,
                          onDetect: (barcode, args) async {
                            if (barcode.rawValue == null) {
                              debugPrint('Failed to scan code');
                            } else {
                              res = barcode.rawValue!;
                              var value = await DigiRouter(context).route(res);
                              if (value == 1) {
                                setState(() {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("SUCESSS!!")));
                                });
                              } else {
                                setState(() {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Failed!!")));
                                });
                              }
                              Navigator.pop(context);
                            }
                          }),
                    ));
              },
              child: const Icon(Icons.qr_code),
            ),
    );
  }
}
