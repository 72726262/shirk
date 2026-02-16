import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class UnitsRepository {
  final SupabaseService _supabaseService;

  UnitsRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  Future<List<UnitModel>> getUnits({String? projectId}) async {
    try {
      var query = _client.from('units').select();
      
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }
      
      final response = await query.order('unit_number', ascending: true); // Alphanumeric sort
      
      return (response as List)
          .map((json) => UnitModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load units: ${e.toString()}');
    }
  }

  Future<String> getNextUnitNumber(String projectId) async {
    try {
      // Fetch all unit numbers for the project
      final response = await _client
          .from('units')
          .select('unit_number')
          .eq('project_id', projectId);
      
      if ((response as List).isEmpty) return '1';

      int maxNum = 0;
      for (var item in response) {
        final numStr = item['unit_number'].toString();
        final numVal = int.tryParse(numStr);
        if (numVal != null && numVal > maxNum) {
          maxNum = numVal;
        }
      }
      return (maxNum + 1).toString();
    } catch (e) {
      // Fallback or error, returning '1' is safe if fetch fails/no numeric units
      return '1';
    }
  }

  Future<UnitModel> addUnit(UnitModel unit) async {
    try {
      final unitData = unit.toJson();
      // Remove ID to let Supabase generate it
      unitData.remove('id');
      unitData.remove('created_at');
      unitData.remove('updated_at');

      final response = await _client
          .from('units')
          .insert(unitData)
          .select()
          .single();

      return UnitModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add unit: ${e.toString()}');
    }
  }

  Future<UnitModel> updateUnit(UnitModel unit) async {
    try {
      final unitData = unit.toJson();
      unitData.remove('id');
      unitData.remove('created_at');
      unitData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('units')
          .update(unitData)
          .eq('id', unit.id)
          .select()
          .single();

      return UnitModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update unit: ${e.toString()}');
    }
  }

  Future<void> deleteUnit(String unitId) async {
    try {
      await _client.from('units').delete().eq('id', unitId);
    } catch (e) {
      throw Exception('Failed to delete unit: ${e.toString()}');
    }
  }
}
