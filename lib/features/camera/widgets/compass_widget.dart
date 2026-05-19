
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CompassWidget extends StatelessWidget {
  const CompassWidget({super.key});

  String getDirectionLabel(double degree) {
    if (degree >= 337.5 || degree < 22.5) return 'N';
    if (degree >= 22.5 && degree < 67.5) return 'NE';
    if (degree >= 67.5 && degree < 112.5) return 'E';
    if (degree >= 112.5 && degree < 157.5) return 'SE';
    if (degree >= 157.5 && degree < 202.5) return 'S';
    if (degree >= 202.5 && degree < 247.5) return 'SW';
    if (degree >= 247.5 && degree < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {

    return Container(

      height: 85,
      width: 85,

      decoration: BoxDecoration(

        shape: BoxShape.circle,

        color: Colors.black.withValues(alpha: 0.65),

        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),

        boxShadow: [

          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
          ),

        ],

      ),

      child: StreamBuilder<CompassEvent>(

        stream: FlutterCompass.events,

        builder: (context, snapshot) {

          /// sensor not ready
          if (!snapshot.hasData ||
              snapshot.data!.heading == null) {

            return const Center(

              child: Icon(
                Icons.explore,
                color: Colors.white54,
                size: 28,
              ),

            );

          }

          double direction =
              snapshot.data!.heading!;

          String label =
              getDirectionLabel(direction);

          int degree =
              direction.round();

          return Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              /// arrow
              Transform.rotate(

                angle:
                    direction * (pi / 180) * -1,

                child: const Icon(

                  Icons.navigation,

                  size: 32,

                  color: Colors.redAccent,

                ),

              ),

              const SizedBox(height: 3),

              /// direction label
              Text(

                "$degree° $label",

                style: const TextStyle(

                  color: Colors.white,

                  fontSize: 11,

                  fontWeight:
                      FontWeight.w600,

                  letterSpacing: 0.5,

                ),

              ),

            ],

          );

        },

      ),

    );

  }

}