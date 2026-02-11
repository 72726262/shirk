import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/contract_model.dart';

class ContractRepository {
  final _supabase = Supabase.instance.client;

  // Get all contracts with filters
  Future<List<ContractModel>> getContracts({
    String? status,
    String? subscriptionId,
    String? userId,
  }) async {
    try {
      var query = _supabase
          .from('contracts')
          .select('''
            *,
            subscription:subscriptions(
              *,
              project:projects(*),
              user:profiles(*)
            )
          ''');

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

  // Get contract by ID
  Future<ContractModel?> getContractById(String id) async {
    try {
      final data = await _supabase
          .from('contracts')
          .select('''
            *,
            subscription:subscriptions(
              *,
              project:projects(*),
              user:profiles(*)
            )
          ''')
          .eq('id', id)
          .single();

      return ContractModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch contract: ${e.toString()}');
    }
  }

  // Get contract templates
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

  // Create contract from template
  Future<ContractModel> createContractFromTemplate({
    required String subscriptionId,
    required String templateId,
    required String userId,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      // Get template
      final template = await _supabase
          .from('contract_templates')
          .select()
          .eq('id', templateId)
          .single();

      // Create contract
      final data = await _supabase.from('contracts').insert({
        'subscription_id': subscriptionId,
        'template_id': templateId,
        'user_id': userId,
        'content': template['content'],
        'terms': template['terms'],
        'status': 'draft',
        'custom_fields': customFields,
      }).select('''
        *,
        subscription:subscriptions(
          *,
          project:projects(*),
          user:profiles(*)
        )
      ''').single();

      return ContractModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create contract: ${e.toString()}');
    }
  }

  // Sign contract
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

  // Update contract status
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

  // Delete contract
  Future<void> deleteContract(String id) async {
    try {
      await _supabase.from('contracts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete contract: ${e.toString()}');
    }
  }

  // Get contracts count by status
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
}
