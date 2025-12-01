import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../domain/entities/actuator_state.dart';

class LedColorPickerButton extends StatelessWidget {
  final LedColor currentColor;
  final bool isSyncing;
  final void Function(LedColor) onColorChanged; // callback when color changed

  const LedColorPickerButton({
    super.key,
    required this.currentColor,
    this.isSyncing = false,
    required this.onColorChanged,
  });

  void _showColorPicker(BuildContext context) {
    Color pickerColor = Color.fromARGB(
      255,
      currentColor.red,
      currentColor.green,
      currentColor.blue,
    );
    // modal dialog
    showDialog(
      context: context, // in which screen to show the dialog
      builder: (context) => AlertDialog(
        title: const Text('Pick LED Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // to close the dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newLedColor = LedColor(
                red: (pickerColor.r * 255).round(),
                green: (pickerColor.g * 255).round(),
                blue: (pickerColor.b * 255).round(),
              );
              onColorChanged(newLedColor);
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSyncing ? null : () => _showColorPicker(context),
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color.fromARGB(
                255,
                currentColor.red,
                currentColor.green,
                currentColor.blue,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white54, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(
                    100,
                    currentColor.red,
                    currentColor.green,
                    currentColor.blue,
                  ),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isSyncing
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.palette, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
