import 'package:flutter/material.dart';

import '../models/product_item.dart';
import '../ui/app_theme.dart';

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.stock,
  });

  final String name;
  final String? description;
  final int pointsCost;
  final int stock;
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.initial});

  final ProductItem? initial;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController();
  final _stockController = TextEditingController();

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _descController.text = initial.description ?? '';
      _pointsController.text = '${initial.pointsCost}';
      _stockController.text = '${initial.stock}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _pointsController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = ProductDraft(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      pointsCost: int.tryParse(_pointsController.text.trim()) ?? 0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
    );
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑商品' : '发布商品')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submit,
        icon: const Icon(Icons.check_rounded),
        label: Text(_isEditing ? '保存商品' : '发布商品'),
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
              _sectionTitle('商品信息', '填写奖励名称与描述'),
              const SizedBox(height: 8),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '商品名称'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? '请输入商品名称' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: '描述（可选）'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionTitle('兑换规则', '设置积分消耗与库存数量'),
              const SizedBox(height: 8),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '所需积分'),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 0) return '请输入有效积分';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '库存'),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 0) return '请输入有效库存';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
