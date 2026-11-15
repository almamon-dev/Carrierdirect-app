import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/chat_message_model.dart';

class ChatRemoteDataSource {
  static final ChatRemoteDataSource _instance =
      ChatRemoteDataSource._internal();
  factory ChatRemoteDataSource() => _instance;
  ChatRemoteDataSource._internal();

  final SecureStorage _secureStorage = SecureStorage();

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final token = await _secureStorage.read(AppConstants.keyAuthToken);
    return {
      if (isJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<Map<String, dynamic>> _extractList(dynamic body) {
    if (body == null) return [];
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (body is Map) {
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (data is Map) {
        if (data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (data['messages'] is List) {
          return (data['messages'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (data['items'] is List) {
          return (data['items'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      if (body['messages'] is List) {
        return (body['messages'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return [];
  }

  /// Send online presence heartbeat (`POST /messages/heartbeat`)
  Future<void> sendHeartbeat() async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return;
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.chatHeartbeat}',
      );
      await http
          .post(uri, headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  /// Fetch paginated conversations (`GET /messages/conversations`)
  Future<List<Map<String, dynamic>>> getConversations({
    int page = 1,
    int perPage = 50,
    String? search,
    String? filter,
  }) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return [];

      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (filter != null && filter.trim().isNotEmpty) 'filter': filter.trim(),
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.chatConversations}',
      ).replace(queryParameters: queryParams);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final dynamic decoded = jsonDecode(res.body);
        return _extractList(decoded);
      }
    } catch (_) {}
    return [];
  }

  /// Fetch directory contacts from assigned orders (`GET /messages/users`)
  Future<List<Map<String, dynamic>>> getDirectoryUsers({
    String? search,
    String? role,
  }) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return [];

      final queryParams = <String, String>{
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.chatDirectoryUsers}',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final dynamic decoded = jsonDecode(res.body);
        return _extractList(decoded);
      }
    } catch (_) {}
    return [];
  }

  /// Fetch all messages with a specific partner (`GET /messages/conversations/{partnerId}`)
  Future<List<ChatMessage>> getMessages(
    int partnerId, {
    String partnerName = 'Partner',
    String shipmentId = '',
    MessageSenderRole partnerRole = MessageSenderRole.customerReceiver,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return [];

      final queryParams = <String, String>{
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.chatConversations}/$partnerId',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final dynamic decoded = jsonDecode(res.body);
        final rawList = _extractList(decoded);
        return rawList
            .map(
              (m) => ChatMessage.fromJson(
                m,
                partnerName: partnerName,
                shipmentId: shipmentId,
                partnerRole: partnerRole,
              ),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Send a text or file/photo message (`POST /messages/send`)
  Future<ChatMessage?> sendMessage({
    required int receiverId,
    String? message,
    int? replyToId,
    List<String>? filePaths,
    String partnerName = 'Partner',
    String shipmentId = '',
    MessageSenderRole partnerRole = MessageSenderRole.customerReceiver,
  }) async {
    try {
      final hasFiles = filePaths != null && filePaths.isNotEmpty;
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.chatSendMessage}',
      );

      if (!hasFiles) {
        final headers = await _getHeaders(isJson: true);
        if (!headers.containsKey('Authorization')) return null;

        final payload = <String, dynamic>{
          'receiver_id': receiverId,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
          'reply_to_id': ?replyToId,
        };

        final res = await http
            .post(uri, headers: headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 15));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final dynamic decoded = jsonDecode(res.body);
          final dataMap = (decoded is Map && decoded['data'] is Map)
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : (decoded is Map ? Map<String, dynamic>.from(decoded) : null);
          if (dataMap != null) {
            return ChatMessage.fromJson(
              dataMap,
              partnerName: partnerName,
              shipmentId: shipmentId,
              partnerRole: partnerRole,
            );
          }
        }
        return null;
      }

      // Multipart upload for photos & documents
      final headers = await _getHeaders(isJson: false);
      if (!headers.containsKey('Authorization')) return null;

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.fields['receiver_id'] = receiverId.toString();
      if (message != null && message.trim().isNotEmpty) {
        request.fields['message'] = message.trim();
      }
      if (replyToId != null) {
        request.fields['reply_to_id'] = replyToId.toString();
      }

      for (final path in filePaths) {
        if (path.isNotEmpty && File(path).existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath('attachments[]', path),
          );
        }
      }

      final streamedRes = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final resBody = await streamedRes.stream.bytesToString();

      if (streamedRes.statusCode >= 200 && streamedRes.statusCode < 300) {
        final dynamic decoded = jsonDecode(resBody);
        final dataMap = (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : (decoded is Map ? Map<String, dynamic>.from(decoded) : null);
        if (dataMap != null) {
          return ChatMessage.fromJson(
            dataMap,
            partnerName: partnerName,
            shipmentId: shipmentId,
            partnerRole: partnerRole,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mark all unread messages from a partner as read (`POST /messages/conversations/{partnerId}/read`)
  Future<bool> markAsRead(int partnerId) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return false;

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.chatConversations}/$partnerId/read',
      );
      final res = await http
          .post(uri, headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Edit a sent message (`PUT /messages/{messageId}`)
  Future<ChatMessage?> updateMessage(
    int messageId,
    String newText, {
    String partnerName = 'Partner',
    String shipmentId = '',
  }) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return null;

      final uri = Uri.parse('${ApiConstants.baseUrl}/messages/$messageId');
      final res = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode({'message': newText.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final dynamic decoded = jsonDecode(res.body);
        final dataMap = (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : null;
        if (dataMap != null) {
          return ChatMessage.fromJson(
            dataMap,
            partnerName: partnerName,
            shipmentId: shipmentId,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Toggle pin on a message (`PATCH /messages/{messageId}/pin`)
  Future<ChatMessage?> togglePin(
    int messageId, {
    String partnerName = 'Partner',
    String shipmentId = '',
  }) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return null;

      final uri = Uri.parse('${ApiConstants.baseUrl}/messages/$messageId/pin');
      final res = await http
          .patch(uri, headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final dynamic decoded = jsonDecode(res.body);
        final dataMap = (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : null;
        if (dataMap != null) {
          return ChatMessage.fromJson(
            dataMap,
            partnerName: partnerName,
            shipmentId: shipmentId,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Delete or unsend a message (`DELETE /messages/{messageId}?type=everyone|for_me`)
  Future<bool> deleteMessage(
    int messageId, {
    String type = 'everyone',
  }) async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return false;

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/messages/$messageId',
      ).replace(queryParameters: {'type': type});

      final res = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Get total unread message count (`GET /messages/unread-count`)
  Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return 0;

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.chatUnreadCount}',
      );
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final dynamic decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['data'] is Map) {
          return int.tryParse(
                (decoded['data']['unread_count'] ?? '0').toString(),
              ) ??
              0;
        }
      }
    } catch (_) {}
    return 0;
  }
}
