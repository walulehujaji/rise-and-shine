import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RISE AND SHINE',
      theme: ThemeData.dark(),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return HomeScreen();
        return LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  String error = "";

  Future submit() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("RISE AND SHINE")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Bet Smart. Win Better."),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: submit,
              child: Text(isLogin ? "Login" : "Register"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Create account" : "Login"),
            ),
            if (error.isNotEmpty)
              Text(error, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final tipsRef = FirebaseFirestore.instance.collection('tips');
  final user = FirebaseAuth.instance.currentUser;

  Future<bool> checkIfPaid() async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (!doc.exists) return false;
    return doc['paid'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Tips"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: FutureBuilder<bool>(
        future: checkIfPaid(),
        builder: (context, paidSnapshot) {
          if (!paidSnapshot.hasData)
            return Center(child: CircularProgressIndicator());
          bool isPaid = paidSnapshot.data!;
          return StreamBuilder(
            stream: tipsRef.snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              var tips = snapshot.data.docs;
              return ListView.builder(
                itemCount: tips.length,
                itemBuilder: (context, index) {
                  var tip = tips[index];
                  bool isPremium = tip['premium'];
                  if (isPremium && !isPaid) {
                    return Card(
                      child: ListTile(
                        title: Text("Premium Tip 🔒"),
                        subtitle: Text("Pay to unlock"),
                      ),
                    );
                  }
                  return Card(
                    child: ListTile(
                      title: Text(tip['match']),
                      subtitle: Text("Odds: ${tip['odds']} | ${tip['result']}"),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.payment),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Payment"),
              content: Text("Send via Mobile Money then contact admin."),
            ),
          );
        },
      ),
    );
  }
}
