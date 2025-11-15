import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool outlined;

  const CustomButton({super.key, required this.text, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        width: double.infinity,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : primary,
          border: outlined ? Border.all(color: primary, width: 2) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: outlined
              ? []
              : [
                  BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: outlined ? primary : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
