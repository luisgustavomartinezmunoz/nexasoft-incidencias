import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _clave = 'nexasoft_incidencias_v1';

List<Map<String, Object>> _datosIniciales() => [
      {
        'id': 'INC-1',
        'titulo': 'WiFi sin conexión',
        'descripcion': 'Falla de túnel de red',
        'cliente': 'Cliente Uno',
        'categoria': 'Redes',
        'estado': 'Pendiente',
        'prioridad': 'Alta',
        'fecha': '2026-10-01',
      },
      {
        'id': 'INC-2',
        'titulo': 'Error de acceso',
        'descripcion': 'No puede iniciar sesión',
        'cliente': 'Cliente Dos',
        'categoria': 'Software',
        'estado': 'En proceso',
        'prioridad': 'Baja',
        'fecha': '2026-10-02',
      },
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(
      {_clave: jsonEncode(_datosIniciales())},
    );
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test(
      'busca título y descripción sin distinguir mayúsculas y recorta espacios',
      () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();

    expect(gestor.buscar('  wifi ').map((x) => x.id), ['INC-1']);
    expect(gestor.buscar('WiFi').map((x) => x.id), ['INC-1']);
    expect(gestor.buscar('túnel').map((x) => x.id), ['INC-1']);
    expect(gestor.buscar('   ').length, 2);
  });

  test('cambios y nuevas incidencias persisten sin alterar las existentes',
      () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();
    await gestor.cambiarEstado('INC-1', 'Resuelta');
    await gestor.crear(
        'Nuevo caso', 'Descripción nueva', 'Cliente Tres', 'Software');

    final reiniciado = GestorIncidencias();
    await reiniciado.iniciar();

    expect(reiniciado.incidencias, hasLength(3));
    expect(reiniciado.porId('INC-1')!.estado, 'Resuelta');
    expect(reiniciado.porId('INC-2')!.estado, 'En proceso');
    expect(reiniciado.buscar('nuevo caso'), hasLength(1));
  });

  test('contadores reflejan estados tras cambios, creación y reinicio',
      () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();
    expect(gestor.contar('Pendiente'), 1);
    expect(gestor.contar('En proceso'), 1);
    expect(gestor.contar('Resuelta'), 0);

    await gestor.cambiarEstado('INC-1', 'En proceso');
    expect(gestor.contar('Pendiente'), 0);
    expect(gestor.contar('En proceso'), 2);
    await gestor.cambiarEstado('INC-1', 'Pendiente');
    expect(gestor.contar('Pendiente'), 1);
    await gestor.cambiarEstado('INC-1', 'Resuelta');
    expect(gestor.contar('Pendiente'), 0);
    expect(gestor.contar('Resuelta'), 1);
    await gestor.cambiarEstado('INC-1', 'Pendiente');
    expect(gestor.contar('Pendiente'), 1);
    expect(gestor.contar('Resuelta'), 0);
    await gestor.cambiarEstado('INC-2', 'Resuelta');
    await gestor.crear('Otro', 'Otro detalle', 'Cliente Cuatro', 'Redes');

    final reiniciado = GestorIncidencias();
    await reiniciado.iniciar();
    expect(reiniciado.contar('Pendiente'), 2);
    expect(reiniciado.contar('En proceso'), 0);
    expect(reiniciado.contar('Resuelta'), 1);
    expect(reiniciado.buscar('sin coincidencia'), isEmpty);
    expect(reiniciado.contar('Pendiente'), 2);
  });

  test('prioridad se persiste y los registros antiguos o inválidos usan Media',
      () async {
    final datos = _datosIniciales()
      ..[0].remove('prioridad')
      ..[1]['prioridad'] = 'Urgente';
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(
      {_clave: jsonEncode(datos)},
    );

    final gestor = GestorIncidencias();
    await gestor.iniciar();
    expect(gestor.porId('INC-1')!.prioridad, 'Media');
    expect(gestor.porId('INC-2')!.prioridad, 'Media');

    await gestor.cambiarPrioridad('INC-1', 'Alta');
    await gestor.crear('Urgente', 'Caso prioritario', 'Cliente Tres', 'Redes',
        prioridad: 'Alta');
    final reiniciado = GestorIncidencias();
    await reiniciado.iniciar();

    expect(reiniciado.porId('INC-1')!.prioridad, 'Alta');
    expect(reiniciado.incidencias.first.prioridad, 'Alta');
    expect(() => reiniciado.porId('INC-1')!.prioridad = 'Urgente',
        throwsArgumentError);
    expect(reiniciado.porId('INC-1')!.prioridad, 'Alta');
  });

  test('combina texto, estado y prioridad y permite quitar todos los filtros',
      () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();

    expect(
      gestor
          .filtrar(texto: ' wifi ', estado: 'Pendiente', prioridad: 'Alta')
          .map((x) => x.id),
      ['INC-1'],
    );
    expect(
      gestor.filtrar(texto: 'wifi', estado: 'En proceso', prioridad: 'Alta'),
      isEmpty,
    );

    final todos = gestor.filtrar();
    expect(todos, hasLength(2));
    expect(gestor.contar('Pendiente'), 1);
    expect(gestor.contar('En proceso'), 1);
  });
}
