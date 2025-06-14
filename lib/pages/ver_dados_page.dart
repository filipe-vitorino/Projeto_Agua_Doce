import 'package:flutter/material.dart';

class VerDadosPage extends StatelessWidget {
  const VerDadosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Lista de Itens', home: ItemListPage());
  }
}

class Item {
  final String id;
  final bool enviado;
  final Map<String, bool> atributos;

  Item({required this.id, required this.enviado, required this.atributos});
}

class ItemListPage extends StatefulWidget {
  @override
  _ItemListPageState createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<Item> itens = [
    Item(
      id: 'Item 1',
      enviado: true,
      atributos: {
        'Pressão': true,
        'Vazão': true,
        'Temperatura': false,
        'Condutividade': true,
      },
    ),
    Item(
      id: 'Item 2',
      enviado: false,
      atributos: {
        'Pressão': false,
        'Vazão': true,
        'Temperatura': true,
        'Condutividade': false,
      },
    ),
  ];

  Set<String> itensExpandidos = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Itens')),
      body: ListView.builder(
        itemCount: itens.length,
        itemBuilder: (context, index) {
          final item = itens[index];
          final estaExpandido = itensExpandidos.contains(item.id);

          return Card(
            child: InkWell(
              onTap: () {
                setState(() {
                  if (estaExpandido) {
                    itensExpandidos.remove(item.id);
                  } else {
                    itensExpandidos.add(item.id);
                  }
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color:
                        item.enviado ? Colors.green[100] : Colors.orange[100],
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          item.enviado ? Icons.check_circle : Icons.cloud_off,
                          color: item.enviado ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${item.id} - ${item.enviado ? "Enviado" : "Não enviado"}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children:
                          item.atributos.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bubble_chart,
                                    color: Colors.blueGrey,
                                  ),
                                  SizedBox(width: 8),
                                  Text(entry.key),
                                  Spacer(),
                                  Icon(
                                    entry.value ? Icons.check : Icons.close,
                                    color:
                                        entry.value ? Colors.green : Colors.red,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  if (estaExpandido) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => print('Editar ${item.id}'),
                            child: Text('Editar'),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => print('Excluir ${item.id}'),
                            child: Text('Excluir'),
                            style: ElevatedButton.styleFrom(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
