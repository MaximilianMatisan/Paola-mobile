
import 'package:dio/dio.dart';
import 'package:interactive_notifications/core/network/api_exception.dart';
import 'package:interactive_notifications/core/network/paola_api.dart';

import 'auth_api.dart';

class AuthRepository {
  final AuthApi _authApi = AuthApi();

  Future<void> login({
    required String username,
    required String password
  }) async {
    try {
      final response = await _authApi.login(username: username, password: password);
      //TODO convert response to model
      //for now just print!
      print(response);
      // Keep the session so PaolaApi can make authenticated requests.
      await PaolaApi.instance.takeSessionCookie(
        response.headers['set-cookie']?.join('; '),
      );
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'];
      if (errorMsg is String) {
        throw ApiException(message: errorMsg);
      }
      throw const ApiException(message: 'Error while logging in');
    }
  }
}