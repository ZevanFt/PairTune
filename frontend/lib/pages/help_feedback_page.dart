import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/profile_config.dart';
import '../i18n/app_strings.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _contactController = TextEditingController();

  String _category = AppStrings.feedbackCategories.first;
  List<Map<String, dynamic>> _recent = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ProfileConfig.prefFeedbackItems);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _recent = data.whereType<Map<String, dynamic>>().take(20).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recent = []);
    }
  }

  Future<void> _saveFeedback() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = {
      'category': _category,
      'title': _titleController.text.trim(),
      'detail': _detailController.text.trim(),
      'contact': _contactController.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    };
    final next = [item, ..._recent];
    final trimmed = next.take(20).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ProfileConfig.prefFeedbackItems, jsonEncode(trimmed));
    if (!mounted) return;
    setState(() {
      _recent = trimmed;
      _saving = false;
      _titleController.clear();
      _detailController.clear();
      _contactController.clear();
      _category = AppStrings.feedbackCategories.first;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.helpFeedbackSaved)),
    );
  }

  Future<void> _copyFeedback() async {
    final payload = jsonEncode({
      'category': _category,
      'title': _titleController.text.trim(),
      'detail': _detailController.text.trim(),
      'contact': _contactController.text.trim(),
    });
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.helpFeedbackCopied)),
    );
  }

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.helpFeedbackTitleRequired;
    if (text.length > ProfileConfig.feedbackTitleMax) {
      return AppStrings.helpFeedbackTitleMaxDetail(
        ProfileConfig.feedbackTitleMax,
      );
    }
    return null;
  }

  String? _validateDetail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.helpFeedbackDetailRequired;
    if (text.length > ProfileConfig.feedbackBodyMax) {
      return AppStrings.helpFeedbackDetailMaxDetail(
        ProfileConfig.feedbackBodyMax,
      );
    }
    return null;
  }

  String? _validateContact(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > ProfileConfig.feedbackContactMax) {
      return AppStrings.helpFeedbackContactMaxDetail(
        ProfileConfig.feedbackContactMax,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.helpTitle)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            _buildSectionTitle(AppStrings.helpSectionFaq, AppStrings.helpSectionFaqHint),
            AppSpace.h8,
            _buildFaqCard(),
            AppSpace.h16,
            _buildSectionTitle(
              AppStrings.helpSectionFeedback,
              AppStrings.helpSectionFeedbackHint,
            ),
            AppSpace.h8,
            _buildFeedbackForm(),
            if (_recent.isNotEmpty) ...[
              AppSpace.h16,
              _buildSectionTitle(AppStrings.helpRecentFeedback, ''),
              AppSpace.h8,
              ..._recent.take(3).map(_buildRecentItem),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (subtitle.isNotEmpty) Text(subtitle, style: AppText.sectionSubtitle),
          ],
        ),
      ],
    );
  }

  Widget _buildFaqCard() {
    final faqs = [
      (AppStrings.helpFaqQ1, AppStrings.helpFaqA1),
      (AppStrings.helpFaqQ2, AppStrings.helpFaqA2),
      (AppStrings.helpFaqQ3, AppStrings.helpFaqA3),
    ];
    return Container(
      decoration: AppSurface.card(alpha: 0.95),
      child: Column(
        children: faqs
            .map(
              (item) => ExpansionTile(
                title: Text(item.$1, style: AppText.cardTitle),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  Text(item.$2, style: AppText.bodyMuted),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppSurface.card(alpha: 0.95),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: AppStrings.helpFeedbackCategory),
              items: AppStrings.feedbackCategories
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.helpFeedbackTitle,
                suffixText: AppStrings.helpFeedbackLimit(
                  _titleController.text.length,
                  ProfileConfig.feedbackTitleMax,
                ),
              ),
              validator: _validateTitle,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _detailController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: AppStrings.helpFeedbackDetail,
                suffixText: AppStrings.helpFeedbackLimit(
                  _detailController.text.length,
                  ProfileConfig.feedbackBodyMax,
                ),
              ),
              validator: _validateDetail,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: AppStrings.helpFeedbackContact,
              ),
              validator: _validateContact,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _copyFeedback,
                    child: const Text(AppStrings.helpFeedbackCopy),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _saveFeedback,
                    child: Text(
                      _saving
                          ? AppStrings.helpFeedbackSubmitting
                          : AppStrings.helpFeedbackSubmit,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppSurface.subtleCard(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.softBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.question_answer_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String? ?? '', style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '${item['category'] ?? ''}',
                  style: AppText.bodyMuted,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonEncode(item)));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.helpFeedbackCopied)),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            tooltip: AppStrings.helpFeedbackCopyTooltip,
          ),
        ],
      ),
    );
  }
}
