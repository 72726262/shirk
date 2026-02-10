import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _supabase;

  SupabaseService._internal();

  factory SupabaseService() {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  static SupabaseService get instance {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  SupabaseClient get client {
    if (_supabase == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _supabase!;
  }

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _supabase = Supabase.instance.client;
  }

  // Auth helpers
  User? get currentUser => _supabase?.auth.currentUser;
  String? get currentUserId => _supabase?.auth.currentUser?.id;
  bool get isAuthenticated => _supabase?.auth.currentUser != null;

  // Storage - Upload file from path
  Future<String> uploadFile({
    required String bucketName,
    required String path,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      await client.storage.from(bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
        ),
      );
      
      return client.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  // Storage - Upload bytes directly
  Future<String> uploadBytes({
    required String bucketName,
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    try {
      final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      await client.storage.from(bucketName).uploadBinary(
        path,
        uint8List,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );
      
      return client.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload bytes: ${e.toString()}');
    }
  }

  // Storage - Delete file by URL or path
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Extract bucket and path from URL
      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;
      
      if (segments.length < 3) {
        throw Exception('Invalid file URL');
      }
      
      // URL format: .../storage/v1/object/public/{bucket}/{path}
      final bucketIndex = segments.indexOf('public') + 1;
      final bucketName = segments[bucketIndex];
      final filePath = segments.sublist(bucketIndex + 1).join('/');
      
      await client.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  // Storage - Get public URL
  String getPublicUrl({
    required String bucketName,
    required String path,
  }) {
    return client.storage.from(bucketName).getPublicUrl(path);
  }

  // Storage - Download file
  Future<List<int>> downloadFile({
    required String bucketName,
    required String path,
  }) async {
    try {
      final bytes = await client.storage.from(bucketName).download(path);
      return bytes;
    } catch (e) {
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  // Database - Execute RPC function
  Future<dynamic> executeRpc(String functionName, {Map<String, dynamic>? params}) async {
    try {
      return await client.rpc(functionName, params: params);
    } catch (e) {
      throw Exception('Failed to execute RPC: ${e.toString()}');
    }
  }

  // Database - Subscribe to table changes
  RealtimeChannel subscribeToTable({
    required String table,
    required void Function(PostgresChangePayload) onInsert,
    void Function(PostgresChangePayload)? onUpdate,
    void Function(PostgresChangePayload)? onDelete,
  }) {
    final channel = client.channel('public:$table');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: table,
      callback: (payload) => onInsert(payload),
    );

    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: (payload) => onUpdate(payload),
      );
    }

    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: (payload) => onDelete(payload),
      );
    }

    channel.subscribe();
    return channel;
  }
}

