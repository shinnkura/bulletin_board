import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter掲示板アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BulletinBoard(),
    );
  }
}

class BulletinBoard extends StatefulWidget {
  const BulletinBoard({super.key});

  @override
  _BulletinBoardState createState() => _BulletinBoardState();
}

class _BulletinBoardState extends State<BulletinBoard> {
  String _title = '';
  String _content = '';

  void _updateBoard(String title, String content) async {
    final collection = FirebaseFirestore.instance.collection('board');
    await collection.doc('post').set({
      'title': title,
      'content': content,
    });
    setState(() {
      _title = title;
      _content = content;
    });
  }

  @override
  void initState() {
    super.initState();
    final doc = FirebaseFirestore.instance.collection('board').doc('post');
    doc.get().then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _title = snapshot.data()!['title'];
          _content = snapshot.data()!['content'];
        });
      }
    });
  }

  void _showEditDialog() {
    final TextEditingController titleController =
        TextEditingController(text: _title);
    final TextEditingController contentController =
        TextEditingController(text: _content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '本文'),
                  maxLines: null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () {
                _updateBoard(titleController.text, contentController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コルクボード掲示板'),
        backgroundColor: Colors.brown,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0), // コンテナ全体のパディングを追加
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/corkboard_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(8.0), // コンテンツのマージンを追加
            decoration: BoxDecoration(
              color: Colors.yellow[100]?.withOpacity(0.9), // 背景色の透明度を調整
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.brown),
                ),
                const SizedBox(height: 10.0),
                Text(
                  _content,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _showEditDialog,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
