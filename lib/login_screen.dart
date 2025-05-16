import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:encrypt/encrypt.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  final supabase = Supabase.instance.client;
  String? _token;

  
  final _key = Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final _iv = IV.fromLength(16);

  final encrypter = Encrypter(AES(Key.fromUtf8('my32lengthsupersecretnooneknows1')));

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await storage.read(key: 'token');
    if (token != null) {
      setState(() {
        _token = token;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SecretNotesScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response.session != null) {
          await storage.write(key: 'token', value: response.session!.accessToken);
          setState(() {
            _token = response.session!.accessToken;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SecretNotesScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login falhou. Verifique suas credenciais.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await storage.delete(key: 'token');
    await supabase.auth.signOut();
    setState(() {
      _token = null;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Login com Supabase', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Entrar'),
                ),
                if (_token != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Sair'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecretNotesScreen extends StatefulWidget {
  const SecretNotesScreen({super.key});

  @override
  State<SecretNotesScreen> createState() => _SecretNotesScreenState();
}

class _SecretNotesScreenState extends State<SecretNotesScreen> {
  final storage = const FlutterSecureStorage();
  final _noteController = TextEditingController();
  List<String> _notes = [];
  final encrypter = Encrypter(AES(Key.fromUtf8('my32lengthsupersecretnooneknows1')));
  final _iv = IV.fromLength(16);

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final allValues = await storage.readAll();
    setState(() {
      _notes = allValues.values.map((e) => encrypter.decrypt64(e, iv: _iv)).toList();
    });
  }

  Future<void> _saveNote() async {
    if (_noteController.text.isNotEmpty) {
      final encrypted = encrypter.encrypt(_noteController.text, iv: _iv);
      await storage.write(key: DateTime.now().toString(), value: encrypted.base64);
      _noteController.clear();
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recados Secretos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Novo Recado',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _saveNote,
            child: const Text('Salvar Recado'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_notes[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
