class LugarFisicoModel {
  final int id;
  final String nombre;
  final String descripcion;
  final int? capacidad;
  final bool activo;

  LugarFisicoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.capacidad,
    required this.activo,
  });

  factory LugarFisicoModel.fromJson(Map<String, dynamic> json) {
    return LugarFisicoModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      capacidad: json['capacidad'] as int?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
