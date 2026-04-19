import 'package:flutter/material.dart';

import '../config/profile_config.dart';
import '../i18n/app_strings.dart';
import '../models/user_profile.dart';
import '../services/account_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../ui/profile_avatar.dart';
import '../utils/error_display.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.owner});

  final String owner;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _customRelationController = TextEditingController();
  final _api = AccountApiService();

  String _relationshipLabel = '';
  bool _useCustomRelation = false;
  String _avatarKey = '';
  bool _saving = false;
  bool _loading = true;
  String? _error;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _api.getProfile(widget.owner);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile.displayName;
        _bioController.text = profile.bio ?? '';
        _relationshipLabel = profile.relationshipLabel;
        _avatarKey = profile.avatar ?? '';
        _useCustomRelation = !AppStrings.relationshipPresets.contains(_relationshipLabel);
        if (_useCustomRelation) {
          _customRelationController.text = _relationshipLabel;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _customRelationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final displayName = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final relation = _useCustomRelation
        ? _customRelationController.text.trim()
        : _relationshipLabel;

    setState(() => _saving = true);
    try {
      final updated = await _api.updateProfile(
        owner: widget.owner,
        displayName: displayName,
        bio: bio.isEmpty ? null : bio,
        avatar: _avatarKey.isEmpty ? null : _avatarKey,
        relationshipLabel: relation,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.editProfileSaved)),
      );
      Navigator.pop(context, updated);
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

  String? _validateDisplayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < ProfileConfig.displayNameMin) {
      return AppStrings.editProfileNameMinDetail(ProfileConfig.displayNameMin);
    }
    if (text.length > ProfileConfig.displayNameMax) {
      return AppStrings.editProfileNameMaxDetail(ProfileConfig.displayNameMax);
    }
    return null;
  }

  String? _validateBio(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > ProfileConfig.bioMax) {
      return AppStrings.editProfileBioMaxDetail(ProfileConfig.bioMax);
    }
    return null;
  }

  String? _validateCustomRelation(String? value) {
    if (!_useCustomRelation) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.editProfileRelationRequired;
    if (text.length > ProfileConfig.relationshipLabelMax) {
      return AppStrings.editProfileRelationMaxDetail(
        ProfileConfig.relationshipLabelMax,
      );
    }
    return null;
  }

  void _selectRelationPreset(String label) {
    setState(() {
      _relationshipLabel = label;
      _useCustomRelation = false;
    });
  }

  void _selectCustomRelation() {
    setState(() {
      _useCustomRelation = true;
      _relationshipLabel = _customRelationController.text.trim();
    });
  }

  void _selectAvatar(String key) {
    setState(() => _avatarKey = key);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editProfileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editProfileTitle)),
        body: Center(child: Text(_error!)),
      );
    }
    final selectedAvatar = resolveAvatarPreset(_avatarKey);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfileTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.check_rounded),
        label: Text(
          _saving ? AppStrings.editProfileSaving : AppStrings.editProfileSave,
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
              _buildSectionTitle(
                AppStrings.editProfileSectionBasic,
                AppStrings.editProfileSectionBasicHint,
              ),
              AppSpace.h8,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AppSurface.card(alpha: 0.95),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.editProfileDisplayName,
                      ),
                      validator: _validateDisplayName,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: AppStrings.editProfileBio,
                        hintText: AppStrings.editProfileBioHint,
                      ),
                      validator: _validateBio,
                    ),
                  ],
                ),
              ),
              AppSpace.h16,
              _buildSectionTitle(
                AppStrings.editProfileSectionAvatar,
                AppStrings.editProfileSectionAvatarHint,
              ),
              AppSpace.h8,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AppSurface.card(alpha: 0.95),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: selectedAvatar.bgColor,
                      child: Icon(
                        selectedAvatar.icon,
                        color: selectedAvatar.fgColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: profileAvatarPresets
                          .map(
                            (preset) => GestureDetector(
                              onTap: () => _selectAvatar(preset.key),
                              child: Container(
                                width: 76,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: preset.bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _avatarKey == preset.key
                                        ? AppTheme.primary
                                        : AppTheme.panelBorder,
                                    width: _avatarKey == preset.key ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      preset.icon,
                                      color: preset.fgColor,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      preset.label,
                                      style: AppText.bodyMuted().copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              AppSpace.h16,
              _buildSectionTitle(
                AppStrings.editProfileSectionRelation,
                AppStrings.editProfileSectionRelationHint,
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
                            selected: !_useCustomRelation &&
                                _relationshipLabel == label,
                            onSelected: (_) => _selectRelationPreset(label),
                          ),
                        ),
                        ChoiceChip(
                          label: const Text(AppStrings.editProfileCustomLabel),
                          selected: _useCustomRelation,
                          onSelected: (_) => _selectCustomRelation(),
                        ),
                      ],
                    ),
                    if (_useCustomRelation) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customRelationController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.editProfileCustomLabel,
                          hintText: AppStrings.editProfileCustomLabelHint,
                        ),
                        onChanged: (value) =>
                            _relationshipLabel = value.trim(),
                        validator: _validateCustomRelation,
                      ),
                    ],
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(subtitle, style: AppText.sectionSubtitle),
          ],
        ),
      ],
    );
  }
}
