import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/db.dart';
import '../models/models.dart';

class ReadPage extends StatefulWidget {
  const ReadPage({super.key, required this.post, required this.initData});
  final Post post;
  final Map<String, dynamic> initData;

  @override
  ReadPageState createState() => ReadPageState();
}

class ReadPageState extends State<ReadPage> {
  late InAppWebViewController webViewController;

  double appbarHeight = 56.0;
  int lastScrollY = 0;

  @override
  Widget build(BuildContext context) {
    final String textColor = Theme.of(context)
        .colorScheme
        .primary
        .value
        .toRadixString(16)
        .substring(2);
    final String backgroundColor = Theme.of(context)
        .scaffoldBackgroundColor
        .value
        .toRadixString(16)
        .substring(2);
    // 如果 widget.post.link 以 http:// 开头，则强制使用 https://
    widget.post.link =
        widget.post.link.replaceFirst(RegExp(r'^http://'), 'https://');

    final String endAddLinkStr = widget.initData['endAddLink']
        ? "<p><a href='${widget.post.link}'>→ 阅读原文</a></p>"
        : '';
    final String contentHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
/* CDN 服务仅供平台体验和调试使用，平台不承诺服务的稳定性，企业客户需下载字体包自行发布使用并做好备份。 */
@font-face {
  font-family: "思源宋体 CN VF Regular";
  src: url("//at.alicdn.com/wf/webfont/xRg1LrpJJqRG/T_MtMXsOAonqR5tTR7L4p.woff2") format("woff2"),
  url("//at.alicdn.com/wf/webfont/xRg1LrpJJqRG/MNkSp-5rictSiKrlMlU8q.woff") format("woff");
  font-display: swap;
}
body {
  font-family: "思源宋体 CN VF Regular", serif;
  font-size: ${widget.initData['fontSize']}px;
  line-height: ${widget.initData['lineheight']};
  color: #$textColor;
  background-color: #$backgroundColor;
  margin: 0;
  padding: 12px ${widget.initData['pagePadding']}px;
  text-align: ${widget.initData['textAlign']};
}
img {
  max-width: 100%;
  height: auto;
}
iframe {
  max-width: 100%;
  height: auto;
}
a {
  color: #$textColor;
  text-decoration: none;
  border-bottom: 1px solid #$textColor;
  padding-bottom: 1px;
  word-break: break-all;
}
blockquote {
  margin: 0;
  padding: 0 0 0 16px;
  border-left: 4px solid #9e9e9e;
}
h1 {
  font-size: 1.5em;
  font-weight: 700;
  margin: 0 0 0.5em 0;
}
${widget.initData['customCss']}
</style>
</head>
<body>
<h1>${widget.post.title}</h1>
${widget.post.content}
$endAddLinkStr
</body>
<style>
${widget.initData['customCss']}
</style>
</html>
''';
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appbarHeight,
        title: Text(
          widget.post.feedName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry>[
                PopupMenuItem(
                  onTap: () async {
                    await markPostAsUnread(widget.post.id!);
                  },
                  child: Text(
                    '标记未读',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () async {
                    await changePostFavorite(widget.post.id!);
                    setState(() {
                      widget.post.favorite = widget.post.favorite == 0 ? 1 : 0;
                    });
                  },
                  child: Text(
                    widget.post.favorite == 1 ? '取消收藏' : '收藏文章',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.post.link));
                  },
                  child: Text(
                    '复制链接',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () {
                    Share.share(
                      widget.post.link,
                      subject: widget.post.title,
                    );
                  },
                  child: Text(
                    '分享文章',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: InAppWebView(
        initialData: widget.post.openType == 0
            ? InAppWebViewInitialData(data: contentHtml)
            : null,
        initialUrlRequest: widget.post.openType == 1
            ? URLRequest(url: Uri.parse(widget.post.link))
            : null,
        initialOptions: InAppWebViewGroupOptions(
            android: AndroidInAppWebViewOptions(
              useHybridComposition: false, // 关闭混合模式，提高性能，避免 WebView 闪烁
            ),
            crossPlatform: InAppWebViewOptions(
              transparentBackground: true,
            )),
        onWebViewCreated: (InAppWebViewController controller) {
          webViewController = controller;
        },
        // 向下滑动时，隐藏 AppBar，向上滑动时，显示 AppBar
        onScrollChanged: (InAppWebViewController controller, int x, int y) {
          if (y > lastScrollY) {
            if (appbarHeight > 0) {
              double tem = appbarHeight - (y - lastScrollY).toDouble() / 10.0;
              setState(() {
                appbarHeight = tem >= 0 ? tem : 0;
              });
            }
          } else if (y < lastScrollY) {
            if (appbarHeight < 56) {
              double tem = appbarHeight + (lastScrollY - y).toDouble() / 10.0;
              setState(() {
                appbarHeight = tem <= 56 ? tem : 56;
              });
            }
          }
          lastScrollY = y;
        },
        contextMenu: ContextMenu(
          options: ContextMenuOptions(
            hideDefaultSystemContextMenuItems: true,
          ),
          menuItems: [
            ContextMenuItem(
              androidId: 1,
              iosId: '1',
              title: '复制',
              action: () {
                webViewController.getSelectedText().then((String? text) {
                  if (text != null) {
                    Clipboard.setData(ClipboardData(text: text));
                  }
                });
              },
            ),
            ContextMenuItem(
              androidId: 2,
              iosId: '2',
              title: '分享',
              action: () {
                webViewController.getSelectedText().then((String? text) {
                  if (text != null) {
                    Share.share(text);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
