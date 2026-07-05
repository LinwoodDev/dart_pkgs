import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:networker_rtc/config.dart';

import 'client.dart';
import 'server.dart';

void main() {
  runApp(const RtcChatApp());
}

const _defaultSignalingUrl = 'ws://127.0.0.1:8080/rtc?room=demo';
const _defaultIceServerText =
    'stun:stun.l.google.com:19302\n'
    'stun:stun1.l.google.com:19302\n'
    'stun:stun2.l.google.com:19302\n'
    'stun:global.stun.twilio.com:3478';

enum AppMode { signaling, peer }

class ChatMessage {
  final bool local;
  final String text;

  const ChatMessage({required this.local, required this.text});
}

class RtcChatApp extends StatelessWidget {
  const RtcChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Networker RTC Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const RtcChatHome(),
    );
  }
}

class RtcChatHome extends StatefulWidget {
  const RtcChatHome({super.key});

  @override
  State<RtcChatHome> createState() => _RtcChatHomeState();
}

class _RtcChatHomeState extends State<RtcChatHome> {
  final RtcExampleSignalingServer _signaling = RtcExampleSignalingServer();
  final RtcExamplePeer _peer = RtcExamplePeer();
  final TextEditingController _message = TextEditingController();
  final TextEditingController _signalingUrl = TextEditingController(
    text: _defaultSignalingUrl,
  );
  final TextEditingController _advertisedHost = TextEditingController();
  final TextEditingController _room = TextEditingController(text: 'demo');
  final TextEditingController _iceServers = TextEditingController(
    text: _defaultIceServerText,
  );
  final TextEditingController _turnUsername = TextEditingController();
  final TextEditingController _turnCredential = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<String> _status = [];
  final List<StreamSubscription<Object?>> _subscriptions = [];

