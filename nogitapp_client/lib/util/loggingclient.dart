import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoggingClient extends http.BaseClient {
  final http.Client _inner;
  LoggingClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    debugPrint('→ ${request.method} ${request.url}');
    if (request is http.Request) debugPrint('  body: ${request.body}');
    final resp = await _inner.send(request);
    final body = await resp.stream.bytesToString();
    debugPrint('← ${resp.statusCode} ${request.url}');
    debugPrint('  resp: $body');
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)), resp.statusCode,
      headers: resp.headers, request: resp.request);
  }
}
