import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gemini_test/chat_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

const apiKey = 'AIzaSyCzmRc1hyvS8165YFh2sSWW6wNsSkoPxHw';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
      ),
      home: const GeminiChat(),
    );
  }
}

class GeminiChat extends StatefulWidget {
  const GeminiChat({super.key});

  @override
  State<GeminiChat> createState() => _GeminiChatState();
}

class _GeminiChatState extends State<GeminiChat> {
  late GenerativeModel model;
  late ChatSession _chat;
  final TextEditingController _controller = TextEditingController();
  List<ChatModel> messages = [];

  String? mineType;
  Uint8List? image;

  @override
  void initState() {
    model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _chat = model.startChat();
    super.initState();
  }

  Future<void> _sendMessage() async {
    try {
      final content = Content.multi(
        [
          TextPart(_controller.text),
          if (image != null) DataPart(mineType!, image!),
        ],
      );
      final response = await _chat.sendMessage(content);
      messages.add(ChatModel(
        name: 'Gemini',
        message: response.text ?? 'loading...',
        time: DateTime.now().toString(),
      ));
    } catch (e) {
      // Log the error or show a message to the user
      print('Failed to send message: $e');
      messages.remove(messages.last);
      messages.add(ChatModel(
        name: 'Error',
        message: 'Failed to send message. Please try again.',
        time: DateTime.now().toString(),
      ));
    }
    messages.removeWhere((message) => message is LoadingMessage);
    setState(() {});
  }

  void createModel() {
    messages.add(ChatModel(
      name: 'User',
      message: _controller.text,
      time: DateTime.now().toString(),
      isUser: true,
      image: image,
      mineType: mineType,
    ));
    _sendMessage();
    image = null;
    mineType = null;
    messages.add(LoadingMessage());
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Gemini Chat'),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterFloat,
        floatingActionButton: _inputField(context),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _ChatItemWidget(message: message);
            },
          ),
        ));
  }

  Container _inputField(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null)
              Stack(
                fit: StackFit.loose,
                alignment: Alignment.topRight,
                children: [
                  Image.memory(
                    image!,
                    width: 100,
                    height: 100,
                  ),
                  Container(
                    color: Colors.white.withOpacity(0.5),
                    height: 100,
                    width: 100,
                  ),
                  Positioned(
                    right: 10,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        image = null;
                        mineType = null;
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onEditingComplete: () {
                      if (_controller.text.isNotEmpty) {
                        createModel();
                      }
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  onPressed: _controller.text.isEmpty
                      ? null
                      : () async {
                          createModel();
                        },
                  icon: const Icon(
                    Icons.send,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
                IconButton(
                  onPressed: action,
                  icon: const Icon(
                    Icons.attach_file,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void action() {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (_) => Material(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    height: 6,
                    width: MediaQuery.sizeOf(context).width * .3,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'Choose Image Platform',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: 40,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Library'),
                  onPressed: () {
                    ImagePicker()
                        .pickImage(source: ImageSource.gallery)
                        .then((value) async {
                      if (value != null) {
                        mineType = value.mimeType ??
                            'image/${value.name.split('.').last.toLowerCase()}';
                        image = await value.readAsBytes();
                        setState(() {});
                      }
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Camera'),
                  onPressed: () {
                    ImagePicker()
                        .pickImage(source: ImageSource.camera)
                        .then((value) async {
                      if (value != null) {
                        mineType = value.mimeType ??
                            'image/${value.name.split('.').last.toLowerCase()}';
                        image = await value.readAsBytes();
                        setState(() {});
                      }
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatItemWidget extends StatelessWidget {
  const _ChatItemWidget({
    super.key,
    required this.message,
  });

  final ChatModel message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: 8.0,
          left: message.isUser ? 50.0 : 8.0,
          right: message.isUser ? 8.0 : 50.0),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: const Radius.circular(10),
              bottomLeft:
                  message.isUser ? const Radius.circular(10) : Radius.zero,
              bottomRight:
                  message.isUser ? Radius.zero : const Radius.circular(10),
            ),
            color: message.isUser
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
          child: message is LoadingMessage
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: LoadingAnimationWidget.waveDots(
                    color: Colors.white,
                    size: 24,
                  ),
                )
              : Column(
                  children: [
                    if (message.image != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.memory(message.image!,
                            width: 100, height: 100),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        message.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
