import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import 'package:websockets/websocket/MyWsChannel.dart';
import 'package:websockets/global.dart';

Map jsonrpc = {
  "jsonrpc": "2.0",
  "id": 1,
  "event": "",
  "data": {},
};

class Response {
  final bool isOk;
  final String message;
  final String error;

  const Response(
      {required this.isOk, required this.message, required this.error});
}

Future<Response> httpPost(String url, String session, Map params) async {
  jsonrpc['session'] = session;
  var responce = {...jsonrpc, ...params};

  try {
    final response = await http.post(Uri.parse(Global.httpRpc + url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: json.encode(responce));
    Map data = json.decode(utf8.decode(response.bodyBytes));

    if (data['success'] != null) {
      return Response(isOk: true, message: data['message'], error: '');
    } else {
      return Response(isOk: false, message: '', error: data['message']);
    }
  } catch (e) {
    return Response(isOk: false, message: '', error: 'network error');
  }
}

WebSocketsNotifications rpc = new WebSocketsNotifications();

class WebSocketsNotifications {
  static final WebSocketsNotifications _sockets =
      new WebSocketsNotifications._internal();
  String session = '';

  factory WebSocketsNotifications() {
    return _sockets;
  }

  WebSocketsNotifications._internal();

  WebSocketChannel? _channel;

  bool _closed = true;

  Map<String, List> _listeners = new Map<String, List>();

  bool isLinked() {
    return !_closed;
  }

  Future<bool> init(String addr, String appSession) async {
    reset();
    session = appSession;

    var i = 2;

    while (true) {
      try {
        _channel = await MyWsChannel.connect(Uri.parse('wss://' + addr));

        _closed = false;
        _channel!.stream.listen(_onReceptionOfMessageFromServer,
            cancelOnError: true, onDone: () {
          String closeReason = "";
          try {
            closeReason = _channel!.closeReason.toString();
          } catch (_) {}
          print("WebSocket done… " + closeReason);
          // _closed = true;
        });
        return true;
      } catch (e) {
        print("DEBUG Flutter: got websockt error.........retry ${i}s");
        //print(e);
        if (i > 100) {
          print("DEBUG Flutter: got websockt error.");
          return false;
        }
        await Future.delayed(Duration(seconds: i), () => true);
        i = i * 2; // 2, 4, 8, 16, 32, 64
        continue;
      }
    }
  }

  reset() {
    if (_channel != null) {
      _channel!.sink.close();
    }
    _closed = true;
  }

  send(String method, Object params) {
    jsonrpc["event"] = method;
    jsonrpc["data"] = params;

    if (_channel != null) {
      _channel!.sink.add(json.encode(jsonrpc));
    }
  }

  addListener(String method, Function callback, [bool notice = false]) {
    _listeners[method] = [callback, notice];
  }

  removeListener(String method) {
    _listeners.remove(method);
  }

  onSuccess(data) {
    print('onSuccess');
    jsonrpc["event"] = 'pusher:subscribe';
    jsonrpc["data"] = {"channel": session};

    if (_channel != null) {
      _channel!.sink.add(json.encode(jsonrpc));
    }
  }

  _onReceptionOfMessageFromServer(message) {
    Map response = json.decode(message);
    // print(response);

    if (response["data"] != null && response["event"] != null) {
      String method = response["event"];
      Object params = response["data"];

      if (method == 'pusher:connection_established') {
        onSuccess(params);
      } else if (_listeners[method] != null) {
        final callbacks = _listeners[method]!;
        try {
          callbacks[0](params);
        } catch (e) {
          print('function is unvalid');
        }
      } else {
        print("has no this " + method);
      }
    }
  }
}
