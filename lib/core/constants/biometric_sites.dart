import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';

class BiometricSite {
  final String id;
  final String label;
  final IconData icon;

  const BiometricSite({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class BiometricSites {
  static const List<BiometricSite> all = [
    BiometricSite(id: 'neck', label: 'NECK', icon: PhosphorIconsFill.shield),
    BiometricSite(id: 'shoulders', label: 'SHOULDERS', icon: PhosphorIconsFill.plusCircle),
    BiometricSite(id: 'chest', label: 'CHEST', icon: PhosphorIconsFill.target),
    BiometricSite(id: 'waist', label: 'WAIST', icon: PhosphorIconsFill.compass),
    BiometricSite(id: 'left_bicep', label: 'LEFT BICEP', icon: PhosphorIconsFill.armchair), // Using metaphors or close matches
    BiometricSite(id: 'right_bicep', label: 'RIGHT BICEP', icon: PhosphorIconsFill.armchair),
    BiometricSite(id: 'left_forearm', label: 'LEFT FOREARM', icon: PhosphorIconsFill.handPointing),
    BiometricSite(id: 'right_forearm', label: 'RIGHT FOREARM', icon: PhosphorIconsFill.handPointing),
    BiometricSite(id: 'left_thigh', label: 'LEFT THIGH', icon: PhosphorIconsFill.boot),
    BiometricSite(id: 'right_thigh', label: 'RIGHT THIGH', icon: PhosphorIconsFill.boot),
    BiometricSite(id: 'left_calf', label: 'LEFT CALF', icon: PhosphorIconsFill.steps),
    BiometricSite(id: 'right_calf', label: 'RIGHT CALF', icon: PhosphorIconsFill.steps),
  ];

  static BiometricSite getById(String id) {
    return all.firstWhere((s) => s.id == id, 
      orElse: () => BiometricSite(id: 'unknown', label: id.toUpperCase(), icon: PhosphorIconsFill.question));
  }
}
