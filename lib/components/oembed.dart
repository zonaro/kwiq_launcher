import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OEmbedView extends StatefulWidget {
  final Uri uri;

  const OEmbedView({super.key, required this.uri});
  @override
  State<OEmbedView> createState() => _OEmbedViewState();
}

class _OEmbedViewState extends State<OEmbedView> {
  late WebViewController controller;
  AwaiterData<OEmbedData> oem = AwaiterData<OEmbedData>(validateData: false, expireDataAfter: 2.seconds);
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: context.width, maxHeight: 300),
      child: FutureAwaiter(
          data: oem,
          future: () async {
            var o = await OEmbed.fromUri(widget.uri);
            return o;
          },
          loading: nil,
          errorChild: (e) => nil,
          builder: (data) {
            controller.loadHtmlString(data.html ?? "<body>NO HTML PROVIDED</body>");
            return SizedBox(width: data.width?.toDouble(), height: data.height?.toDouble(), child: WebViewWidget(controller: controller));
          }),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          // onNavigationRequest: (NavigationRequest request) {},
        ),
      );
  }
}
