import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const MyApp());
}
class Gasto {
  final String nombre;
  final double monto;
  final String categoria;
  final DateTime fecha;

  Gasto({
    required this.nombre,
    required this.monto,
    required this.categoria,
    required this.fecha,
  });

  // Para guardar como texto
  String toStorageString() {
    return '$nombre|$monto|$categoria|${fecha.toIso8601String()}';
  }

  // Para reconstruir desde texto
  static Gasto? fromStorageString(String data) {
    final partes = data.split('|');
    if (partes.length != 4) return null;
    final nombre = partes[0];
    final monto = double.tryParse(partes[1]) ?? 0;
    final categoria = partes[2];
    final fecha = DateTime.tryParse(partes[3]) ?? DateTime.now();
    return Gasto(
      nombre: nombre,
      monto: monto,
      categoria: categoria,
      fecha: fecha,
    );
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Gastos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Gastos Personales'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();

  
}


class _MyHomePageState extends State<MyHomePage> {
  List<Gasto> _gastos = [];
  List<String> _categorias = ['Comida', 'Transporte', 'Salud', 'Educación', 'Otros'];

   Future<void> _guardarCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categorias', _categorias);
  }

    Future<void> _cargarCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    final cargadas = prefs.getStringList('categorias');
    if (cargadas != null) {
      setState(() {
        _categorias = cargadas;
      });
    }
  }
 
void _agregarGasto(Gasto gasto) async {
  setState(() {
    _gastos.add(gasto);
  });
 
  final prefs = await SharedPreferences.getInstance();
  List<String> gastosGuardados = prefs.getStringList('gastos') ?? [];

  // Utilizamos el nuevo método toStorageString
  gastosGuardados.add(gasto.toStorageString());

  await prefs.setStringList('gastos', gastosGuardados);
}

 void _eliminarGasto(Gasto gasto) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> gastosGuardados = prefs.getStringList('gastos') ?? [];

  gastosGuardados.remove(gasto.toStorageString());

  await prefs.setStringList('gastos', gastosGuardados);
}

 Future<void> _cargarGastos() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> gastosGuardados = prefs.getStringList('gastos') ?? [];

  setState(() {
    _gastos = gastosGuardados
        .map((g) => Gasto.fromStorageString(g))
        .whereType<Gasto>()
        .toList();
  });
}
void _mostrarResumenDeGastos() {
  double total = _gastos.fold(0, (suma, gasto) => suma + gasto.monto);

  Map<String, double> totalesPorCategoria = {};
  for (var gasto in _gastos) {
    totalesPorCategoria[gasto.categoria] =
        (totalesPorCategoria[gasto.categoria] ?? 0) + gasto.monto;
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Resumen de Gastos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total gastado: \$${total.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            const Text('Por categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...totalesPorCategoria.entries.map((e) => Text('${e.key}: \$${e.value.toStringAsFixed(2)}')),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}

Future<String?> _mostrarDialogoAgregarCategoria() {
  TextEditingController nuevaCategoriaController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Agregar nueva categoría'),
        content: TextField(
          controller: nuevaCategoriaController,
          decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Agregar'),
            onPressed: () {
              final nueva = nuevaCategoriaController.text.trim();
              if (nueva.isNotEmpty && !_categorias.contains(nueva)) {
                Navigator.of(context).pop(nueva);
              } else {
                Navigator.of(context).pop(null);
              }
            },
          ),
        ],
      );
    },
  );
}


