
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/installment_model.dart'; // We need this model

class PaymentsRepository {
  final SupabaseClient _supabase;

  PaymentsRepository(this._supabase);

  // Fetch payments related to a specific project.
  // This is complex because installments are linked to subscriptions, not directly to projects.
  Future<List<Map<String, dynamic>>> getProjectPayments(String projectId) async {
    try {
      // Fetch installments where the associated subscription belongs to the project
      // We use Supabase's relational query capabilities.
      // Note: 'installments' -> 'subscription_id' -> 'subscriptions' -> 'project_id'
      final response = await _supabase
          .from('installments')
          .select('*, subscriptions!inner(id, project_id, user_id, profiles(full_name))')
          .eq('subscriptions.project_id', projectId)
          .order('due_date', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch project payments: $e');
    }
  }

  // Fetch payments for a specific user in a project (for Client view)
  Future<List<Map<String, dynamic>>> getUserProjectPayments(String userId, String projectId) async {
    try {
      final response = await _supabase
          .from('installments')
          .select('*, subscriptions!inner(id, project_id)')
          .eq('user_id', userId)
          .eq('subscriptions.project_id', projectId)
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user payments: $e');
    }
  }
}
