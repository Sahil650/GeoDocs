import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/utils/responsive_helper.dart';
import '../services/geotag_service.dart';
import 'multi_page_preview_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {

  late DocumentScanner _scanner;

  final List<String> _pages = [];

  bool _isOpening = false;
  final bool _firstOpen = true;

  @override
  void initState() {

    super.initState();

    _scanner = DocumentScanner(
      options: DocumentScannerOptions(
        mode: ScannerMode.full,
        pageLimit: 1,
        isGalleryImport: false,
      ),
    );

    /// open ML Kit automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {

      _openScanner();

    });

  }

  @override
  void dispose() {

    _scanner.close();

    super.dispose();

  }

  /// open ML kit camera
  Future<void> _openScanner() async {

    if (_isOpening) return;

    _isOpening = true;

    try {

      final result =
          await _scanner.scanDocument();

      if (result.images != null &&
          result.images!.isNotEmpty) {

        final savedPath =
            await _copyToTemp(
                result.images!.first);

        _pages.add(savedPath);

      }

    }

    catch (e) {

      debugPrint(e.toString());

    }

    _isOpening = false;

    if (mounted) {
      setState(() {});
    }

  }

  Future<String> _copyToTemp(String src) async {

    final dir =
        await getTemporaryDirectory();

    final newPath = p.join(

      dir.path,

      "${const Uuid().v4()}.jpg",

    );

    await File(src).copy(newPath);

    return newPath;

  }

  /// open preview screen
  Future<void> _openPreview() async {

    final loc =
        await GeotagService.getLocation();

    if (!mounted) return;

    final updatedPages =
        await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) =>
            MultiPagePreviewScreen(

          pages: _pages,

          address: loc.address,

          lat: loc.lat,

          lng: loc.lng,

        ),

      ),

    );

    if (updatedPages != null) {

      _pages.clear();

      _pages.addAll(
          List<String>.from(updatedPages));

    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final buttonHeight = ResponsiveHelper.getButtonHeight(context);
    final fontSize = ResponsiveHelper.getFontSize(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Text(
              "Scanner Ready",
              style: TextStyle(
                color: Colors.white,
                fontSize: isLargeScreen ? 24 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// scan button
          Positioned(
            bottom: isLargeScreen ? 180 : 120,
            left: 0,
            right: 0,

            child: Center(
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _openScanner,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(isLargeScreen ? 200 : 150, buttonHeight),
                  ),
                  child: Text(
                    "Scan Page",
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ),
            ),
          ),

          /// preview button
          if (_pages.isNotEmpty)
            Positioned(
              bottom: isLargeScreen ? 80 : 50,
              left: 0,
              right: 0,

              child: Center(
                child: SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _openPreview,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(isLargeScreen ? 200 : 150, buttonHeight),
                    ),
                    child: Text(
                      "Preview (${_pages.length})",
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }

}