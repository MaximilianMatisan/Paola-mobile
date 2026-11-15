import 'package:dio/dio.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/network/api_exception.dart';
import 'package:paola_mobile/core/network/paola_api.dart';

import 'auth_api.dart';

class AuthRepository {
  final AuthApi _authApi = AuthApi();

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _authenticate(
      () => _authApi.login(username: username, password: password),
      failed: AppLanguage.t.errorLogin,
    );
    //TODO convert response to model
    //for now just print!
    print(response);
  }

  Future<void> register({
    required String username,
    required String password,
    String? code,
  }) async {
    final trimmed = code?.trim();
    await _authenticate(
      () => _authApi.register(
        username: username,
        password: password,
        code: trimmed == null || trimmed.isEmpty ? null : trimmed,
      ),
      failed: AppLanguage.t.errorRegister,
    );
  }

  /// Sends a login or register [request] and keeps the session it answers
  /// with, so PaolaApi can make authenticated requests. Errors become an
  /// [ApiException]: the web app's own message, or [failed] with the cause.
  Future<Response> _authenticate(
    Future<Response> Function() request, {
    required String failed,
  }) async {
    try {
      final response = await request();
      await PaolaApi.instance.takeSessionCookie(
        response.headers['set-cookie']?.join('; '),
      );
      return response;
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
            '$failed (${e.type.name}'
            '${status != null ? ', HTTP $status' : ''}): '
            '${e.message ?? e.error} – ${e.requestOptions.uri}',
      );
    }
  }
}
