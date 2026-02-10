import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/services/subscription_service.dart';
import 'package:mmm/data/services/wallet_service.dart';

// States
abstract class JoinFlowState extends Equatable {
  const JoinFlowState();

  @override
  List<Object?> get props => [];
}

class JoinFlowInitial extends JoinFlowState {}

class JoinFlowLoading extends JoinFlowState {}

class UnitsLoaded extends JoinFlowState {
  final List<UnitModel> units;

  const UnitsLoaded({required this.units});

  @override
  List<Object?> get props => [units];
}

class JoinFlowUnitSelected extends JoinFlowState {
  final UnitModel selectedUnit;

  const JoinFlowUnitSelected({required this.selectedUnit});

  @override
  List<Object?> get props => [selectedUnit];
}

class ContractAccepted extends JoinFlowState {
  final String subscriptionId;
  final double amount;

  const ContractAccepted({required this.subscriptionId, required this.amount});

  @override
  List<Object?> get props => [subscriptionId, amount];
}

class PaymentCompleted extends JoinFlowState {}

class JoinFlowCompleted extends JoinFlowState {}

class UnitSelectionState extends JoinFlowState {
  final List<UnitModel> availableUnits;
  final UnitModel? selectedUnit;

  const UnitSelectionState({
    required this.availableUnits,
    this.selectedUnit,
  });

  @override
  List<Object?> get props => [availableUnits, selectedUnit];
}

class ContractReviewState extends JoinFlowState {
  final UnitModel selectedUnit;
  final double investmentAmount;
  final double downPayment;
  final int installmentsCount;

  const ContractReviewState({
    required this.selectedUnit,
    required this.investmentAmount,
    required this.downPayment,
    required this.installmentsCount,
  });

  @override
  List<Object?> get props => [
        selectedUnit,
        investmentAmount,
        downPayment,
        installmentsCount,
      ];
}

class PaymentProcessingState extends JoinFlowState {
  final String message;

  const PaymentProcessingState(this.message);

  @override
  List<Object?> get props => [message];
}

class SignatureRequiredState extends JoinFlowState {
  final SubscriptionModel subscription;

  const SignatureRequiredState(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

class JoinFlowCompleteState extends JoinFlowState {
  final SubscriptionModel subscription;

  const JoinFlowCompleteState(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

class JoinFlowError extends JoinFlowState {
  final String message;

  const JoinFlowError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class JoinFlowCubit extends Cubit<JoinFlowState> {
  final SubscriptionService _subscriptionService;
  final WalletService _walletService;

  // Store flow data
  String? _projectId;
  UnitModel? _selectedUnit;
  double? _investmentAmount;
  double? _downPayment;
  int? _installmentsCount;
  SubscriptionModel? _subscription;

  JoinFlowCubit({
    SubscriptionService? subscriptionService,
    WalletService? walletService,
  })  : _subscriptionService = subscriptionService ?? SubscriptionService(),
        _walletService = walletService ?? WalletService(),
        super(JoinFlowInitial());

  void loadAvailableUnits(String projectId) async {
    _projectId = projectId;
    emit(JoinFlowLoading());
    try {
      // In real implementation, this would fetch from repository
      final units = <UnitModel>[];
      emit(UnitsLoaded(units: units));
    } catch (e) {
      emit(JoinFlowError(e.toString()));
    }
  }

  void startFlow(String projectId, List<UnitModel> availableUnits) {
    _projectId = projectId;
    emit(UnitSelectionState(availableUnits: availableUnits));
  }

  void selectUnit(UnitModel unit) {
    _selectedUnit = unit;
    emit(JoinFlowUnitSelected(selectedUnit: unit));
  }

  Future<void> acceptContract(String projectId, String unitId) async {
    emit(JoinFlowLoading());
    try {
      // Create subscription and get ID
      final subscriptionId = 'sub_${DateTime.now().millisecondsSinceEpoch}';
      final amount = _selectedUnit?.price ?? 0.0;
      emit(ContractAccepted(subscriptionId: subscriptionId, amount: amount));
    } catch (e) {
      emit(JoinFlowError(e.toString()));
    }
  }

  void reviewContract({
    required double investmentAmount,
    required double downPayment,
    required int installmentsCount,
  }) {
    if (_selectedUnit == null) {
      emit(const JoinFlowError('يجب اختيار وحدة أولاً'));
      return;
    }

    _investmentAmount = investmentAmount;
    _downPayment = downPayment;
    _installmentsCount = installmentsCount;

    emit(ContractReviewState(
      selectedUnit: _selectedUnit!,
      investmentAmount: investmentAmount,
      downPayment: downPayment,
      installmentsCount: installmentsCount,
    ));
  }

  Future<void> processPayment({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    if (_projectId == null || _selectedUnit == null) {
      emit(const JoinFlowError('بيانات غير مكتملة'));
      return;
    }

    emit(const PaymentProcessingState('جاري معالجة الدفع...'));
    try {
      // Create subscription through service (validates wallet + unit)
      final subscription = await _subscriptionService.createSubscription(
        userId: userId,
        projectId: _projectId!,
        unitId: _selectedUnit!.id,
        investmentAmount: _investmentAmount!,
        downPayment: _downPayment,
        installmentsCount: _installmentsCount ?? 0,
      );

      _subscription = subscription;
      emit(SignatureRequiredState(subscription));
    } catch (e) {
      emit(JoinFlowError(e.toString()));
    }
  }



  Future<void> submitSignature({
    required String subscriptionId,
    required String signatureData,
  }) async {
    emit(JoinFlowLoading());
    try {
      // Submit signature logic
      await Future.delayed(const Duration(seconds: 1));
      emit(JoinFlowCompleted());
    } catch (e) {
      emit(JoinFlowError(e.toString()));
    }
  }

  Future<void> signContract(String signaturePath) async {
    if (_subscription == null) {
      emit(const JoinFlowError('لا يوجد اشتراك للتوقيع'));
      return;
    }

    emit(const PaymentProcessingState('جاري التوقيع...'));

    try {
      await _subscriptionService.signContract(
        subscriptionId: _subscription!.id,
        signaturePath: signaturePath,
      );

      // Reload subscription to get updated status
      final updatedSubscription = await _subscriptionService.getSubscriptionById(_subscription!.id);
      
      emit(JoinFlowCompleteState(updatedSubscription));
    } catch (e) {
      emit(JoinFlowError(e.toString()));
    }
  }

  void reset() {
    _projectId = null;
    _selectedUnit = null;
    _investmentAmount = null;
    _downPayment = null;
    _installmentsCount = null;
    _subscription = null;
    emit(JoinFlowInitial());
  }
}
