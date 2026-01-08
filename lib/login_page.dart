import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  bool loading = false;

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await FirebaseFirestore.instance
        .collection('scores')
        .doc(username)
        .get();

    return !doc.exists;
  }

  void login() async {
    final username = _nameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("İsim boş olamaz")));

      return;
    }

    setState(() => loading = true);

    final doc = await FirebaseFirestore.instance
        .collection('scores')
        .doc(username)
        .get();


    if (!doc.exists) {

      await FirebaseFirestore.instance
          .collection('scores')
          .doc(username)
          .set({
        'name': username,
        'score': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }


    await saveUsername(username);

    setState(() => loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(username: username),
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    loadSavedUsername();
  }



  Future<void> loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');

    if (savedUsername != null) {
      _nameController.text = savedUsername;
    }
  }
  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Snake Game")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              maxLength: 12,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: "Kullanıcı Adı",
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            SizedBox(height: 12),
            loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: login,
              child: Text("Oyuna Gir"),
            ),
            SizedBox(height: 20),
            Text("🏆 TOP 10", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Expanded(child: Top10List()),
          ],
        ),
      ),
    );
  }
}

class Top10List extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('scores')
          .orderBy('score', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text("Henüz skor yok"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index];
            return ListTile(
              leading: Text("#${index + 1}"),
              title: Text(data['name']),
              trailing: Text(data['score'].toString()),
            );
          },
        );
      },
    );
  }
}
