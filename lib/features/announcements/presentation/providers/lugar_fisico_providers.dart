import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gea_app/core/network/network_providers.dart';
import '../../domain/repositories/lugar_fisico_repository.dart';
import '../../data/repositories/lugar_fisico_repository_impl.dart';
import '../../data/models/lugar_fisico_model.dart';

final lugarFisicoRepositoryProvider = Provider<LugarFisicoRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return LugarFisicoRepositoryImpl(dio);
});

final lugaresFisicosProvider = FutureProvider<List<LugarFisicoModel>>((ref) async {
  final repository = ref.watch(lugarFisicoRepositoryProvider);
  final result = await repository.getLugaresFisicos();
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (lugares) => lugares,
  );
});
