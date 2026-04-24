import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maiself/features/dashboard/presentation/providers/avatar_provider.dart';
import 'package:maiself/presentation/widgets/avatar_widget.dart';

/// Page de sélection d'avatar
class AvatarShowcaseScreen extends ConsumerStatefulWidget {
  const AvatarShowcaseScreen({super.key});

  @override
  ConsumerState<AvatarShowcaseScreen> createState() => _AvatarShowcaseScreenState();
}

class _AvatarShowcaseScreenState extends ConsumerState<AvatarShowcaseScreen> {
  int selectedIndex = 0;

  static const _options = <AvatarStyle>[
    AvatarStyle(
      skinColor: Color(0xFFE8B8A3),
      hairColor: Color(0xFF5D4037),
      clothingColor: Color(0xFF4CAF50),
    ),
    AvatarStyle(
      skinColor: Color(0xFFE8B8A3),
      hairColor: Color(0xFFC65100),
      clothingColor: Color(0xFF2196F3),
    ),
    AvatarStyle(
      skinColor: Color(0xFFE8B8A3),
      hairColor: Color(0xFFFFD54F),
      clothingColor: Color(0xFFF44336),
    ),
    AvatarStyle(
      skinColor: Color(0xFFE8B8A3),
      hairColor: Color(0xFF1A1A1A),
      clothingColor: Color(0xFF9C27B0),
    ),
    AvatarStyle(
      skinColor: Color(0xFFFDBCAD),
      hairColor: Color(0xFF8D6E63),
      clothingColor: Color(0xFF00BCD4),
    ),
    AvatarStyle(
      skinColor: Color(0xFFD7A878),
      hairColor: Color(0xFF3E2723),
      clothingColor: Color(0xFFFFC107),
    ),
  ];

  static const _titles = [
    'Avatar par défaut',
    'Cheveux roux',
    'Cheveux blonds',
    'Cheveux noirs',
    'Teint clair',
    'Teint plus foncé',
  ];

  void _selectAvatar(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Variantes d\'avatars'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < _options.length; i++) ...[
              _AvatarSelectionCard(
                title: _titles[i],
                style: _options[i],
                selected: selectedIndex == i,
                onTap: () => _selectAvatar(i),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () {
                ref.read(avatarProvider.notifier).state = _options[selectedIndex];
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text(
                'Valider cet avatar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSelectionCard extends StatelessWidget {
  final String title;
  final AvatarStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarSelectionCard({
    required this.title,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF4CAF50) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: AvatarWidget(
                size: 120,
                skinColor: style.skinColor,
                hairColor: style.hairColor,
                clothingColor: style.clothingColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
