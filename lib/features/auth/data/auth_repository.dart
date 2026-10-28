
import 'package:dio/dio.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/network/api_exception.dart';
import 'package:paola_mobile/core/network/paola_api.dart';

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
      final data = e.response?.data;
      final errorMsg = data is Map ? data['error'] : null;
      if (errorMsg is String) {
        throw ApiException(message: errorMsg);
      }
      // Surface the cause (connection refused, sandbox, wrong URL, ...).
      final status = e.response?.statusCode;
      throw ApiException(
        message:
            '${AppLanguage.t.errorLogin} (${e.type.name}'
            '${status != null ? ', HTTP $status' : ''}): '
            '${e.message ?? e.error} – ${e.requestOptions.uri}',
      );
    }
  }
}