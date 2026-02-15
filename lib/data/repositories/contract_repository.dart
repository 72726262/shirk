import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/contract_model.dart';

class ContractRepository {
  final _supabase = Supabase.instance.client;

  // ========== FUTURE-BASED METHODS (Original) ==========

  Future<List<ContractModel>> getContracts({
    String? status,
    String? subscriptionId,
    String? userId,
  }) async {
    try {
      var query = _supabase.from('contracts').select('*');

      if (status != null) {
        query = query.eq('status', status);
      }
      if (subscriptionId != null) {
        query = query.eq('subscription_id', subscriptionId);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final data = await query.order('created_at', ascending: false);
      
      return (data as List)
          .map((json) => ContractModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch contracts: ${e.toString()}');
    }
  }

  Future<ContractModel?> getContractById(String id) async {
    try {
      final data = await _supabase
          .from('contracts')
          .select('*')
          .eq('id', id)
          .single();

      return ContractModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch contract: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getContractTemplates({
    String? type,
    bool? isActive,
  }) async {
    try {
      var query = _supabase.from('contract_templates').select();

      if (type != null) {
        query = query.eq('type', type);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      return await query.order('created_at', ascending: false);
    } catch (e) {
      throw Exception('Failed to fetch contract templates: ${e.toString()}');
    }
  }

  Future<ContractModel> createContractFromTemplate({
    required String subscriptionId,
    required String templateId,
    required String userId,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      final template = await _supabase
          .from('contract_templates')
          .select()
          .eq('id', templateId)
          .single();

      final data = await _supabase.from('contracts').insert({
        'subscription_id': subscriptionId,
        'template_id': templateId,
        'user_id': userId,
        'content': template['content'],
        'terms': template['terms'],
        'status': 'draft',
        'custom_fields': customFields,
      }).select('*').single();

      return ContractModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create contract: ${e.toString()}');
    }
  }

  Future<ContractModel> createManualContract({
    required String userId,
    String? projectId,
    required String title,
    required String content,
    required String contractNumber,
    double? amount,
    Map<String, dynamic>? terms,
  }) async {
    try {
      final data = await _supabase.from('contracts').insert({
        'user_id': userId,
        'project_id': projectId,
        'title': title,
        'content': content,
        'contract_number': contractNumber,
        'status': 'draft',
        'terms': terms ?? {},
      }).select('*').single();

      return ContractModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create manual contract: ${e.toString()}');
    }
  }

  Future<void> signContract({
    required String contractId,
    required String userId,
    required String signatureData,
  }) async {
    try {
      await _supabase.from('contracts').update({
        'status': 'signed',
        'signed_at': DateTime.now().toIso8601String(),
        'signature_data': signatureData,
      }).eq('id', contractId);
    } catch (e) {
      throw Exception('Failed to sign contract: ${e.toString()}');
    }
  }

  Future<void> updateContractStatus({
    required String contractId,
    required String status,
  }) async {
    try {
      await _supabase.from('contracts').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', contractId);
    } catch (e) {
      throw Exception('Failed to update contract status: ${e.toString()}');
    }
  }

  Future<ContractModel> updateContract({
    required String contractId,
    String? title,
    String? content,
    double? amount,
    Map<String, dynamic>? terms,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      if (terms != null) updates['terms'] = terms;

      final data = await _supabase
          .from('contracts')
          .update(updates)
          .eq('id', contractId)
          .select('*')
          .single();

      return ContractModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update contract: ${e.toString()}');
    }
  }

  Future<void> deleteContract(String id) async {
    try {
      await _supabase.from('contracts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete contract: ${e.toString()}');
    }
  }

  Future<Map<String, int>> getContractsCountByStatus() async {
    try {
      final data = await _supabase
          .from('contracts')
          .select('status')
          .order('status');

      final Map<String, int> counts = {};
      for (final item in data) {
        final status = item['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get contracts count: ${e.toString()}');
    }
  }

  // ========== STREAM-BASED METHODS (Real-time) ==========

  /// Get contracts stream (already exists) ✅
  Stream<List<ContractModel>> getContractsStream({
    String? status,
    String? subscriptionId,
    String? userId,
  }) {
    return _supabase
        .from('contracts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          var filtered = data;

          if (status != null) {
            filtered = filtered
                .where((json) => json['status'] == status)
                .toList();
          }
          if (subscriptionId != null) {
            filtered = filtered
                .where((json) => json['subscription_id'] == subscriptionId)
                .toList();
          }
          if (userId != null) {
            filtered = filtered
                .where((json) => json['user_id'] == userId)
                .toList();
          }

          return filtered.map((json) => ContractModel.fromJson(json)).toList();
        });
  }

  /// Get single contract by ID with real-time updates
  Stream<ContractModel> getContractByIdStream(String id) {
    return _supabase
        .from('contracts')
        .stream(primaryKey: ['id'])
        .map((data) {
          final contract = data.firstWhere(
            (c) => c['id'] == id,
            orElse: () => throw Exception('Contract not found'),
          );
          return ContractModel.fromJson(contract);
        });
  }

  /// Get contract templates with real-time updates
  Stream<List<Map<String, dynamic>>> getContractTemplatesStream({
    String? type,
    bool? isActive,
  }) {
    return _supabase
        .from('contract_templates')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      var filtered = data;

      if (type != null) {
        filtered = filtered.where((t) => t['type'] == type).toList();
      }
      if (isActive != null) {
        filtered = filtered.where((t) => t['is_active'] == isActive).toList();
      }

      return filtered.map((json) => Map<String, dynamic>.from(json)).toList();
    });
  }

  /// Get contracts count by status with real-time updates
  Stream<Map<String, int>> getContractsCountByStatusStream() {
    return _supabase
        .from('contracts')
        .stream(primaryKey: ['id'])
        .map((data) {
      final Map<String, int> counts = {};
      for (final item in data) {
        final status = item['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    });
  }
}
