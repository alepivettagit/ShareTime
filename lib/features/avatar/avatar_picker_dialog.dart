import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'avatar_widget.dart';

class AvatarChoice {
  final String seed;
  final String colorHex;

  const AvatarChoice({required this.seed, required this.colorHex});
}

class AvatarPickerDialog extends StatefulWidget {
  final String initialSeed;
  final String initialColorHex;

  const AvatarPickerDialog({
    super.key,
    required this.initialSeed,
    required this.initialColorHex,
  });

  static Future<AvatarChoice?> show(
    BuildContext context, {
    required String currentSeed,
    required String currentColorHex,
  }) {
    return showDialog<AvatarChoice>(
      context: context,
      builder: (context) => AvatarPickerDialog(
        initialSeed: currentSeed,
        initialColorHex: currentColorHex,
      ),
    );
  }

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  late String _selectedSeed;
  late String _selectedColorHex;
  late List<AvatarChoice> _avatarGrid;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _selectedSeed = widget.initialSeed;
    _selectedColorHex = widget.initialColorHex;
    _generateGrid();
  }

  void _generateGrid() {
    final colors = AppColors.avatarPalette;
    _avatarGrid = List.generate(24, (index) {
      final randInt = _rng.nextInt(0xFFFFFF);
      final seed = 'node_${index}_${randInt.toRadixString(16)}';
      final color = colors[index % colors.length];
      return AvatarChoice(seed: seed, colorHex: color);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined, color: AppColors.primaryCyan, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Scegli il tuo Avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Preview Centrale Ingrandita
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryCyan.withOpacity(0.4), width: 1.5),
                ),
                child: AvatarWidget(
                  seed: _selectedSeed,
                  colorHex: _selectedColorHex,
                  size: 76,
                  showGlow: true,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Griglia 24 opzioni
            Flexible(
              child: SizedBox(
                height: 240,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _avatarGrid.length,
                  itemBuilder: (context, index) {
                    final choice = _avatarGrid[index];
                    final isSelected = _selectedSeed == choice.seed &&
                        _selectedColorHex == choice.colorHex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSeed = choice.seed;
                          _selectedColorHex = choice.colorHex;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: AppColors.primaryCyan, width: 2)
                              : null,
                        ),
                        child: AvatarWidget(
                          seed: choice.seed,
                          colorHex: choice.colorHex,
                          size: 38,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _generateGrid();
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Rimescola'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      AvatarChoice(
                        seed: _selectedSeed,
                        colorHex: _selectedColorHex,
                      ),
                    );
                  },
                  child: const Text('Conferma'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
