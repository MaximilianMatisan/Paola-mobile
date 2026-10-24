
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:paola_mobile/core/network/api_client.dart';

class AuthApi {

  final Dio _dio = ApiClient.instance.dio;

  Future<Response> login({
    required String username,
    required String password
  }) async {
    return await _dio.post(
      '/paola/api/auth/login',
      data: {
        'username': username,
        'password': password
      }
    );
  }
}