import 'package:flutter/material.dart';

import '../features/camera/screens/camera_screen.dart';
// import '../features/gallery/screens/gallery_screen.dart';
// import '../features/form/screens/form_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class BottomNavbar extends StatefulWidget {

  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();

}

class _BottomNavbarState extends State<BottomNavbar> {

  int currentIndex = 2;

  final List pages = [

    // const FormScreen(),

    // const GalleryScreen(),

    const CameraScreen(),

    const Center(child: Text("Convert")),

    const ProfileScreen(),

  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,

        selectedItemColor: Colors.deepPurple,

        unselectedItemColor: Colors.grey,

        currentIndex: currentIndex,

        onTap: (index){

          setState(() {

            currentIndex = index;

          });

        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: "Form",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: "Gallery",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, size: 32),
            label: "Camera",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            label: "Convert",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),

        ],

      ),

    );

  }

}