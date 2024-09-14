import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app.dart';
import '../utils/rust_service.dart';

class EventsPage extends StatefulWidget {
  final String readyEvent;
  const EventsPage({super.key, required this.readyEvent});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  Map<String, dynamic>? _guildData;
  final Map<String, Map<String, List<Map<String, dynamic>>>> _guildChannels = {};
  final Map<String, Map<String, List<Map<String, dynamic>>>> _guildMessages = {};
  late StreamSubscription<Map<String, String>> _eventSubscription;
  late StreamSubscription<Object> _errorSubscription;

  @override
  void initState() {
    super.initState();
    _handleReadyEvent(widget.readyEvent);

    _eventSubscription = rustService.events.listen((event) {
      switch (event['type']) {
        case 'READY':
          _handleReadyEvent(event['data']!);
          break;
        case 'MESSAGE':
          _handleMessageEvent(event['data']!);
          break;
        default:
        // Handle other events if necessary
          break;
      }
    });

    _errorSubscription = rustService.errors.listen((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _errorSubscription.cancel();
    rustService.stop();
    super.dispose();
  }

  void _handleReadyEvent(String guildDataJson) {
    setState(() {
      _guildData = json.decode(guildDataJson);
      _initializeGuildChannels();
    });
  }

  void _initializeGuildChannels() {
    if (_guildData != null && _guildData!.containsKey('guilds')) {
      List<dynamic> guilds = _guildData!['guilds'];
      for (var guild in guilds) {
        String guildId = guild['id'].toString().replaceAll('"', '');
        List<dynamic> channels = guild['channels'] ?? [];

        if (!_guildChannels.containsKey(guildId)) {
          _guildChannels[guildId] = {'text': [], 'voice': []};
        }

        for (var channel in channels) {
          String channelId = channel['id'].toString().replaceAll('"', '');
          String channelName = channel['name'] ?? 'Unnamed Channel';
          int channelType = channel['type'];

          if (channelType == 0 && !_guildChannels[guildId]!['text']!.any((c) => c['id'] == channelId)) {
            _guildChannels[guildId]!['text']!.add({'id': channelId, 'name': channelName});
            _guildMessages[guildId] = _guildMessages[guildId] ?? {};
            _guildMessages[guildId]![channelId] = _guildMessages[guildId]![channelId] ?? [];
          } else if (channelType == 2 && !_guildChannels[guildId]!['voice']!.any((c) => c['id'] == channelId)) {
            _guildChannels[guildId]!['voice']!.add({'id': channelId, 'name': channelName});
            _guildMessages[guildId] = _guildMessages[guildId] ?? {};
            _guildMessages[guildId]![channelId] = _guildMessages[guildId]![channelId] ?? [];
          }
        }
      }

      print('Initialized guild messages: $_guildMessages');
    }
  }

  void _handleMessageEvent(String messageJson) {
    Map<String, dynamic> messageData = json.decode(messageJson);
    BigInt guildId = BigInt.parse(messageData['server_id'].toString().trim().replaceAll('"', ''));
    BigInt channelId = BigInt.parse(messageData['channel_id'].toString().trim().replaceAll('"', ''));

    print('Received message for guild: $guildId, channel: $channelId');

    if (_guildMessages.containsKey(guildId.toString()) && _guildMessages[guildId.toString()]!.containsKey(channelId.toString())) {
      List<Map<String, dynamic>> messages = _guildMessages[guildId.toString()]![channelId.toString()]!;
      messages.add({
        'author': messageData['author'] ?? 'Unknown',
        'content': messageData['content'] ?? '',
        'timestamp': messageData['timestamp'] ?? '',
      });

      print('Message added: ${messageData['content']}');

      setState(() {
        _guildMessages[guildId.toString()]![channelId.toString()] = messages;
      });
    } else {
      print('Guild or channel not found for the message.');
      print('Current guild messages: $_guildMessages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discord Events')),
      drawer: const AppDrawer(),
      body: Center(
        child: ListView(
          children: [
            if (_guildData != null)
              ..._buildGuildList(_guildData!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGuildList(Map<String, dynamic> guildData) {
    List<Widget> guildWidgets = [];

    if (guildData.containsKey('guilds')) {
      List<dynamic> guilds = guildData['guilds'];

      for (var guild in guilds) {
        String guildId = guild['id'].toString();

        guildWidgets.add(
          ExpansionTile(
            title: Text(guild['name'] ?? 'Unknown Guild'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildChannelsView(guildId),
              ),
            ],
          ),
        );
      }
    }

    return guildWidgets;
  }

  Widget _buildChannelsView(String guildId) {
    List<Map<String, dynamic>> textChannels = _guildChannels[guildId]!['text'] ?? [];
    List<Map<String, dynamic>> voiceChannels = _guildChannels[guildId]!['voice'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (textChannels.isNotEmpty) ...[
          const Text('Text Channels', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          ..._buildChannelList(textChannels, isVoice: false, guildId: guildId),
          const SizedBox(height: 16.0),
        ],
        if (voiceChannels.isNotEmpty) ...[
          const Text('Voice Channels', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          ..._buildChannelList(voiceChannels, isVoice: true, guildId: guildId),
        ],
      ],
    );
  }

  List<Widget> _buildChannelList(List<Map<String, dynamic>> channels, {required bool isVoice, required String guildId}) {
    return channels.map((channel) {
      String channelId = channel['id'].toString();
      String channelName = channel['name'].toString();

      return ListTile(
        title: Text(channelName),
        onTap: () {
          _showChannelMessages(guildId, channelId, channelName, isVoice);
        },
      );
    }).toList();
  }

  void _showChannelMessages(String guildId, String channelId, String channelName, bool isVoice) {
  List<Map<String, dynamic>> messages = _guildMessages[guildId]![channelId]!;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ChannelMessagesPage(
        guildId: guildId,
        channelId: channelId,
        channelName: channelName,
        initialMessages: messages,
      ),
    ),
  );
}
}

class ChannelMessagesPage extends StatefulWidget {
  final String guildId;
  final String channelId;
  final String channelName;
  final List<Map<String, dynamic>> initialMessages;

  const ChannelMessagesPage({
    super.key,
    required this.guildId,
    required this.channelId,
    required this.channelName,
    required this.initialMessages,
  });

  @override
  _ChannelMessagesPageState createState() => _ChannelMessagesPageState();
}

class _ChannelMessagesPageState extends State<ChannelMessagesPage> {
  late List<Map<String, dynamic>> _messages;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.initialMessages);

    _subscription = rustService.events.listen((event) {
      if (event['type'] == 'MESSAGE') {
        final messageData = json.decode(event['data']!);
        final eventGuildId = messageData['server_id'].toString().trim().replaceAll('"', '');
        final eventChannelId = messageData['channel_id'].toString().trim().replaceAll('"', '');

        if (eventGuildId == widget.guildId && eventChannelId == widget.channelId) {
          if (mounted) {
            setState(() {
              _messages.add({
                'author': messageData['author'] ?? 'Unknown',
                'content': messageData['content'] ?? '',
                'timestamp': messageData['timestamp'] ?? '',
              });
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages in ${widget.channelName}')),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final author = message['author'] ?? 'Unknown';
          final content = message['content'] ?? '';
          final timestamp = message['timestamp'] ?? '';

          return ListTile(
            title: Text('$author - $timestamp'),
            subtitle: Text(content),
          );
        },
      ),
    );
  }
}