Future<void> _editarGasto(Gasto gastoOriginal, int index) async {
  final TextEditingController nombreController = TextEditingController(text: gastoOriginal.nombre);
  final TextEditingController montoController = TextEditingController(text: gastoOriginal.monto.toString());
  String categoriaSeleccionada = gastoOriginal.categoria;
  DateTime fechaSeleccionada = gastoOriginal.fecha;

  final gastoEditado = await showDialog<Gasto>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Gasto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre del gasto'),
                  ),
                  TextField(
                    controller: montoController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                 DropdownButtonFormField<String>(
                   value: categoriaSeleccionada,
                   decoration: const InputDecoration(labelText: 'Categoría'),
                   items: [
              ..._categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                 const DropdownMenuItem(
                 value: 'nueva_categoria',
                child: Text('➕ Agregar nueva categoría'),
                 ),
                 ],
               onChanged: (value) async {
                if (value == 'nueva_categoria') {
                  final nueva = await _mostrarDialogoAgregarCategoria();
               if (nueva != null && !_categorias.contains(nueva)) {
  setState(() {
    _categorias.add(nueva);
    categoriaSeleccionada = nueva;

    
  });
  await _guardarCategorias();
}
    } else if (value != null) {
      setState(() => categoriaSeleccionada = value);
    }
  },
),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fecha: ${fechaSeleccionada.toLocal().toString().split(' ')[0]}'),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && picked != fechaSeleccionada) {
                            setState(() => fechaSeleccionada = picked);
                          }
                        },
                        child: const Text('Seleccionar Fecha'),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () {
                  final nombre = nombreController.text;
                  final monto = double.tryParse(montoController.text) ?? 0;
                  if (nombre.isNotEmpty && monto > 0) {
                    Navigator.of(context).pop(Gasto(
                      nombre: nombre,
                      monto: monto,
                      categoria: categoriaSeleccionada,
                      fecha: fechaSeleccionada,
                    ));
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );

  if (gastoEditado != null) {
    setState(() {
      _gastos[index] = gastoEditado;
    });

    final prefs = await SharedPreferences.getInstance();
    List<String> gastosGuardados = _gastos.map((g) => g.toStorageString()).toList();
    await prefs.setStringList('gastos', gastosGuardados);
  }
}

  Future<Gasto?> _mostrarDialogoAgregarGasto(BuildContext context) {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController montoController = TextEditingController();
  String categoriaSeleccionada = 'Otros';
  DateTime fechaSeleccionada = DateTime.now();

  return showDialog<Gasto>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Agregar Gasto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre del gasto'),
                  ),
                  TextField(
                    controller: montoController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                  DropdownButtonFormField<String>(
  value: categoriaSeleccionada,
  decoration: const InputDecoration(labelText: 'Categoría'),
  items: [
    ..._categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
    const DropdownMenuItem(
      value: 'nueva_categoria',
      child: Text('➕ Agregar nueva categoría'),
    ),
  ],
  onChanged: (value) async {
    if (value == 'nueva_categoria') {
      final nueva = await _mostrarDialogoAgregarCategoria();
      if (nueva != null && !_categorias.contains(nueva)) {
  setState(() {
    _categorias.add(nueva);
    categoriaSeleccionada = nueva;
  });
  await _guardarCategorias();
}
    } else if (value != null) {
      setState(() => categoriaSeleccionada = value);
    }
  },
),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fecha: ${fechaSeleccionada.toLocal().toString().split(' ')[0]}'),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && picked != fechaSeleccionada) {
                            setState(() => fechaSeleccionada = picked);
                          }
                        },
                        child: const Text('Seleccionar Fecha'),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Agregar'),
                onPressed: () {
                  final nombre = nombreController.text;
                  final monto = double.tryParse(montoController.text) ?? 0;
                  if (nombre.isNotEmpty && monto > 0) {
                    Navigator.of(context).pop(Gasto(
                      nombre: nombre,
                      monto: monto,
                      categoria: categoriaSeleccionada,
                      fecha: fechaSeleccionada,
                    ));
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}


 
 @override
void initState() {
  super.initState();
  _cargarGastos();
}

@override
Widget build(BuildContext context) {
  return Scaffold(
   appBar: AppBar(
  title: Text(widget.title),
  actions: [
    IconButton(
      icon: const Icon(Icons.bar_chart),
      onPressed: _mostrarResumenDeGastos,
    ),
  ],
),
    body: ListView.builder(
      itemCount: _gastos.length,
      itemBuilder: (context, index) {
        final gasto = _gastos[index];
     return Dismissible(
  key: Key(gasto.toStorageString()),
  direction: DismissDirection.endToStart,
  onDismissed: (direction) {
    final gastoEliminado = _gastos[index];

    setState(() {
      _gastos.removeAt(index);
    });

    _eliminarGasto(gastoEliminado);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gasto eliminado')),
    );
  },
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    child: const Icon(Icons.delete, color: Colors.white),
  ),
  child: ListTile(
    title: Text(gasto.nombre),
    subtitle: Text(
      'Monto: \$${gasto.monto.toStringAsFixed(2)}\n'
      'Categoría: ${gasto.categoria} - Fecha: ${gasto.fecha.toLocal().toString().split(' ')[0]}',
    ),
    isThreeLine: true,
  ),
);
      },
    ),
  floatingActionButton: FloatingActionButton(
      onPressed: () async {
        final gasto = await _mostrarDialogoAgregarGasto(context);
        if (gasto != null) {
          _agregarGasto(gasto);
        }
      },
      child: const Icon(Icons.add),
    ),
  );
  
}
}




