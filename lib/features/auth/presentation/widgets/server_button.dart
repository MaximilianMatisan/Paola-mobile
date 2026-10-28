import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/network/api_exception.dart';
import 'package:paola_mobile/core/network/paola_api.dart';

/// Shows the server in use; tapping it lets you enter another one, e.g. the
/// LAN IP of the laptop running the web app.
class ServerButton extends StatefulWidget {
  final bool enabled;

  const ServerButton({super.key, this.enabled = true});

  @override
  State<ServerButton> createState() => _ServerButtonState();
}

class _ServerButtonState extends State<ServerButton> {
  final _api = PaolaApi.instance;

  Future<void> _editServer() async {
    final controller = TextEditingController(text: _api.serverUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.serverTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'http://192.168.1.20:3000',
            helperText: context.t.serverDefault(_api.defaultServerUrl),
          ),
          onSubmitted: (text) => Navigator.of(context).pop(text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(context.t.serverReset),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.t.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || !mounted) return;
    try {
      await _api.setServerUrl(url);
      setState(() {});
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: widget.enabled ? _editServer : null,
      icon: const Icon(Icons.dns_outlined, size: 18),
      label: Text(_api.serverUrl),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
