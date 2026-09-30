import 'package:fpdart/fpdart.dart';
import 'package:gea_app/core/error/failures.dart';
import '../../data/models/lugar_fisico_model.dart';

abstract class LugarFisicoRepository {
  Future<Either<Failure, List<LugarFisicoModel>>> getLugaresFisicos();
}
