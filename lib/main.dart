import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import './firebase_options.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const MultiAuth(),
  );
}

class MultiAuth extends StatelessWidget {
  const MultiAuth({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Auth',
      home: MultiAuthPage(),
    );
  }
}

class MultiAuthPage extends StatefulWidget {
  const MultiAuthPage({Key? key}) : super(key: key);

  @override
  _MultiAuthPageState createState() => _MultiAuthPageState();
}

class _MultiAuthPageState extends State<MultiAuthPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final StreamSubscription _firebaseStreamEvents;
  String _loginMessage = '';

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _firebaseStreamEvents =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      print(user);
      if (user != null) {
        user.sendEmailVerification();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firebaseStreamEvents.cancel();
    super.dispose();
  }

  void _goToHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
            EdgeInsets.all(16.0), // Espaciado de 16 píxeles en todos los lados
        child: Column(
          children: [
            TextField(
              controller: _emailController,
            ),
            SizedBox(
                height:
                    16.0), // Espacio vertical de 16 píxeles entre los campos de texto
            TextField(
              controller: _passwordController,
            ),
            SizedBox(
                height:
                    16.0), // Espacio vertical de 16 píxeles entre el segundo campo de texto y el botón
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                  setState(() {
                    _loginMessage = 'Inicio de Sesión Exitoso';
                  });
                  _goToHomePage();
                } on FirebaseAuthException catch (e) {
                  if (e.message!.contains('auth/user-not-found') ||
                      e.message!.contains('auth/wrong-password')) {
                    setState(() {
                      _loginMessage =
                          'Credenciales de inicio de sesión incorrectas';
                    });
                  } else {
                    setState(() {
                      _loginMessage = 'Error >>>> ${e.message}';
                    });
                  }
                } catch (e) {
                  setState(() {
                    _loginMessage = 'Print >>> ${e}';
                  });
                }
              },
              child: const Text("Submit"),
            ),
            SizedBox(height: 16.0),
            Text(
              _loginMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> items = List.generate(20, (index) => 'Item ${index + 1}');
  bool isLoading = false;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // El usuario ha alcanzado el final del ListView, cargar más elementos
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      // Obtén la referencia a la colección en Firebase Firestore
      final collectionReference =
          FirebaseFirestore.instance.collection('items');

      // Realiza una consulta paginada para obtener los siguientes elementos
      collectionReference
          .orderBy('campo_orden', descending: false)
          .startAfter([items.last])
          .limit(10)
          .get()
          .then((querySnapshot) {
            // Mapea los documentos de la consulta a objetos o datos relevantes para tu aplicación
            List<String> newItems = querySnapshot.docs
                .map((doc) => doc.data()['item'] as String)
                .toList();

            setState(() {
              items.addAll(newItems);
              isLoading = false;
            });
          })
          .catchError((error) {
            print('Error al cargar más elementos: $error');
            setState(() {
              isLoading = false;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index < items.length) {
            // Mostrar elementos existentes
            return ListTile(
              title: Text(items[index]),
            );
          } else {
            // Mostrar un indicador de carga al final del ListView
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
