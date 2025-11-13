  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';

  enum ButtonState { enablen, disable, loadding }

  class Custombutton extends StatelessWidget {
    final String text;
    final VoidCallback onpressed;
    final ButtonState state;

    const Custombutton({
      super.key,
      required this.text,
      this.state = ButtonState.disable,
      required this.onpressed,
    });

    @override
    Widget build(BuildContext context) {
      return ElevatedButton(
        onPressed: state == ButtonState.enablen ? onpressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _buildChild(),
      );
    }

    Widget _buildChild() {
      switch (state) {
        case ButtonState.loadding:
          return const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          );
        case ButtonState.disable:
        case ButtonState.enablen:
          return Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          );
      }
    }
  }
