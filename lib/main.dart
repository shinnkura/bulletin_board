import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart'; // 日付をフォーマットするために追加

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
        primarySwatch: Colors.orange, // テーマカラーをオレンジに設定
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
  String _lastEdited = '';

  void _updateBoard(String title, String content) async {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(now);

    final collection = FirebaseFirestore.instance.collection('board');
    await collection.doc('post').set({
      'title': title,
      'content': content,
      'lastEdited': formattedDate,
    });
    setState(() {
      _title = title;
      _content = content;
      _lastEdited = formattedDate;
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
          _lastEdited = snapshot.data()!['lastEdited'] ?? '';
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
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '本文'),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 3,
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
        backgroundColor: Colors.orange[800], // アプリバーの色を濃いオレンジに設定
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.orange[50], // コンテナの背景色を薄いオレンジに設定
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.5), // 影の色をオレンジに設定
                      blurRadius: 8,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.orange[800]), // タイトルのスタイルを変更
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      _content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          '最終編集: $_lastEdited',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        TextButton(
                          onPressed: _showEditDialog,
                          child: Text(
                            '編集',
                            style: TextStyle(color: Colors.orange[800]),
                          ), // ボタンのスタイルを変更
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
