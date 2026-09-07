import 'dart:async';

import 'package:deep_link_kit/deep_link_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Replace these with values from your DeepLinkKit (mlink) dashboard.
const _apiBaseUrl = String.fromEnvironment(
  'DLK_API_BASE',
  defaultValue: 'https://deeplinkkit.com',
);
const _uriPrefix = String.fromEnvironment(
  'DLK_URI_PREFIX',
  defaultValue: 'https://yourapp.deeplinkkit.com',
);
const _apiKey = String.fromEnvironment(
  'DLK_API_KEY',
  defaultValue: 'dk_live_YOUR_SECRET',
);
const _customScheme = String.fromEnvironment(
  'DLK_CUSTOM_SCHEME',
  defaultValue: 'yourapp',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeepLinkKit.initialize(
    options: const DeepLinkKitOptions(
      apiBaseUrl: _apiBaseUrl,
      uriPrefix: _uriPrefix,
      apiKey: _apiKey,
      customScheme: _customScheme,
    ),
  );

  // Terminated state — same order as Firebase receive docs.
  final PendingDynamicLinkData? initialLink =
      await DeepLinkKit.instance.getInitialLink();

  runApp(DeepLinkKitExampleApp(initialLink: initialLink));
}

class DeepLinkKitExampleApp extends StatelessWidget {
  const DeepLinkKitExampleApp({super.key, this.initialLink});

  final PendingDynamicLinkData? initialLink;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepLinkKit Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: HomePage(initialLink: initialLink),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialLink});

  final PendingDynamicLinkData? initialLink;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pathController = TextEditingController(text: '/product/123');
  final _titleController = TextEditingController(text: 'Summer sale');

  StreamSubscription<PendingDynamicLinkData>? _linkSub;
  final _received = <String>[];

  String? _longLink;
  String? _shortLink;
  String? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialLink != null) {
      _appendReceived('initial', widget.initialLink!);
    }

    // Background / foreground — Firebase onLink parity.
    _linkSub = DeepLinkKit.instance.onLink.listen(
      (data) => _appendReceived('onLink', data),
      onError: (Object e) => setState(() => _status = 'onLink error: $e'),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _pathController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _appendReceived(String source, PendingDynamicLinkData data) {
    setState(() {
      _received.insert(
        0,
        '[$source] ${data.link} '
        '${data.shortLink != null ? '(short: ${data.shortLink})' : ''}',
      );
    });
  }

  DynamicLinkParameters _params() {
    final path = _pathController.text.trim();
    final normalized = path.startsWith('/') ? path : '/$path';

    return DynamicLinkParameters(
      link: Uri.parse('https://www.example.com$normalized'),
      uriPrefix: _uriPrefix,
      androidParameters: const AndroidParameters(
        packageName: 'com.deeplinkkit.deep_link_kit_example',
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.deeplinkkit.deepLinkKitExample',
        customScheme: _customScheme,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        description: 'Opened via DeepLinkKit example',
      ),
      googleAnalyticsParameters: const GoogleAnalyticsParameters(
        source: 'example_app',
        medium: 'sdk_demo',
        campaign: 'deep_link_kit',
      ),
    );
  }

  Future<void> _buildLongLink() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final uri = DeepLinkKit.instance.buildLink(_params());
      setState(() {
        _longLink = uri.toString();
        _status = 'Long link built locally (no network).';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _buildShortLink({bool unguessable = false}) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final short = await DeepLinkKit.instance.buildShortLink(
        _params(),
        shortLinkType: unguessable
            ? ShortDynamicLinkType.unguessable
            : ShortDynamicLinkType.short,
      );
      setState(() {
        _shortLink = short.shortUrl.toString();
        _longLink = short.previewLink.toString();
        _status = 'Short link created via mlink API.';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _copy(String? value) async {
    if (value == null || value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepLinkKit Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Create', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Mirrors Firebase DynamicLinkParameters → buildLink / buildShortLink.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathController,
            decoration: const InputDecoration(
              labelText: 'Deep link path',
              hintText: '/product/123',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Social title (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : _buildLongLink,
                child: const Text('buildLink'),
              ),
              FilledButton.tonal(
                onPressed: _busy ? null : () => _buildShortLink(),
                child: const Text('buildShortLink'),
              ),
              OutlinedButton(
                onPressed:
                    _busy ? null : () => _buildShortLink(unguessable: true),
                child: const Text('unguessable'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, style: theme.textTheme.bodySmall),
          ],
          if (_shortLink != null) ...[
            const SizedBox(height: 16),
            _LinkTile(
              label: 'Short link',
              value: _shortLink!,
              onCopy: () => _copy(_shortLink),
            ),
          ],
          if (_longLink != null) ...[
            const SizedBox(height: 8),
            _LinkTile(
              label: 'Long / preview link',
              value: _longLink!,
              onCopy: () => _copy(_longLink),
            ),
          ],
          const SizedBox(height: 28),
          Text('Receive', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'getInitialLink + onLink (Firebase receive parity). '
            'Open a short link or custom scheme to see events here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (_received.isEmpty)
            Text(
              'No links received yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ..._received.map(
              (line) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: SelectableText(line),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Config', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            'apiBaseUrl: $_apiBaseUrl\n'
            'uriPrefix: $_uriPrefix\n'
            'customScheme: $_customScheme\n'
            'apiKey: ${_apiKey.startsWith('dk_live_YOUR') ? '(placeholder — set DLK_API_KEY)' : '(set)'}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: SelectableText(value),
        trailing: IconButton(
          tooltip: 'Copy',
          onPressed: onCopy,
          icon: const Icon(Icons.copy),
        ),
      ),
    );
  }
}
