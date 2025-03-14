import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

final UrlLauncherPlatform _launcher = UrlLauncherPlatform.instance;

Future<void> launchInBrowser(String url) async {
  if (!await _launcher.launch(
    url,
    useSafariVC: false,
    useWebView: false,
    enableJavaScript: false,
    enableDomStorage: false,
    universalLinksOnly: false,
    headers: <String, String>{},
  )) {
    throw Exception('Could not launch $url');
  }
}
