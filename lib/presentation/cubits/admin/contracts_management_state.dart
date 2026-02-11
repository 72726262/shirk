part of 'contracts_management_cubit.dart';

abstract class ContractsManagementState extends Equatable {
  const ContractsManagementState();

  @override
  List<Object?> get props => [];
}

class ContractsManagementInitial extends ContractsManagementState {}

class ContractsManagementLoading extends ContractsManagementState {}

class ContractsManagementCreating extends ContractsManagementState {}

class ContractsManagementLoaded extends ContractsManagementState {
  final List<ContractModel> contracts;

  const ContractsManagementLoaded({required this.contracts});

  @override
  List<Object?> get props => [contracts];
}

class ContractDetailLoaded extends ContractsManagementState {
  final ContractModel contract;

  const ContractDetailLoaded({required this.contract});

  @override
  List<Object?> get props => [contract];
}

class ContractTemplatesLoaded extends ContractsManagementState {
  final List<Map<String, dynamic>> templates;

  const ContractTemplatesLoaded({required this.templates});

  @override
  List<Object?> get props => [templates];
}

class ContractCreatedSuccessfully extends ContractsManagementState {
  final ContractModel contract;

  const ContractCreatedSuccessfully({required this.contract});

  @override
  List<Object?> get props => [contract];
}

class ContractSignedSuccessfully extends ContractsManagementState {
  const ContractSignedSuccessfully();
}

class ContractUpdatedSuccessfully extends ContractsManagementState {
  const ContractUpdatedSuccessfully();
}

class ContractDeletedSuccessfully extends ContractsManagementState {
  const ContractDeletedSuccessfully();
}

class ContractStatsLoaded extends ContractsManagementState {
  final Map<String, int> stats;

  const ContractStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class ContractsManagementError extends ContractsManagementState {
  final String message;

  const ContractsManagementError({required this.message});

  @override
  List<Object?> get props => [message];
}
