import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const MyApp());
}

class Gasto {
  final String nombre;
  final double monto;

  Gasto({required this.nombre, required this.monto});
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

  void _agregarGasto(Gasto gasto) async {
    setState(() {
      _gastos.add(gasto);
    });
     // Guarda el gasto en SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  List<String> gastosGuardados = prefs.getStringList('gastos') ?? [];
  gastosGuardados.add('${gasto.nombre},${gasto.monto}');
  await prefs.setStringList('gastos', gastosGuardados);
  }

 Future<void> _cargarGastos() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> gastosGuardados = prefs.getStringList('gastos') ?? [];

  setState(() {
    // Filtramos y validamos los datos antes de agregarlos
    _gastos = gastosGuardados.map((g) {
      final partes = g.split(',');
      // Verifica si hay exactamente dos elementos (nombre y monto)
      if (partes.length != 2) return null; // Si el formato es incorrecto, retorna null
      final nombre = partes[0];
      final monto = double.tryParse(partes[1]) ?? 0; // Parseamos el monto a double
      return Gasto(nombre: nombre, monto: monto); // Creamos el objeto Gasto
    }).whereType<Gasto>().toList(); // Filtramos los elementos null
  });
}
  Future<Gasto?> _mostrarDialogoAgregarGasto(BuildContext context) {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController montoController = TextEditingController();

    return showDialog<Gasto>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Gasto'),
          content: Column(
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
            ],
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
                  Navigator.of(context).pop(Gasto(nombre: nombre, monto: monto));
                }
              },
            ),
          ],
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
      ),
      body: ListView.builder(
        itemCount: _gastos.length,
        itemBuilder: (context, index) {
          final gasto = _gastos[index];
          return ListTile(
            title: Text(gasto.nombre),
            subtitle: Text('\$${gasto.monto.toStringAsFixed(2)}'),
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
