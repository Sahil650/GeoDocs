import 'dart:io';
import 'package:flutter/material.dart';

class CropScreen extends StatelessWidget {

  final String imagePath;

  final int pageNumber;

  final Function(String) onSaved;

  const CropScreen({

    super.key,

    required this.imagePath,

    required this.pageNumber,

    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        title: Text("Page $pageNumber"),

        backgroundColor: Colors.black,

        actions: [

          TextButton(

            onPressed: (){

              Navigator.pop(context);
            },

            child: const Text(

              "RETAKE",

              style: TextStyle(

                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      body: Column(

        children: [

          Expanded(

            child: Padding(

              padding: const EdgeInsets.all(12),

              child: ClipRRect(

                borderRadius:
                    BorderRadius.circular(12),

                child: Image.file(

                  File(imagePath),

                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Container(

            padding: const EdgeInsets.all(20),

            decoration: const BoxDecoration(

              color: Colors.black,
            ),

            child: Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,

              children: [

                ElevatedButton.icon(

                  style: ElevatedButton.styleFrom(

                    backgroundColor: Colors.grey[800],
                  ),

                  onPressed: (){

                    Navigator.pop(context);
                  },

                  icon:
                      const Icon(Icons.refresh),

                  label:
                      const Text("Retake"),
                ),

                ElevatedButton.icon(

                  style: ElevatedButton.styleFrom(

                    backgroundColor: Colors.blue,
                  ),

                  onPressed: (){

                    onSaved(imagePath);

                    Navigator.pop(context);
                  },

                  icon:
                      const Icon(Icons.check),

                  label:
                      const Text("Use Photo"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}