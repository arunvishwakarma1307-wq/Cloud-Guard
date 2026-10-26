
import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NetworkSecurityCenterPage extends StatefulWidget {
  const NetworkSecurityCenterPage({super.key});

  @override
  State<NetworkSecurityCenterPage> createState() =>
      _NetworkSecurityCenterPageState();
}

class _NetworkSecurityCenterPageState
    extends State<NetworkSecurityCenterPage> {
  List<ConnectivityResult> _connections = [];
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _loading = true;
  bool _internetLoading = false;
  bool? _internetAvailable;
  String? _error;
  String? _internetMessage;

  // Manual confirmations only; these are not automatic security scans.
  bool _wifiSecurityChecked = false;
  bool _deviceUpdatesChecked = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();

    _subscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        if (!mounted) return;

        setState(() {
          _connections = results;
          _loading = false;
          _error = null;
        });
      },
      onError: (_) {
        if (!mounted) return;

        setState(() {
          _error = 'Connection status could not be monitored.';
          _loading = false;
        });
      },
    );
  }

  Future<void> _checkConnection() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Connectivity().checkConnectivity();

      if (!mounted) return;

      setState(() {
        _connections = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to read connection status.';
        _loading = false;
      });
    }
  }

  Future<void> _testInternet() async {
    if (!_hasConnection) {
      setState(() {
        _internetAvailable = false;
        _internetMessage =
            'No network connection is currently detected.';
        _internetLoading = false;
      });
      return;
    }

    setState(() {
      _internetLoading = true;
      _internetAvailable = null;
      _internetMessage = kIsWeb
          ? 'Testing browser-compatible DNS endpoint...'
          : 'Testing a public internet endpoint...';
    });

    try {
      final response = kIsWeb
          ? await http
              .get(
                Uri.parse(
                  'https://cloudflare-dns.com/dns-query'
                  '?name=example.com&type=A',
                ),
                headers: {
                  'Accept': 'application/dns-json',
                },
              )
              .timeout(const Duration(seconds: 8))
          : await http
              .get(
                Uri.parse('https://www.google.com/generate_204'),
              )
              .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      bool success;
      String message;

      if (kIsWeb) {
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            final dnsStatus = decoded['Status'];
            final answers = decoded['Answer'];

            success = dnsStatus == 0 &&
                answers is List &&
                answers.isNotEmpty;

            message = success
                ? 'The browser reached the DNS endpoint and received '
                    'a DNS answer. This does not confirm every website '
                    'is reachable or that the network is secure.'
                : 'The DNS endpoint responded, but a successful DNS '
                    'answer could not be confirmed.';
          } else {
            success = false;
            message = 'The DNS response format was unexpected.';
          }
        } else {
          success = false;
          message =
              'The DNS endpoint returned HTTP ${response.statusCode}. '
              'Internet access could not be confirmed.';
        }
      } else {
        success = response.statusCode == 204 ||
            (response.statusCode >= 200 &&
                response.statusCode < 400);

        message = success
            ? 'The test endpoint responded successfully. '
                'This does not prove all internet services work.'
            : 'The endpoint returned HTTP ${response.statusCode}. '
                'Internet access could not be fully confirmed.';
      }

      setState(() {
        _internetAvailable = success;
        _internetMessage = message;
        _internetLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _internetAvailable = null;
        _internetMessage =
            'The request timed out. Internet status could not '
            'be confirmed.';
        _internetLoading = false;
      });
    } on FormatException {
      if (!mounted) return;

      setState(() {
        _internetAvailable = null;
        _internetMessage =
            'The endpoint response could not be understood. '
            'Internet status could not be confirmed.';
        _internetLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _internetAvailable = null;
        _internetMessage = kIsWeb
            ? 'The browser could not read the DNS response. '
                'CORS or another network restriction may be blocking it.'
            : 'The endpoint could not be reached. '
                'Internet status could not be confirmed.';
        _internetLoading = false;
      });
    }
  }

  bool get _hasConnection => _connections.any(
        (result) => result != ConnectivityResult.none,
      );

  String get _connectionName {
    if (_connections.isEmpty ||
        _connections.every(
          (result) => result == ConnectivityResult.none,
        )) {
      return 'No network connection detected';
    }

    final names = _connections
        .where((result) => result != ConnectivityResult.none)
        .map((result) {
          switch (result) {
            case ConnectivityResult.wifi:
              return 'Wi-Fi';
            case ConnectivityResult.mobile:
              return 'Mobile data';
            case ConnectivityResult.ethernet:
              return 'Ethernet';
            case ConnectivityResult.vpn:
              return 'VPN';
            case ConnectivityResult.bluetooth:
              return 'Bluetooth';
            case ConnectivityResult.satellite:
              return 'Satellite';
            case ConnectivityResult.other:
              return 'Other network';
            case ConnectivityResult.none:
              return 'No connection';
          }
        })
        .toSet()
        .toList();

    return names.join(', ');
  }

  int get _completedManualChecks =>
      (_wifiSecurityChecked ? 1 : 0) +
      (_deviceUpdatesChecked ? 1 : 0);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = _hasConnection;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Security Center'),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _loading || _internetLoading
                ? null
                : _checkConnection,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    'Network Overview',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _StatusRow(
                    icon: _loading
                        ? Icons.hourglass_top
                        : connected
                            ? Icons.wifi
                            : Icons.wifi_off,
                    color: _loading
                        ? Colors.orange
                        : connected
                            ? Colors.green
                            : Colors.red,
                    title: _loading
                        ? 'Checking network...'
                        : _error != null
                            ? 'Network status unavailable'
                            : connected
                                ? 'Network detected'
                                : 'No network detected',
                    subtitle: _error ?? _connectionName,
                  ),
                  const Divider(height: 28),
                  _StatusRow(
                    icon: _internetLoading
                        ? Icons.hourglass_top
                        : _internetAvailable == true
                            ? Icons.check_circle_outline
                            : _internetAvailable == false
                                ? Icons.error_outline
                                : Icons.public,
                    color: _internetLoading
                        ? Colors.orange
                        : _internetAvailable == true
                            ? Colors.green
                            : _internetAvailable == false
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                    title: _internetLoading
                        ? 'Testing internet...'
                        : _internetAvailable == true
                            ? 'Internet endpoint reachable'
                            : _internetAvailable == false
                                ? 'Internet test unsuccessful'
                                : 'Internet not confirmed',
                    subtitle: _internetMessage ??
                        'Press Test internet to check a public endpoint.',
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'A detected network does not guarantee internet '
                    'access or prove that the network is secure.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _checkConnection,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Check network'),
                      ),
                      FilledButton.icon(
                        onPressed: _internetLoading ? null : _testInternet,
                        icon: const Icon(Icons.public),
                        label: const Text('Test internet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Security Checklist',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '$_completedManualChecks of 2 manual checks completed',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _completedManualChecks / 2,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          _ChecklistItem(
            title: 'Network connection status',
            description:
                'Checks the connection type reported by your device.',
            status: _loading ? 'Checking...' : _connectionName,
            icon: Icons.wifi,
            checked: !_loading && _error == null && _hasConnection,
            interactive: false,
          ),
          _ChecklistItem(
            title: 'Internet endpoint test',
            description:
                'A successful response confirms this endpoint responded, '
                'not that every website is reachable.',
            status: _internetLoading
                ? 'Test running...'
                : _internetAvailable == true
                    ? 'Endpoint responded'
                    : _internetAvailable == false
                        ? 'Test unsuccessful'
                        : 'Not tested yet',
            icon: Icons.public,
            checked: _internetAvailable == true,
            interactive: false,
          ),
          _ChecklistItem(
            title: 'Wi-Fi encryption and router security',
            description:
                'Open your router settings and confirm WPA2-AES or WPA3 '
                'is enabled. Tick only after you have checked it.',
            status: _wifiSecurityChecked ? 'Manually checked' : 'Not checked',
            icon: Icons.router_outlined,
            checked: _wifiSecurityChecked,
            interactive: true,
            onChanged: (value) {
              setState(() {
                _wifiSecurityChecked = value;
              });
            },
          ),
          _ChecklistItem(
            title: 'Device updates',
            description:
                'Check your device settings for operating system and app '
                'security updates. Tick after checking.',
            status: _deviceUpdatesChecked ? 'Manually checked' : 'Not checked',
            icon: Icons.system_update_outlined,
            checked: _deviceUpdatesChecked,
            interactive: true,
            onChanged: (value) {
              setState(() {
                _deviceUpdatesChecked = value;
              });
            },
          ),
          const _ChecklistItem(
            title: 'Malware and phishing',
            description:
                'This page does not scan for malware or detect phishing.',
            status: 'Not scanned',
            icon: Icons.gpp_bad_outlined,
            checked: false,
            interactive: false,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Advisor',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const _SecurityTip(
                    icon: Icons.lock_outline,
                    title: 'Use trusted networks',
                    description:
                        'Be careful with sensitive transactions on '
                        'public Wi-Fi.',
                  ),
                  const _SecurityTip(
                    icon: Icons.vpn_key_outlined,
                    title: 'Protect your accounts',
                    description:
                        'Use unique passwords and enable two-factor '
                        'authentication wherever possible.',
                  ),
                  const _SecurityTip(
                    icon: Icons.link_outlined,
                    title: 'Check links before opening',
                    description:
                        'Be cautious with unexpected links and login '
                        'pages asking for personal information.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            kIsWeb
                ? 'Platform: Web browser. Browser security policies '
                    'may block the internet test.'
                : 'Platform: Android or another supported device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.checked,
    required this.interactive,
    this.onChanged,
  });

  final String title;
  final String description;
  final String status;
  final IconData icon;
  final bool checked;
  final bool interactive;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(
                icon,
                size: 27,
                color: checked ? Colors.green : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(description),
                  const SizedBox(height: 6),
                  Text(
                    'Status: $status',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (interactive)
              Checkbox(
                value: checked,
                onChanged: onChanged == null
                    ? null
                    : (value) => onChanged!(value ?? false),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  checked ? Icons.check_circle : Icons.info_outline,
                  color: checked ? Colors.green : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SecurityTip extends StatelessWidget {
  const _SecurityTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 28),
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(description),
      ),
    );
  }
}
