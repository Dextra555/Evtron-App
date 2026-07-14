import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evtron/Service/station_service.dart';

class _FakeClient implements http.Client {
  _FakeClient(this.response);

  final http.Response response;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return response;
  }

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }

  @override
  void close() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'auth_token': 'valid-token'});
    await SharedPreferences.getInstance();
  });

  group('StationService', () {
    test('throws an auth exception for a 403 invalid token response', () async {
      final service = StationService(
        httpClient: _FakeClient(
          http.Response(
            jsonEncode({'success': false, 'error': 'Invalid token'}),
            403,
          ),
        ),
      );

      expectLater(
        service.fetchStations(),
        throwsA(isA<AuthSessionExpiredException>()),
      );
    });
  });
}
