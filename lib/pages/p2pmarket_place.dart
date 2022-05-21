import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:kryptonia/widgets/cust_scaf_wid.dart';
import 'package:kryptonia/widgets/text_link.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'dart:async';

import '../helpers/strings.dart';

class P2PMarketPlace extends StatefulWidget {
  final String url;

  const P2PMarketPlace({
    Key? key,
    required this.url,
  }) : super(key: key);

  @override
  State<P2PMarketPlace> createState() => _P2PMarketPlaceState();
}

class _P2PMarketPlaceState extends State<P2PMarketPlace> {

  int indexPosition = 1;

  Completer<WebViewController> _controller =
  Completer<WebViewController>();

  completeLoading(String A) {
    setState(() {
      indexPosition = 0;
    });
  }

  beginLoading(String A) {
    setState(() {
      indexPosition = 1;
    });
  }

  var _key = UniqueKey();

  onError(WebResourceError error) {
    setState(() {
      indexPosition = 2;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  showWeb() async {
    await FlutterWebBrowser.openWebPage(
      url: P2PURL,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustScafWid(
      // body: Center(
      //   child: TextLinkWid(
      //     title: 'Open Marketplace',
      //     onTap: () {
      //       showWeb();
      //     },
      //   ),
      // ),
      body: IndexedStack(
        index: indexPosition,
        children: [
          WebView(
              key: _key,
              initialUrl: P2PURL,
              onPageStarted: beginLoading,
              onPageFinished: completeLoading,
              onWebResourceError: onError,
              onWebViewCreated: (c) {
                _controller.complete(c);
              }
          ),
          Center(
            child: CircularProgressIndicator(),
          ),
          Center(
              child: Text(
                'Hmm... failed to load page\nCheck your internet and try again',)
          ),
        ],
      ),
    );
  }
}
