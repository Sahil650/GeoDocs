import 'dart:io';
import 'package:flutter/material.dart';

import '../models/crop_points.dart';

class EdgeAdjustScreen extends StatefulWidget {

  final String imagePath;

  final Function(String) onDone;

  const EdgeAdjustScreen({

    super.key,

    required this.imagePath,

    required this.onDone,
  });

  @override
  State<EdgeAdjustScreen> createState() =>
      _EdgeAdjustScreenState();
}

class _EdgeAdjustScreenState
    extends State<EdgeAdjustScreen> {

  late CropPoints points;

  @override
  void initState() {

    super.initState();

    points = CropPoints(

      topLeft: const Offset(60,120),

      topRight: const Offset(320,120),

      bottomLeft: const Offset(60,500),

      bottomRight: const Offset(320,500),
    );
  }

  Widget corner(Offset offset, Function(Offset) onDrag){

    return Positioned(

      left: offset.dx,

      top: offset.dy,

      child: GestureDetector(

        onPanUpdate: (d){

          onDrag(

            Offset(

              offset.dx + d.delta.dx,

              offset.dy + d.delta.dy,
            ),
          );
        },

        child: Container(

          width: 22,

          height: 22,

          decoration: const BoxDecoration(

            color: Colors.yellow,

            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        title: const Text("Adjust edges"),
      ),

      body: Stack(

        children: [

          Positioned.fill(

            child: Image.file(

              File(widget.imagePath),

              fit: BoxFit.contain,
            ),
          ),

          corner(points.topLeft,

            (p)=>setState(()=>points.topLeft=p)),

          corner(points.topRight,

            (p)=>setState(()=>points.topRight=p)),

          corner(points.bottomLeft,

            (p)=>setState(()=>points.bottomLeft=p)),

          corner(points.bottomRight,

            (p)=>setState(()=>points.bottomRight=p)),

          Align(

            alignment: Alignment.bottomCenter,

            child: Padding(

              padding: const EdgeInsets.all(20),

              child: ElevatedButton(

                onPressed: (){

                  widget.onDone(widget.imagePath);

                  Navigator.pop(context);
                },

                child: const Text("Confirm Crop"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}