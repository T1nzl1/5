import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override String toString() => message;
}
class NetworkException extends ApiException { const NetworkException([super.message='Сервер недоступен. Проверьте соединение и CORS.']); }
class UnauthorizedException extends ApiException { const UnauthorizedException([super.message='Требуется вход в систему.']); }
class ForbiddenException extends ApiException { const ForbiddenException([super.message='Недостаточно прав для этого действия.']); }
class NotFoundException extends ApiException { const NotFoundException([super.message='Запись не найдена.']); }
class ConflictException extends ApiException { const ConflictException(super.message); }
class ValidationException extends ApiException { final Map<String,String> errors; const ValidationException(super.message,this.errors); }
class ServerException extends ApiException { const ServerException([super.message='Ошибка на сервере. Попробуйте позже.']); }

ApiException mapHttpError(int status, dynamic body) {
  final message = body is Map && body['message'] is String ? body['message'] as String : null;
  return switch(status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(message ?? 'Недостаточно прав для этого действия.'),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна из-за конфликта данных.'),
    422 => ValidationException(message ?? 'Ошибка валидации', body is Map && body['errors'] is Map ? (body['errors'] as Map).map((k,v)=>MapEntry('$k','$v')) : const {}),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}
ApiException mapDioError(DioException e) {
  if (e.error is ApiException) return e.error! as ApiException;
  if (e.response != null) return mapHttpError(e.response!.statusCode ?? 500, e.response!.data);
  return switch(e.type) {
    DioExceptionType.connectionTimeout || DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout => const NetworkException('Сервер не ответил вовремя.'),
    DioExceptionType.connectionError => const NetworkException('Не удалось загрузить данные с сервера. Проверьте подключение и повторите попытку.'),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}
Future<T> guard<T>(Future<T> Function() action) async { try { return await action(); } on DioException catch(e) { throw mapDioError(e); } }
