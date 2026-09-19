import 'package:flutter/material.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'goal_input_screen.dart';

/// Figma: iPhone 16 - 3
class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalInputScreen(userName: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 80, 28, 0),
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
              const SizedBox(height: 28),
              PrimaryButton(
                label: '다음',
                onPressed: _controller.text.trim().isEmpty ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
