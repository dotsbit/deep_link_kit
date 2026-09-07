import 'package:deep_link_kit/deep_link_kit.dart';
import 'package:deep_link_kit_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await DeepLinkKit.initialize(
      options: const DeepLinkKitOptions(
        apiBaseUrl: 'https://deeplinkkit.com',
        uriPrefix: 'https://yourapp.deeplinkkit.com',
        customScheme: 'yourapp',
      ),
    );
  });

  tearDownAll(() async {
    if (DeepLinkKit.isInitialized) {
      await DeepLinkKit.instance.dispose();
    }
  });

  testWidgets('shows create and receive sections', (tester) async {
    await tester.pumpWidget(const DeepLinkKitExampleApp());
    expect(find.text('DeepLinkKit Example'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('buildLink'), findsOneWidget);
    expect(find.text('buildShortLink'), findsOneWidget);
  });
}
