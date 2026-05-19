
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/utils/responsive_helper.dart';
import 'settings_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'watermark_screen.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();

}

class _ProfileScreenState
    extends State<ProfileScreen> {

  User? user =
      FirebaseAuth.instance.currentUser;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  /// LOGIN
  Future login() async {

    await _googleSignIn.initialize(
      serverClientId:
      "17664552951-gvc3e9gltihv4grgrpc5uk1r7qnptb13.apps.googleusercontent.com",
    );

    final account =
        await _googleSignIn.authenticate();

    final auth =
        account.authentication;

    final credential =
        GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );

    final result =
        await FirebaseAuth.instance
            .signInWithCredential(
      credential,
    );

    setState(() {
      user = result.user;
    });

  }

  /// LOGOUT
  Future logout() async {

    await _googleSignIn.signOut();

    await FirebaseAuth.instance.signOut();

    setState(() {
      user = null;
    });

  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final contentWidth = ResponsiveHelper.getContainerWidth(context);
    final avatarSize = ResponsiveHelper.getAvatarSize(context);
    final padding = ResponsiveHelper.getPadding(context);
    final fontSize = ResponsiveHelper.getFontSize(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: contentWidth,
          padding: padding,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                /// PROFILE IMAGE
                CircleAvatar(
                  radius: avatarSize,
                  backgroundImage: user != null && user!.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user == null
                      ? Icon(Icons.person, size: avatarSize)
                      : null,
                ),

                SizedBox(height: ResponsiveHelper.scale(context, 10)),

                /// NAME
                Text(
                  user?.displayName ?? "Guest User",
                  style: TextStyle(
                    fontSize: isDesktop ? 26 : (isTablet ? 22 : 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                /// EMAIL
                Text(
                  user?.email ?? "Login to sync data",
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: ResponsiveHelper.scale(context, 20)),

                /// LOGIN BUTTON
                if (user == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: login,
                      icon: const Icon(Icons.login),
                      label: const Text("Login with Google"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                          double.infinity,
                          ResponsiveHelper.getButtonHeight(context),
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: ResponsiveHelper.scale(context, 10)),

                /// SETTINGS
                _cardTile(Icons.settings, "Settings", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),

                /// WATERMARK
                _cardTile(Icons.image, "Change Watermark", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WatermarkScreen()));
                }),

                /// PRIVACY
                _cardTile(Icons.lock, "Privacy", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
                }),

                /// HELP
                _cardTile(Icons.help, "Help & Support", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
                }),

                /// ABOUT
                _cardTile(Icons.info, "About App", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                }),

                SizedBox(height: ResponsiveHelper.scale(context, 20)),

                /// LOGOUT BUTTON
                if (user != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: Size(double.infinity, ResponsiveHelper.getButtonHeight(context)),
                      ),
                      child: const Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                  ),

                SizedBox(height: ResponsiveHelper.scale(context, 20)),

              ],

            ),

          ),

        ),

      ),

    );

  }

  /// RESPONSIVE TILE
  Widget _cardTile(IconData icon, String title, VoidCallback onTap) {
    final borderRadius = ResponsiveHelper.getBorderRadius(context);
    final elevation = ResponsiveHelper.getCardElevation(context);
    final iconSize = ResponsiveHelper.getIconSize(context);
    final fontSize = ResponsiveHelper.getFontSize(context);

    return Card(
      elevation: elevation,
      margin: EdgeInsets.symmetric(vertical: ResponsiveHelper.scale(context, 6)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.scale(context, 14),
          vertical: ResponsiveHelper.scale(context, 4),
        ),
        leading: Icon(icon, color: Colors.deepPurple, size: iconSize),
        title: Text(title, style: TextStyle(fontSize: fontSize)),
        trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveHelper.scale(context, 16)),
        onTap: onTap,
      ),
    );
  }
}