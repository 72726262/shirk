// lib/presentation/cubits/location/location_state.dart
import 'package:equatable/equatable.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationSuccess extends LocationState {
  const LocationSuccess();
  
  @override
  List<Object?> get props => [];
}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}
