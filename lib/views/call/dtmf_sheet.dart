import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dtmf_tones.dart';
import '../../core/utils/haptics.dart';

class DtmfKeypadSheet extends StatelessWidget {
  final Function(String) onKeyPressed;

  const DtmfKeypadSheet({super.key, required this.onKeyPressed});

  static const List<Map<String, String>> keys = [
    {'digit': '1', 'letters': ''},
    {'digit': '2', 'letters': 'ABC'},
    {'digit': '3', 'letters': 'DEF'},
    {'digit': '4', 'letters': 'GHI'},
    {'digit': '5', 'letters': 'JKL'},
    {'digit': '6', 'letters': 'MNO'},
    {'digit': '7', 'letters': 'PQRS'},
    {'digit': '8', 'letters': 'TUV'},
    {'digit': '9', 'letters': 'WXYZ'},
    {'digit': '*', 'letters': ''},
    {'digit': '0', 'letters': '+'},
    {'digit': '#', 'letters': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Touch-Tone Keypad (DTMF)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 18,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final item = keys[index];
              final digit = item['digit']!;
              return InkWell(
                onTap: () {
                  Haptics.light();
                  DtmfPlayer.playTone(digit);
                  onKeyPressed(digit);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
