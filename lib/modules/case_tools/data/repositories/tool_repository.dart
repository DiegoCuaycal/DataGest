import 'package:herramienta_case/modules/case_tools/data/models/tool_model.dart';
import 'package:herramienta_case/modules/case_tools/domain/entities/tool_entity.dart';

/// Repositorio de herramientas CASE
class ToolRepository {
  // TODO: Implementar data source cuando el backend esté listo

  /// Obtiene todas las herramientas (mock)
  Future<List<ToolEntity>> getAllTools() async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    // Datos mock para pruebas
    final mockTools = [
      ToolModel(
        id: 1,
        nombre: 'Visual Paradigm',
        descripcion:
            'Herramienta CASE para modelado UML, diseño de bases de datos y más',
        categoria: 'Modelado',
        url: 'https://www.visual-paradigm.com/',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ToolModel(
        id: 2,
        nombre: 'Enterprise Architect',
        descripcion:
            'Plataforma completa para diseño, análisis y modelado de sistemas',
        categoria: 'Modelado',
        url: 'https://sparxsystems.com/',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 25)),
      ),
      ToolModel(
        id: 3,
        nombre: 'StarUML',
        descripcion:
            'Herramienta de modelado de software ágil y sofisticada',
        categoria: 'Modelado',
        url: 'https://staruml.io/',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 20)),
      ),
      ToolModel(
        id: 4,
        nombre: 'Rational Rose',
        descripcion: 'Suite de herramientas de modelado visual de IBM',
        categoria: 'Modelado',
        url: 'https://www.ibm.com/',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 15)),
      ),
      ToolModel(
        id: 5,
        nombre: 'MySQL Workbench',
        descripcion:
            'Herramienta visual para diseño, modelado y administración de BD',
        categoria: 'Base de Datos',
        url: 'https://www.mysql.com/products/workbench/',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 10)),
      ),
      ToolModel(
        id: 6,
        nombre: 'DBDesigner',
        descripcion: 'Herramienta de diseño de bases de datos visuales',
        categoria: 'Base de Datos',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    return mockTools.map((model) => model.toEntity()).toList();
  }

  /// Obtiene una herramienta por ID (mock)
  Future<ToolEntity?> getToolById(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final tools = await getAllTools();
    try {
      return tools.firstWhere((tool) => tool.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca herramientas por nombre (mock)
  Future<List<ToolEntity>> searchTools(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final tools = await getAllTools();
    final lowerQuery = query.toLowerCase();

    return tools
        .where((tool) =>
            tool.nombre.toLowerCase().contains(lowerQuery) ||
            tool.descripcion.toLowerCase().contains(lowerQuery) ||
            tool.categoria.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Filtra herramientas por categoría (mock)
  Future<List<ToolEntity>> getToolsByCategory(String categoria) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final tools = await getAllTools();
    return tools
        .where((tool) =>
            tool.categoria.toLowerCase() == categoria.toLowerCase())
        .toList();
  }
}
