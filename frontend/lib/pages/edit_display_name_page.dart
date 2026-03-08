import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EditDisplayNamePage extends StatefulWidget {
  const EditDisplayNamePage({super.key, required this.initialName});

  final String initialName;

  @override
  State<EditDisplayNamePage> createState() => _EditDisplayNamePageState();
}

class _EditDisplayNamePageState extends State<EditDisplayNamePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑昵称')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submit,
        icon: const Icon(Icons.check_rounded),
        label: const Text('保存昵称'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.blush,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '资料设置',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '昵称用于任务、通知与协作展示',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.panel.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.panelBorder),
                ),
                child: TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: '昵称'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '请输入昵称' : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
