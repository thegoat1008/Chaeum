import 'package:flutter/material.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'goal_input_screen.dart';

class NameScreen extends StatefulWidget {
  final String? initialName;
  const NameScreen({super.key, this.initialName});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GoalInputScreen(userName: name)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: SizedBox(
            width: 393,
            height: 852,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 110, 40, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: '이름을 적어주세요',
                    hint: '이름',
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _next(),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 48),
                  PrimaryButton(label: '다음', onPressed: _controller.text.trim().isEmpty ? null : _next),
                ],
              ),
            ),
          ),
      ),
    );
  }
}
