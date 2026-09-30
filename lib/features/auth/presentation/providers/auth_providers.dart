import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gea_app/core/network/network_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(dio, storage);
});

class AuthState {
  final bool isLoading;
  final bool isGuest;
  final AuthUser? user;
  final String? errorMessage;

  AuthState({this.isLoading = false, this.isGuest = false, this.user, this.errorMessage});

  AuthState copyWith({bool? isLoading, bool? isGuest, AuthUser? user, String? errorMessage}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isGuest: isGuest ?? this.isGuest,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  void continueAsGuest() {
    state = state.copyWith(isGuest: true, user: null, errorMessage: null);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _repository.login(email, password);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> loginWithMicrosoft() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _repository.loginWithMicrosoft();
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
