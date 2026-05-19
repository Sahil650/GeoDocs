import 'package:flutter/material.dart';

class CropPoints {

  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;

  CropPoints({

    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });
}