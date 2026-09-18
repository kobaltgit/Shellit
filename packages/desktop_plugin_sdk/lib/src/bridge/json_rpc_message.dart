import 'package:meta/meta.dart';

/// Standard JSON-RPC 2.0 error codes and Shellit custom codes.
abstract class JsonRpcErrorCodes {
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  /// Custom error: Plugin attempted an action without the required manifest permission.
  static const int permissionDenied = -32003;
}

/// JSON-RPC 2.0 Error object.
@immutable
class JsonRpcError {
  final int code;
  final String message;
  final dynamic data;

  const JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    return JsonRpcError(
      code: json['code'] as int? ?? JsonRpcErrorCodes.internalError,
      message: json['message'] as String? ?? 'Unknown error',
      data: json['data'],
    );
  }

  factory JsonRpcError.permissionDenied(String permission, [String? pluginId]) {
    return JsonRpcError(
      code: JsonRpcErrorCodes.permissionDenied,
      message:
          "Permission denied: Missing permission '$permission'${pluginId != null ? ' for plugin \'$pluginId\'' : ''}",
      data: {
        'requiredPermission': permission,
        if (pluginId != null) 'pluginId': pluginId
      },
    );
  }

  factory JsonRpcError.methodNotFound(String method) {
    return JsonRpcError(
      code: JsonRpcErrorCodes.methodNotFound,
      message: "Method not found: '$method'",
    );
  }

  factory JsonRpcError.invalidRequest([String? details]) {
    return JsonRpcError(
      code: JsonRpcErrorCodes.invalidRequest,
      message: 'Invalid JSON-RPC request${details != null ? ': $details' : ''}',
    );
  }

  factory JsonRpcError.internal(String error) {
    return JsonRpcError(
      code: JsonRpcErrorCodes.internalError,
      message: 'Internal error: $error',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() => 'JsonRpcError(code: $code, message: $message)';
}

/// JSON-RPC 2.0 Request or Notification.
@immutable
class JsonRpcRequest {
  final String jsonrpc;
  final dynamic id;
  final String method;
  final dynamic params;

  const JsonRpcRequest({
    this.jsonrpc = '2.0',
    this.id,
    required this.method,
    this.params,
  });

  bool get isNotification => id == null;

  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) {
    final method = json['method'];
    if (method == null || method is! String) {
      throw const FormatException(
          "JSON-RPC request must contain a string 'method'");
    }
    return JsonRpcRequest(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      id: json['id'],
      method: method,
      params: json['params'],
    );
  }

  Map<String, dynamic> toJson() => {
        'jsonrpc': jsonrpc,
        if (id != null) 'id': id,
        'method': method,
        if (params != null) 'params': params,
      };
}

/// JSON-RPC 2.0 Response.
@immutable
class JsonRpcResponse {
  final String jsonrpc;
  final dynamic id;
  final dynamic result;
  final JsonRpcError? error;

  const JsonRpcResponse({
    this.jsonrpc = '2.0',
    required this.id,
    this.result,
    this.error,
  });

  bool get isSuccess => error == null;

  factory JsonRpcResponse.success(dynamic id, dynamic result) {
    return JsonRpcResponse(id: id, result: result);
  }

  factory JsonRpcResponse.error(dynamic id, JsonRpcError error) {
    return JsonRpcResponse(id: id, error: error);
  }

  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    JsonRpcError? error;
    if (json.containsKey('error') && json['error'] != null) {
      error = JsonRpcError.fromJson(json['error'] as Map<String, dynamic>);
    }
    return JsonRpcResponse(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      id: id,
      result: json['result'],
      error: error,
    );
  }

  Map<String, dynamic> toJson() => {
        'jsonrpc': jsonrpc,
        'id': id,
        if (error != null) 'error': error!.toJson() else 'result': result,
      };
}
