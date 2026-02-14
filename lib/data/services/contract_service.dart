import 'package:mmm/data/repositories/contract_repository.dart';
import 'package:mmm/data/models/contract_model.dart';

class ContractService {
  final ContractRepository _contractRepository = ContractRepository();

  /// Get all contracts with optional filters
  Future<List<ContractModel>> getContracts({
    String? status,
    String? subscriptionId,
    String? userId,
  }) async {
    try {
      return await _contractRepository.getContracts(
        status: status,
        subscriptionId: subscriptionId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('فشل تحميل العقود: ${e.toString()}');
    }
  }

  /// Get contracts stream
  Stream<List<ContractModel>> getContractsStream({
    String? status,
    String? subscriptionId,
    String? userId,
  }) {
    return _contractRepository.getContractsStream(
      status: status,
      subscriptionId: subscriptionId,
      userId: userId,
    );
  }

  /// Get contract by ID
  Future<ContractModel?> getContractById(String id) async {
    try {
      return await _contractRepository.getContractById(id);
    } catch (e) {
      throw Exception('فشل تحميل العقد: ${e.toString()}');
    }
  }

  /// Get contract templates
  Future<List<Map<String, dynamic>>> getContractTemplates({
    String? type,
    bool? isActive,
  }) async {
    try {
      return await _contractRepository.getContractTemplates(
        type: type,
        isActive: isActive,
      );
    } catch (e) {
      throw Exception('فشل تحميل قوالب العقود: ${e.toString()}');
    }
  }

  /// Create contract from template
  Future<ContractModel> createContractFromTemplate({
    required String subscriptionId,
    required String templateId,
    required String userId,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      return await _contractRepository.createContractFromTemplate(
        subscriptionId: subscriptionId,
        templateId: templateId,
        userId: userId,
        customFields: customFields,
      );
    } catch (e) {
      throw Exception('فشل إنشاء العقد: ${e.toString()}');
    }
  }

  /// Create manual contract
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
      return await _contractRepository.createManualContract(
        userId: userId,
        projectId: projectId,
        title: title,
        content: content,
        contractNumber: contractNumber,
        amount: amount,
        terms: terms,
      );
    } catch (e) {
      throw Exception('فشل إنشاء العقد اليدوي: ${e.toString()}');
    }
  }

  /// Sign contract
  Future<void> signContract({
    required String contractId,
    required String userId,
    required String signatureData,
  }) async {
    try {
      await _contractRepository.signContract(
        contractId: contractId,
        userId: userId,
        signatureData: signatureData,
      );
    } catch (e) {
      throw Exception('فشل توقيع العقد: ${e.toString()}');
    }
  }

  /// Update contract status
  Future<void> updateContractStatus({
    required String contractId,
    required String status,
  }) async {
    try {
      await _contractRepository.updateContractStatus(
        contractId: contractId,
        status: status,
      );
    } catch (e) {
      throw Exception('فشل تحديث حالة العقد: ${e.toString()}');
    }
  }

  /// Update contract details
  Future<ContractModel> updateContract({
    required String contractId,
    String? title,
    String? content,
    double? amount,
    Map<String, dynamic>? terms,
  }) async {
    try {
      return await _contractRepository.updateContract(
        contractId: contractId,
        title: title,
        content: content,
        amount: amount,
        terms: terms,
      );
    } catch (e) {
      throw Exception('فشل تحديث العقد: ${e.toString()}');
    }
  }

  /// Delete contract
  Future<void> deleteContract(String id) async {
    try {
      await _contractRepository.deleteContract(id);
    } catch (e) {
      throw Exception('فشل حذف العقد: ${e.toString()}');
    }
  }

  /// Get contracts statistics
  Future<Map<String, int>> getContractsStats() async {
    try {
      return await _contractRepository.getContractsCountByStatus();
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات العقود: ${e.toString()}');
    }
  }
}
