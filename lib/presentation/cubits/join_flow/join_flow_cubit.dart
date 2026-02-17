import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/services/subscription_service.dart';
import 'package:mmm/data/services/wallet_service.dart';
import 'package:mmm/data/repositories/project_repository.dart';

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

  String? get projectId => _projectId;
  UnitModel? get selectedUnit => _selectedUnit;

  List<UnitModel> _availableUnits = []; // Store available units
  double? _investmentAmount;
  double? _downPayment;
  int? _installmentsCount;
  SubscriptionModel? _subscription;

  final ProjectRepository _projectRepository;

  JoinFlowCubit({
    SubscriptionService? subscriptionService,
    WalletService? walletService,
    ProjectRepository? projectRepository,
  })  : _subscriptionService = subscriptionService ?? SubscriptionService(),
        _walletService = walletService ?? WalletService(),
        _projectRepository = projectRepository ?? ProjectRepository(),
        super(JoinFlowInitial());

  void loadAvailableUnits(String projectId) async {
    _projectId = projectId;
    emit(JoinFlowLoading());
    try {
      final units = await _projectRepository.getProjectUnits(projectId: projectId, status: 'available');
      _availableUnits = units; // Cache locally
      emit(UnitSelectionState(availableUnits: units));
    } catch (e) {
      emit(JoinFlowError(e.toString()));
    }
  }

  void startFlow(String projectId, List<UnitModel> availableUnits) {
    _projectId = projectId;
    _availableUnits = availableUnits;
    emit(UnitSelectionState(availableUnits: availableUnits));
  }

  void selectUnit(UnitModel unit) {
    _selectedUnit = unit;
    emit(UnitSelectionState(availableUnits: _availableUnits, selectedUnit: unit));
  }

  void initBooking(String projectId, UnitModel unit) {
    _projectId = projectId;
    _selectedUnit = unit;
    // We might not have all available units here, but that's fine for booking flow
    emit(UnitSelectionState(availableUnits: const [], selectedUnit: unit));
  }

  Future<void> acceptContract(String projectId, String unitId, {bool isFullPayment = false}) async {
    emit(JoinFlowLoading());
    try {
      _investmentAmount = _selectedUnit?.price ?? 0.0;
      
      if (isFullPayment) {
        // Full Payment: 100% now, 0 installments
        _downPayment = _investmentAmount;
        _installmentsCount = 0;
      } else {
        // Partial Payment: Split into 4 payments
        // 1st payment serves as down payment
        _downPayment = (_investmentAmount ?? 0.0) / 4; 
        _installmentsCount = 3; // Remaining 3 installments
      }

      final subscriptionId = 'sub_${DateTime.now().millisecondsSinceEpoch}';
      final amount = _downPayment ?? 0.0; // Amount to pay now
      
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

    if (_investmentAmount == null || _investmentAmount! <= 0) {
      _investmentAmount = _selectedUnit?.price;
    }

    if (_investmentAmount == null) {
       emit(const JoinFlowError('خطأ: لم يتم تحديد مبلغ الاستثمار'));
       return;
    }

    emit(const PaymentProcessingState('جاري معالجة الدفع...'));
    try {
      // Skip wallet check if not paying by wallet
      final skipWalletCheck = paymentMethod != 'wallet';

      // Create subscription through service (validates wallet + unit)
      final subscription = await _subscriptionService.createSubscription(
        userId: userId,
        projectId: _projectId!,
        unitId: _selectedUnit!.id,
        investmentAmount: _investmentAmount!,
        downPayment: _downPayment,
        installmentsCount: _installmentsCount ?? 0,
        skipWalletCheck: skipWalletCheck,
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
     // Deprecated or can be used for string path
    await signContract(signatureData);
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

  Future<void> signContractBytes(List<int> signatureBytes) async {
    if (_subscription == null) {
      emit(const JoinFlowError('لا يوجد اشتراك للتوقيع'));
      return;
    }

    emit(const PaymentProcessingState('جاري التوقيع...'));

    try {
      await _subscriptionService.signContractWithBytes(
        subscriptionId: _subscription!.id,
        signatureBytes: signatureBytes,
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
