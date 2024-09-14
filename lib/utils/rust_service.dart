import 'dart:async';
import 'dart:convert';
import 'package:disproportion/src/rust/api/main.dart';

class RustService {
  final _eventController = StreamController<Map<String, String>>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  StreamSubscription<String>? _subscription;

  Stream<Map<String, String>> get events => _eventController.stream;
  Stream<Object> get errors => _errorController.stream;

  void start(String token) {
    stop(); // Cancel any existing subscription before starting a new one

    _subscription = gatewayConnection(token: token).listen((data) {
      try {
        final event = jsonDecode(data) as Map<String, dynamic>;
        final eventType = event['event_type'] as String;
        final eventData = event['data'] as String;
        _eventController.add({'type': eventType, 'data': eventData});
      } catch (e) {
        _errorController.add(e);
      }
    }, onError: (error) {
      _errorController.add(error);
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    _eventController.close();
    _errorController.close();
    stop();
  }
}

final rustService = RustService();