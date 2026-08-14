import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app_globals.dart';

export 'package:http/http.dart' show Client, Response, BaseRequest, StreamedResponse, ClientException;

class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = NetworkService.noInternetMessage]);

  @override
  String toString() => message;
}

Future<http.Response> get(
  Uri url, {
  Map<String, String>? headers,
  Duration timeout = NetworkService.defaultTimeout,
}) {
  return NetworkService.get(url, headers: headers, timeout: timeout);
}

Future<http.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = NetworkService.defaultTimeout,
}) {
  return NetworkService.post(
    url,
    headers: headers,
    body: body,
    encoding: encoding,
    timeout: timeout,
  );
}

Future<http.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = NetworkService.defaultTimeout,
}) {
  return NetworkService.put(
    url,
    headers: headers,
    body: body,
    encoding: encoding,
    timeout: timeout,
  );
}

Future<http.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = NetworkService.defaultTimeout,
}) {
  return NetworkService.patch(
    url,
    headers: headers,
    body: body,
    encoding: encoding,
    timeout: timeout,
  );
}

Future<http.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = NetworkService.defaultTimeout,
}) {
  return NetworkService.delete(
    url,
    headers: headers,
    body: body,
    encoding: encoding,
    timeout: timeout,
  );
}

class NetworkService {
  static final http.Client _client = http.Client();
  static bool _noInternetSnackbarShown = false;

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const String noInternetMessage =
      'No internet connection. Please check your network and try again.';

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = defaultTimeout,
  }) async {
    return _send(() => _client.get(url, headers: headers), timeout);
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = defaultTimeout,
  }) async {
    return _send(
      () => _client.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      ),
      timeout,
    );
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = defaultTimeout,
  }) async {
    return _send(
      () => _client.put(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      ),
      timeout,
    );
  }

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = defaultTimeout,
  }) async {
    return _send(
      () => _client.patch(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      ),
      timeout,
    );
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = defaultTimeout,
  }) async {
    return _send(
      () => _client.delete(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      ),
      timeout,
    );
  }

  static Future<T> _send<T>(Future<T> Function() request, Duration timeout) async {
    try {
      final result = await request().timeout(timeout);
      return result;
    } on TimeoutException catch (error, stackTrace) {
      _handleNetworkError(error, stackTrace);
      throw NetworkException(noInternetMessage);
    } on SocketException catch (error, stackTrace) {
      _handleNetworkError(error, stackTrace);
      throw NetworkException(noInternetMessage);
    } on http.ClientException catch (error, stackTrace) {
      if (_isClientExceptionNetworkError(error)) {
        _handleNetworkError(error, stackTrace);
        throw NetworkException(noInternetMessage);
      }
      rethrow;
    } on OSError catch (error, stackTrace) {
      if (_isNetworkRelatedOSError(error)) {
        _handleNetworkError(error, stackTrace);
        throw NetworkException(noInternetMessage);
      }
      rethrow;
    } catch (error, stackTrace) {
      if (_isNetworkRelatedException(error)) {
        _handleNetworkError(error, stackTrace);
        throw NetworkException(noInternetMessage);
      }
      rethrow;
    }
  }

  static bool _isNetworkRelatedOSError(OSError error) {
    final message = error.message?.toLowerCase() ?? '';
    return message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connection timed out') ||
        message.contains('connection refused') ||
        message.contains('name or service not known');
  }

  static bool _isNetworkRelatedException(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('connection refused') ||
        text.contains('socketexception') ||
        text.contains('connection timed out') ||
        text.contains('connection timeout') ||
        text.contains('network is unreachable') ||
        text.contains('network unavailable') ||
        text.contains('no internet connection') ||
        text.contains('certificate handshake') ||
        text.contains('network error');
  }

  static bool _isNetworkError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException && _isClientExceptionNetworkError(error) ||
        error is OSError && _isNetworkRelatedOSError(error) ||
        _isNetworkRelatedException(error);
  }

  static bool _isClientExceptionNetworkError(http.ClientException exception) {
    final message = exception.message.toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('no address associated with hostname') ||
        message.contains('connection refused') ||
        message.contains('connection timed out') ||
        message.contains('socketexception') ||
        message.contains('network is unreachable') ||
        message.contains('network unavailable') ||
        message.contains('no internet connection');
  }

  static void _handleNetworkError(Object error, StackTrace stackTrace) {
    print('❌ Network request failed: $error');
    print('Stack trace: $stackTrace');
  }
}