  AppMode? _mode;
  bool _started = false;
  bool _connected = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_signaling.events.listen(_handleEvent))
      ..add(_peer.events.listen(_handleEvent));
  }

  Future<void> _startSignaling() async {
    if (_started || _busy) return;
    setState(() {
      _mode = AppMode.signaling;
      _busy = true;
    });
    try {
      final url = await _signaling.start(
        advertisedHost: _advertisedHost.text,
        room: _room.text.trim().isEmpty ? 'demo' : _room.text.trim(),
      );
      _signalingUrl.text = url.toString();
      _addStatus('signaling server started');
      setState(() => _started = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _joinPeer() async {
    if (_started || _busy) return;
    setState(() {
      _mode = AppMode.peer;
      _busy = true;
    });
    try {
      final url = Uri.tryParse(_signalingUrl.text.trim());
      if (url == null || !url.hasScheme) {
        _addStatus('invalid signaling url');
        setState(() => _mode = null);
        return;
      }
      await _peer.join(url, configuration: _buildRtcConfiguration());
      _addStatus('joined signaling room');
      setState(() => _started = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  NetworkerRtcConfiguration _buildRtcConfiguration() {
    final username = _turnUsername.text.trim();
    final credential = _turnCredential.text.trim();
    final servers = _iceServers.text
        .split(RegExp(r'[\n,]'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((url) {
          if (url.startsWith('turn:') || url.startsWith('turns:')) {
            return NetworkerRtcIceServer(
              url: url,
              username: username.isEmpty ? null : username,
              credential: credential.isEmpty ? null : credential,
            );
          }
          return NetworkerRtcIceServer.stun(url);
        })
        .toList();
    return NetworkerRtcConfiguration(
      iceServers: servers.isEmpty
          ? NetworkerRtcConfiguration.defaultIceServers
          : servers,
    );
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (!_connected || text.isEmpty) return;
    _message.clear();
    await _peer.send(text);
  }

  Future<void> _copySignalingUrl() async {
    await _copyText(_signalingUrl.text.trim());
  }

  Future<void> _shareSignalingUrl() async {
    final shareUrl = Uri.tryParse(_signalingUrl.text.trim());
    final localUrl = _signaling.localUrl ?? shareUrl;
    if (shareUrl == null || localUrl == null) return;
    final host = TextEditingController(text: shareUrl.host);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share signaling URL'),
          content: _ShareDialogContent(
            localUrl: localUrl,
            shareUrl: shareUrl,
            publicHost: host,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    host.dispose();
  }

  Future<void> _copyText(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied $text')));
  }

  void _handleEvent(String event) {
    if (event == 'data channel opened') {
      setState(() => _connected = true);
      _addStatus('connected');
      return;
    }
    if (event == 'data channel closed') {
      setState(() => _connected = false);
      _addStatus('disconnected');
      return;
    }
    if (event.startsWith('me: ')) {
      _addMessage(local: true, text: event.substring('me: '.length));
      return;
    }
    if (event.startsWith('peer: ')) {
      _addMessage(local: false, text: event.substring('peer: '.length));
      return;
    }
    _addStatus(event);
  }

  void _addMessage({required bool local, required String text}) {
    if (!mounted) return;
    setState(() => _messages.add(ChatMessage(local: local, text: text)));
    _scrollToBottom();
  }

  void _addStatus(String event) {
    if (!mounted) return;
    setState(() {
      _status.add(event);
      if (_status.length > 5) {
        _status.removeAt(0);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _message.dispose();
    _signalingUrl.dispose();
    _advertisedHost.dispose();
    _room.dispose();
    _iceServers.dispose();
    _turnUsername.dispose();
    _turnCredential.dispose();
    _scrollController.dispose();
    unawaited(_signaling.close());
    unawaited(_peer.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Networker RTC Chat')),
      body: SafeArea(
        child: _mode == null
            ? _ModePicker(
                signalingUrl: _signalingUrl,
                advertisedHost: _advertisedHost,
                room: _room,
                iceServers: _iceServers,
                turnUsername: _turnUsername,
                turnCredential: _turnCredential,
                busy: _busy,
                onSignaling: _startSignaling,
                onPeer: _joinPeer,
              )
            : _mode == AppMode.signaling
            ? _SignalingView(
                url: _signalingUrl.text,
                status: _status,
                onCopyUrl: _copySignalingUrl,
                onShare: _shareSignalingUrl,
              )
            : _ChatView(
                url: _signalingUrl.text,
                connected: _connected,
                status: _status.isEmpty ? 'Waiting for peer' : _status.last,
                messages: _messages,
                message: _message,
                scrollController: _scrollController,
                onSend: _send,
              ),
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  final TextEditingController signalingUrl;
  final TextEditingController advertisedHost;
  final TextEditingController room;
  final TextEditingController iceServers;
  final TextEditingController turnUsername;
  final TextEditingController turnCredential;
  final bool busy;
  final VoidCallback onSignaling;
  final VoidCallback onPeer;

  const _ModePicker({
    required this.signalingUrl,
    required this.advertisedHost,
    required this.room,
    required this.iceServers,
    required this.turnUsername,
    required this.turnCredential,
    required this.busy,
    required this.onSignaling,
    required this.onPeer,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: room,
                enabled: !busy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Room',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: advertisedHost,
                enabled: !busy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Public signaling host or IP',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy ? null : onSignaling,
                icon: const Icon(Icons.hub),
                label: const Text('Start signaling server'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: signalingUrl,
                enabled: !busy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Signaling URL',
                ),
                onSubmitted: (_) => busy ? null : onPeer(),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('ICE servers'),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  TextField(
                    controller: iceServers,
                    enabled: !busy,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'STUN/TURN URLs',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: turnUsername,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'TURN username',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: turnCredential,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'TURN credential',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onPeer,
                icon: const Icon(Icons.person),
                label: const Text('Join as peer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalingView extends StatelessWidget {
  final String url;
  final List<String> status;
  final Future<void> Function() onCopyUrl;
  final Future<void> Function() onShare;

  const _SignalingView({
    required this.url,
    required this.status,
    required this.onCopyUrl,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: colors.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Signaling server - $url',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopyUrl,
                icon: const Icon(Icons.copy),
                tooltip: 'Copy signaling URL',
              ),
              IconButton(
                onPressed: onShare,
                icon: const Icon(Icons.share),
                tooltip: 'Share signaling URL',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: status.length,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.circle, size: 10),
              title: Text(status[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatView extends StatelessWidget {
  final String url;
  final bool connected;
  final String status;
  final List<ChatMessage> messages;
  final TextEditingController message;
  final ScrollController scrollController;
  final Future<void> Function() onSend;

  const _ChatView({
    required this.url,
    required this.connected,
    required this.status,
    required this.messages,
    required this.message,
    required this.scrollController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: connected
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          child: Text(
            'Peer - ${connected ? 'Connected' : status} - $url',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: connected
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _MessageBubble(message: messages[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: message,
                  enabled: connected,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Message peer',
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: connected ? onSend : null,
                icon: const Icon(Icons.send),
                tooltip: 'Send',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareDialogContent extends StatefulWidget {
  final Uri localUrl;
  final Uri shareUrl;
  final TextEditingController publicHost;

  const _ShareDialogContent({
    required this.localUrl,
    required this.shareUrl,
    required this.publicHost,
  });

  @override
  State<_ShareDialogContent> createState() => _ShareDialogContentState();
}

class _ShareDialogContentState extends State<_ShareDialogContent> {
  Uri get _publicUrl {
    final host = widget.publicHost.text.trim();
    return widget.shareUrl.replace(
      host: host.isEmpty ? widget.shareUrl.host : host,
    );
  }

  Future<void> _copy(Uri url) async {
    await Clipboard.setData(ClipboardData(text: url.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied ${url.toString()}')));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Local network URL',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => _copy(widget.localUrl),
                icon: const Icon(Icons.copy),
                tooltip: 'Copy local URL',
              ),
            ),
            child: SelectableText(widget.localUrl.toString(), maxLines: 1),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.publicHost,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Public host or IP',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _copy(_publicUrl),
            icon: const Icon(Icons.copy),
            label: Text('Copy ${_publicUrl.toString()}'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final alignment = message.local
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final background = message.local
        ? colors.primary
        : colors.secondaryContainer;
    final foreground = message.local
        ? colors.onPrimary
        : colors.onSecondaryContainer;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: message.local
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.local ? 'Me' : 'Peer',
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(message.text, style: TextStyle(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
