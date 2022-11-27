import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:ui' as ui;
import 'package:face_mask/coordinates_translator.dart';

class FacePainter extends CustomPainter {
  final ui.Image? image;
  final List<bool> _isBlue;
  final List<Rect> _rects;
  final Size? absoluteImageSize;
  final InputImageRotation? rotation;

  FacePainter(this._isBlue, this._rects,
      {this.image, this.absoluteImageSize, this.rotation});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.red;
    final Paint paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.cyanAccent;
    if (image != null) {
      canvas.drawImage(image!, Offset.zero, Paint());
      for (int i = 0; i < _rects.length; i++) {
        if (_isBlue[i]) {
          canvas.drawRect(_rects[i], paint2);
        } else {
          canvas.drawRect(_rects[i], paint1);
        }
      }
    } else {
      for (int i = 0; i < _rects.length; i++) {
        canvas.drawRect(
            Rect.fromLTRB(
                translateX(_rects[i].left, rotation!, size, absoluteImageSize!),
                translateY(_rects[i].top, rotation!, size, absoluteImageSize!),
                translateX(
                    _rects[i].right, rotation!, size, absoluteImageSize!),
                translateY(
                    _rects[i].bottom, rotation!, size, absoluteImageSize!)),
            _isBlue[i] ? paint2 : paint1);
      }
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate._rects != _rects ||
        oldDelegate._isBlue != _isBlue ||
        oldDelegate.rotation != rotation ||
        oldDelegate.image != image;
  }
}
