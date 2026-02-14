import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/services/contract_service.dart';
import 'package:mmm/data/models/contract_model.dart';

part 'contracts_management_state.dart';

class ContractsManagementCubit extends Cubit<ContractsManagementState> {
  final ContractService _contractService = ContractService();

  ContractsManagementCubit() : super(ContractsManagementInitial());

  Future<void> loadContracts({
    String? status,
    String? subscriptionId,
    String? userId,
  }) async {
    try {
      emit(ContractsManagementLoading());

      final contracts = await _contractService.getContracts(
        status: status,
        subscriptionId: subscriptionId,
        userId: userId,
      );

      emit(ContractsManagementLoaded(contracts: contracts));
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> loadContractById(String id) async {
    try {
      emit(ContractsManagementLoading());

      final contract = await _contractService.getContractById(id);

      if (contract != null) {
        emit(ContractDetailLoaded(contract: contract));
      } else {
        emit(const ContractsManagementError(message: 'العقد غير موجود'));
      }
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> loadContractTemplates({String? type}) async {
    try {
      emit(ContractsManagementLoading());

      final templates = await _contractService.getContractTemplates(
        type: type,
        isActive: true,
      );

      emit(ContractTemplatesLoaded(templates: templates));
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> createContractFromTemplate({
    required String subscriptionId,
    required String templateId,
    required String userId,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      emit(ContractsManagementCreating());

      final contract = await _contractService.createContractFromTemplate(
        subscriptionId: subscriptionId,
        templateId: templateId,
        userId: userId,
        customFields: customFields,
      );

      emit(ContractCreatedSuccessfully(contract: contract));

      // Reload all contracts
      await loadContracts();
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> createManualContract({
    required String userId,
    String? projectId,
    required String title,
    required String content,
    required String contractNumber,
    double? amount,
    Map<String, dynamic>? terms,
  }) async {
    try {
      emit(ContractsManagementCreating());

      final contract = await _contractService.createManualContract(
        userId: userId,
        projectId: projectId,
        title: title,
        content: content,
        contractNumber: contractNumber,
        amount: amount,
        terms: terms,
      );

      emit(ContractCreatedSuccessfully(contract: contract));

      // Reload all contracts
      await loadContracts();
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> signContract({
    required String contractId,
    required String userId,
    required String signatureData,
  }) async {
    try {
      emit(ContractsManagementLoading());

      await _contractService.signContract(
        contractId: contractId,
        userId: userId,
        signatureData: signatureData,
      );

      emit(const ContractSignedSuccessfully());

      // Reload contract details
      await loadContractById(contractId);
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> updateContractStatus({
    required String contractId,
    required String status,
  }) async {
    try {
      emit(ContractsManagementLoading());

      await _contractService.updateContractStatus(
        contractId: contractId,
        status: status,
      );

      emit(const ContractUpdatedSuccessfully());

      // Reload all contracts
      await loadContracts();
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> updateContract({
    required String contractId,
    String? title,
    String? content,
    double? amount,
    Map<String, dynamic>? terms,
  }) async {
    try {
      emit(ContractsManagementLoading());

      await _contractService.updateContract(
        contractId: contractId,
        title: title,
        content: content,
        amount: amount,
        terms: terms,
      );

      emit(const ContractUpdatedSuccessfully());

      // Reload all contracts
      await loadContracts();
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> deleteContract(String id) async {
    try {
      emit(ContractsManagementLoading());

      await _contractService.deleteContract(id);

      emit(const ContractDeletedSuccessfully());

      // Reload all contracts
      await loadContracts();
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }

  Future<void> loadContractStats() async {
    try {
      final stats = await _contractService.getContractsStats();
      emit(ContractStatsLoaded(stats: stats));
    } catch (e) {
      emit(ContractsManagementError(message: e.toString()));
    }
  }
}
