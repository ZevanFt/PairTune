import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import 'app_theme.dart';

class ProfileAvatarPreset {
  const ProfileAvatarPreset({
    required this.key,
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
}

const List<ProfileAvatarPreset> profileAvatarPresets = [
  ProfileAvatarPreset(
    key: 'sunny',
    label: AppStrings.editProfileAvatarSunny,
    icon: Icons.wb_sunny_rounded,
    bgColor: AppTheme.softAmber,
    fgColor: AppTheme.primary,
  ),
  ProfileAvatarPreset(
    key: 'moon',
    label: AppStrings.editProfileAvatarMoon,
    icon: Icons.nightlight_round,
    bgColor: AppTheme.softViolet,
    fgColor: AppTheme.primary,
  ),
  ProfileAvatarPreset(
    key: 'leaf',
    label: AppStrings.editProfileAvatarLeaf,
    icon: Icons.park_rounded,
    bgColor: AppTheme.softGreen,
    fgColor: AppTheme.primary,
  ),
  ProfileAvatarPreset(
    key: 'spark',
    label: AppStrings.editProfileAvatarSpark,
    icon: Icons.auto_awesome_rounded,
    bgColor: AppTheme.softRose,
    fgColor: AppTheme.primary,
  ),
  ProfileAvatarPreset(
    key: 'wave',
    label: AppStrings.editProfileAvatarWave,
    icon: Icons.water_rounded,
    bgColor: AppTheme.softBlue,
    fgColor: AppTheme.primary,
  ),
  ProfileAvatarPreset(
    key: 'shield',
    label: AppStrings.editProfileAvatarShield,
    icon: Icons.shield_rounded,
    bgColor: AppTheme.surfaceMuted,
    fgColor: AppTheme.primary,
  ),
];

ProfileAvatarPreset resolveAvatarPreset(String? key) {
  if (key == null || key.isEmpty) {
    return profileAvatarPresets.first;
  }
  return profileAvatarPresets.firstWhere(
    (preset) => preset.key == key,
    orElse: () => profileAvatarPresets.first,
  );
}
