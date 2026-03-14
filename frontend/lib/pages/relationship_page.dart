import 'package:flutter/material.dart';

import '../config/profile_config.dart';
import '../i18n/app_strings.dart';
import '../services/account_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';

class RelationshipPage extends StatefulWidget {
  const RelationshipPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<RelationshipPage> createState() => _RelationshipPageState();
}

class _RelationshipPageState extends State<RelationshipPage> {
  final _formKey = GlobalKey<FormState>();
  final _customLabelController = TextEditingController();
  final _api = AccountApiService();

  String _label = '';
  bool _useCustomLabel = false;
  bool _checkin = true;
  bool _reminder = true;
  bool _coopHint = true;
  bool _saving = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _label = widget.profile.relationshipLabel;
    _useCustomLabel = !AppStrings.relationshipPresets.contains(_label);
    if (_useCustomLabel) {
      _customLabelController.text = _label;
    }
    _loadSettings();
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _api.getSettings(widget.profile.owner);
      if (!mounted) return;
      setState(() {
        _checkin = settings.relationCheckin;
        _reminder = settings.relationReminder;
        _coopHint = settings.relationCoopHint;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = formatErrorMessage(e);
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final label = _useCustomLabel ? _customLabelController.text.trim() : _label;
    setState(() => _saving = true);
    try {
      final updatedProfile = await _api.updateProfile(
        owner: widget.profile.owner,
        displayName: widget.profile.displayName,
        bio: widget.profile.bio,
        avatar: widget.profile.avatar,
        relationshipLabel: label,
      );
      await _api.updateSettings(
        owner: widget.profile.owner,
        relationCheckin: _checkin,
        relationReminder: _reminder,
        relationCoopHint: _coopHint,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.relationshipSaved)),
      );
      Navigator.pop(context, updatedProfile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _validateCustomLabel(String? value) {
    if (!_useCustomLabel) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.relationshipLabelRequired;
    if (text.length > ProfileConfig.relationshipLabelMax) {
      return AppStrings.relationshipLabelMaxDetail(
        ProfileConfig.relationshipLabelMax,
      );
    }
    return null;
  }

  void _selectPreset(String label) {
    setState(() {
      _label = label;
      _useCustomLabel = false;
    });
  }

  void _selectCustom() {
    setState(() {
      _useCustomLabel = true;
      _label = _customLabelController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.relationshipTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.check_rounded),
        label: Text(
          _saving ? AppStrings.relationshipSaving : AppStrings.relationshipSave,
        ),
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
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: AppText.bodyMuted.copyWith(color: AppTheme.danger),
                  ),
                ),
              _buildSectionTitle(
                AppStrings.relationshipSectionLabel,
                AppStrings.relationshipSectionLabelHint,
              ),
              AppSpace.h8,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AppSurface.card(alpha: 0.95),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...AppStrings.relationshipPresets.map(
                          (label) => ChoiceChip(
                            label: Text(label),
                            selected: !_useCustomLabel && _label == label,
                            onSelected: (_) => _selectPreset(label),
                          ),
                        ),
                        ChoiceChip(
                          label: const Text(AppStrings.editProfileCustomLabel),
                          selected: _useCustomLabel,
                          onSelected: (_) => _selectCustom(),
                        ),
                      ],
                    ),
                    if (_useCustomLabel) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customLabelController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.editProfileCustomLabel,
                          hintText: AppStrings.editProfileCustomLabelHint,
                        ),
                        validator: _validateCustomLabel,
                        onChanged: (value) => _label = value.trim(),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpace.h16,
              _buildSectionTitle(
                AppStrings.relationshipSectionPrefs,
                '',
              ),
              AppSpace.h8,
              Container(
                padding: const EdgeInsets.all(4),
                decoration: AppSurface.card(alpha: 0.95),
                child: Column(
                  children: [
                    _buildSwitchItem(
                      AppStrings.relationshipPrefCheckin,
                      AppStrings.relationshipPrefCheckinHint,
                      _checkin,
                      (value) => setState(() => _checkin = value),
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      AppStrings.relationshipPrefReminder,
                      AppStrings.relationshipPrefReminderHint,
                      _reminder,
                      (value) => setState(() => _reminder = value),
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      AppStrings.relationshipPrefCoop,
                      AppStrings.relationshipPrefCoopHint,
                      _coopHint,
                      (value) => setState(() => _coopHint = value),
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

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      title: Text(title, style: AppText.cardTitle),
      subtitle: Text(subtitle, style: AppText.bodyMuted),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppTheme.border);
  }
}
