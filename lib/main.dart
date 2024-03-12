import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';

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
    return const MaterialApp(
      title: '掲示板アプリ',
      home: BulletinBoard(),
    );
  }
}

class BulletinBoard extends StatefulWidget {
  const BulletinBoard({super.key});

  @override
  _BulletinBoardState createState() => _BulletinBoardState();
}

class _BulletinBoardState extends State<BulletinBoard> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掲示板アプリ'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFormDialog,
        tooltip: '投稿',
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.grey[400],
    );
  }

  Widget _buildBody() {
    return Center(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('エラーが発生しました: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }

          if (!snapshot.hasData) {
            return const Text('データがありません');
          }

          return _buildList(snapshot.data!.docs);
        },
      ),
    );
  }

  Widget _buildList(List<DocumentSnapshot> docs) {
    return ListView(
      children: docs.map(_buildListItem).toList(),
    );
  }

  Widget _buildListItem(DocumentSnapshot doc) {
    // timestamp が null でないか確認し、null の場合は現在時刻を使用
    DateTime timestamp =
        (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    String formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(timestamp);

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        title: Text(
          doc['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc['content']),
            const SizedBox(height: 10),
            Text(
              formattedDate,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormDialog() {
    // テキストフィールドの内容をクリア
    titleController.clear();
    contentController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しい投稿'),
          content: _buildDialogForm(),
          actions: <Widget>[
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('キャンセル'),
            ),
            TextButton(
              child: const Text('追加'),
              onPressed: () {
                _addPostToFirestore();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'タイトル'),
        ),
        TextField(
          controller: contentController,
          decoration: const InputDecoration(labelText: '内容'),
        ),
      ],
    );
  }

  void _addPostToFirestore() async {
    await FirebaseFirestore.instance.collection('posts').add({
      'title': titleController.text,
      'content': contentController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // データが追加された後にUIを更新するために状態を設定
    setState(() {});
  }
}
