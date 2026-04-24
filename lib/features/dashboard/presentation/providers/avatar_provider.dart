import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AvatarStyle {
  final Color skinColor;
  final Color hairColor;
  final Color clothingColor;

  const AvatarStyle({
    required this.skinColor,
    required this.hairColor,
    required this.clothingColor,
  });
}

final avatarProvider = StateProvider<AvatarStyle>((ref) {
  return const AvatarStyle(
    skinColor: Color(0xFFE8B8A3),
    hairColor: Color(0xFF5D4037),
    clothingColor: Color(0xFF4CAF50),
  );
});
