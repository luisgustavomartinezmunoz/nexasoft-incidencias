class Incidencia {
  static const prioridadesPermitidas = ['Baja', 'Media', 'Alta'];

  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String _prioridad;
  String get prioridad => _prioridad;
  set prioridad(String valor) {
    if (!prioridadesPermitidas.contains(valor)) {
      throw ArgumentError.value(valor, 'prioridad', 'Prioridad no permitida');
    }
    _prioridad = valor;
  }

  String fecha;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    required this.fecha,
    String prioridad = 'Media',
  }) : _prioridad = _validarPrioridad(prioridad);

  static String _validarPrioridad(String valor) {
    if (!prioridadesPermitidas.contains(valor)) {
      throw ArgumentError.value(valor, 'prioridad', 'Prioridad no permitida');
    }
    return valor;
  }

  factory Incidencia.desdeJson(Map<String, dynamic> m) {
    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      fecha: m['fecha']?.toString() ?? '',
      prioridad: prioridadesPermitidas.contains(m['prioridad'])
          ? m['prioridad'] as String
          : 'Media',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'prioridad': prioridad,
      'fecha': fecha,
    };
  }
}
