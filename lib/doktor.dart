import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

import 'homePage.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Sanal Doktor",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Geri düğmesi
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const homePage()),
            );
          },
        ),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(
          onPressed: _sendMediaMessage,
          icon: const Icon(Icons.image),
        )
      ]),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      messageOptions: const MessageOptions(
        currentUserContainerColor: Color(0xFF0731c5),
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;

      // Gemini'den yanıt akışı başlatılıyor
      gemini.streamGenerateContent(question).listen((event) {
        String rawResponse = event.content?.parts
            ?.fold("", (previous, current) => "$previous ${current.text}") ??
            "";

        // Markdown'daki "**" sembollerini kaldır
        String response = rawResponse.replaceAll(RegExp(r'\*{2}'), '');

        setState(() {
          // Mevcut cevabı güncelle
          if (messages.isNotEmpty &&
              messages.first.user.id == geminiUser.id) {
            messages[0] = ChatMessage(
              user: geminiUser,
              createdAt: messages.first.createdAt,
              text: messages.first.text + response,
            );
          } else {
            // Yeni mesaj ekle
            messages.insert(
              0,
              ChatMessage(
                user: geminiUser,
                createdAt: DateTime.now(),
                text: response,
              ),
            );
          }
        });
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
    }
  }


  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Bu fotoğrafı açıklayınız.",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: file.name, // Dosya adını ekledik
            type: MediaType.image,
          )
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}
