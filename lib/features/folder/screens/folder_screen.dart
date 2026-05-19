import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/services/storage_service.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() =>
      _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen>
    with TickerProviderStateMixin {

  List<FileSystemEntity> allFiles = [];
  List<FileSystemEntity> exportFiles = [];

  bool loading = true;
  bool newestFirst = true;

  bool selectionMode = false;
  Set<String> selectedFiles = {};

  Directory? photoDir;
  Directory? docDir;
  Directory? convertImageDir;
  Directory? exportDir;

  late TabController mainTab;
  late TabController convertTab;

  TextEditingController searchController =
      TextEditingController();

  String searchQuery = "";

  @override
  void initState() {

    super.initState();

    mainTab =
        TabController(length: 4, vsync: this);

    convertTab =
        TabController(length: 3, vsync: this);

    searchController.addListener(() {

      setState(() {

        searchQuery =
            searchController.text.toLowerCase();

      });

    });

    loadFiles();
  }

  Future loadFiles() async {
    setState(() => loading = true);
    try {
      final dirs = await StorageService.getAllDirectories();
      photoDir = dirs['photos'];
      docDir = dirs['docs'];
      convertImageDir = dirs['converted'];
      exportDir = dirs['exports'];

      if (photoDir != null && await photoDir!.exists()) {
        allFiles = photoDir!.listSync();
      }

      final appDir = await getApplicationDocumentsDirectory();
      exportFiles = appDir.listSync();
    } catch (e) {
      debugPrint("Error loading files: $e");
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  List<FileSystemEntity> sortFiles(
      List<FileSystemEntity> files) {

    final filtered =
        files.where((file) {

      final name =
          file.path.split("/").last.toLowerCase();

      return name.contains(searchQuery);

    }).toList();

    filtered.sort((a, b) {

      final aDate =
          a.statSync().modified;

      final bDate =
          b.statSync().modified;

      return newestFirst
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);

    });

    return filtered;
  }

  Map<String,
      List<FileSystemEntity>> groupByDate(
      List<FileSystemEntity> files) {

    final Map<String,
        List<FileSystemEntity>> grouped = {};

    final now = DateTime.now();

    for (var f in files) {

      final date =
          f.statSync().modified;

      String label;

      final diff =
          now.difference(date).inDays;

      if (diff == 0) {

        label = "Today";

      }

      else if (diff == 1) {

        label = "Yesterday";

      }

      else {

        label =
            DateFormat(
                "dd MMM yyyy")
                .format(date);

      }

      grouped.putIfAbsent(
          label, () => []);

      grouped[label]!.add(f);

    }

    return grouped;
  }

  List<FileSystemEntity> get photos =>
      allFiles.where((e) =>
          e.path.endsWith(".jpg") ||
          e.path.endsWith(".png")).toList();

  List<FileSystemEntity> get videos =>
      allFiles.where((e) =>
          e.path.endsWith(".mp4")).toList();

  List<FileSystemEntity> get docs =>
      (docDir != null && docDir!.existsSync())
          ? docDir!.listSync()
          : [];

  List<FileSystemEntity> get convertFiles =>
      (convertImageDir != null && convertImageDir!.existsSync())
          ? convertImageDir!.listSync().where((e) {
              final n = e.path.toLowerCase();
              return n.contains("img_");
            }).toList()
          : [];

  List<FileSystemEntity> get compressFiles {
    List<FileSystemEntity> results = [];
    
    // 1. Files from Converted folder (comp_ images)
    if (convertImageDir != null && convertImageDir!.existsSync()) {
      results.addAll(convertImageDir!.listSync().where((e) {
        final n = e.path.toLowerCase();
        return n.contains("comp_") || n.endsWith(".zip");
      }));
    }
    
    // 2. ZIP files from Export folder (where FileCompressScreen saves them)
    if (exportDir != null && exportDir!.existsSync()) {
      results.addAll(exportDir!.listSync().where((e) {
        return e.path.toLowerCase().endsWith(".zip");
      }));
    }
    
    return results;
  }

  List<FileSystemEntity> get exportConverted => [
        if (exportDir != null && exportDir!.existsSync())
          ...exportDir!.listSync().where((e) {
            final n = e.path.toLowerCase();
            return n.endsWith(".pdf") ||
                n.endsWith(".docx") ||
                n.endsWith(".xlsx") ||
                n.endsWith(".kml") ||
                n.endsWith(".gpx") ||
                n.endsWith(".zip");
          }),
        ...exportFiles
      ];

  Widget preview(String path) {

    if (path.endsWith(".jpg") ||
        path.endsWith(".png")) {

      return Image.file(

        File(path),

        fit: BoxFit.cover,

      );
    }

    if (path.endsWith(".pdf")) {

      return const Icon(

        Icons.picture_as_pdf,

        color: Colors.red,

        size: 40,

      );
    }

    if (path.endsWith(".zip")) {

      return const Icon(

        Icons.archive,

        size: 40,

      );
    }

    if (path.endsWith(".kml") ||
        path.endsWith(".gpx")) {

      return const Icon(

        Icons.map,

        size: 40,

      );
    }

    return const Icon(
        Icons.insert_drive_file);
  }

  Widget buildCard(File file) {

  final path = file.path;

  final name = path.split("/").last;

  final selected = selectedFiles.contains(path);

  final borderRadius = ResponsiveHelper.getBorderRadius(context);

  return GestureDetector(

    onLongPress: () {

      setState(() {

        selectionMode = true;

        selectedFiles.add(path);

      });

    },

    onTap: () {

      if (selectionMode) {

        setState(() {

          if (selected) {

            selectedFiles.remove(path);

            if (selectedFiles.isEmpty) {

              selectionMode = false;

            }

          } else {

            selectedFiles.add(path);

          }

        });

      } else {

        OpenFile.open(path);

      }

    },

    child: Container(

      decoration: BoxDecoration(

        color: const Color(0xfff1edf5),

        borderRadius: BorderRadius.circular(borderRadius + 10),

      ),

      padding: EdgeInsets.all(ResponsiveHelper.scale(context, 6)),

      child: Stack(

        children: [

          Card(

            elevation: ResponsiveHelper.getCardElevation(context),

            margin: EdgeInsets.zero,

            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(borderRadius),

              side: selected

                  ? const BorderSide(

                      color: Colors.deepPurple,

                      width: 2,

                    )

                  : BorderSide.none,

            ),

            child: Column(

              children: [

                Expanded(

                  child: ClipRRect(

                    borderRadius: const BorderRadius.vertical(

                      top: Radius.circular(16),

                    ),

                    child: Container(

                      width: double.infinity,

                      color: Colors.grey.shade200,

                      child: preview(path),

                    ),

                  ),

                ),

                Padding(

                  padding: const EdgeInsets.fromLTRB(

                      8, 8, 8, 4),

                  child: Text(

                    name,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(

                      fontSize: ResponsiveHelper.scale(context, 13),

                      fontWeight: FontWeight.w500,

                    ),

                  ),

                ),

                Padding(

                  padding: EdgeInsets.only(

                      bottom: ResponsiveHelper.scale(context, 6)),

                  child: Row(

                    mainAxisAlignment:

                        MainAxisAlignment.spaceEvenly,

                    children: [

                      IconButton(

                        icon: Icon(

                          Icons.delete,

                          size: ResponsiveHelper.getIconSize(context),

                        ),

                        onPressed: () async {

                          await file.delete();

                          loadFiles();

                        },

                      ),

                      IconButton(

                        icon: Icon(

                          Icons.share,

                          size: ResponsiveHelper.getIconSize(context),

                        ),

                        onPressed: () {

                          Share.shareXFiles(

                              [XFile(path)]);

                        },

                      ),

                    ],

                  ),

                ),

              ],

            ),

          ),

          if (selected)

            Positioned(

              top: ResponsiveHelper.scale(context, 8),

              right: ResponsiveHelper.scale(context, 8),

              child: CircleAvatar(

                radius: ResponsiveHelper.scale(context, 12),

                backgroundColor:

                    Colors.deepPurple,

                child: Icon(

                  Icons.check,

                  size: ResponsiveHelper.scale(context, 14),

                  color: Colors.white,

                ),

              ),

            ),

        ],

      ),

    ),

  );

}

  Widget buildGrid(
      List<FileSystemEntity> files) {

    final sorted =
        sortFiles(files);

    final grouped =
        groupByDate(sorted);

    return ListView(

      children:
          grouped.entries.map((e) {

        return Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Padding(

              padding:
                  const EdgeInsets.fromLTRB(
                      16, 16, 16, 6),

              child: Text(

                e.key,

                style:
                    TextStyle(

                  fontSize: ResponsiveHelper.scale(context, 16),

                  fontWeight:
                      FontWeight.bold,

                ),

              ),

            ),

            GridView.builder(

              shrinkWrap: true,

              physics:
                  const NeverScrollableScrollPhysics(),

              padding:
                  EdgeInsets.all(
                      ResponsiveHelper.scale(context, 12)),

              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),

                crossAxisSpacing:
                    ResponsiveHelper.scale(context, 14),

                mainAxisSpacing:
                    ResponsiveHelper.scale(context, 14),

                childAspectRatio:
                    0.72,

              ),

              itemCount:
                  e.value.length,

              itemBuilder: (_, i) {

                return buildCard(

                    File(e.value[i].path));

              },

            ),

          ],

        );

      }).toList(),

    );

  }

  Widget convertSection() {

    return Column(

      children: [

        TabBar(

          controller:
              convertTab,

          tabs: [

            Tab(text: "CONVERT", height: ResponsiveHelper.getButtonHeight(context)),

            Tab(text: "COMPRESS", height: ResponsiveHelper.getButtonHeight(context)),

            Tab(text: "EXPORT", height: ResponsiveHelper.getButtonHeight(context)),

          ],

        ),

        Expanded(

          child:
              TabBarView(

            controller:
                convertTab,

            children: [

              buildGrid(convertFiles),

              buildGrid(compressFiles),

              buildGrid(exportConverted),

            ],

          ),

        ),

      ],

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: selectionMode

            ? Text(
                "${selectedFiles.length} selected")

            : const Text("My Geo Capture"),

        actions: [

          if (selectionMode) ...[

            IconButton(

              icon:
                  const Icon(Icons.share),

              onPressed: () {

                final files =
                    selectedFiles

                        .map((e) =>
                            XFile(e))

                        .toList();

                Share.shareXFiles(files);

              },

            ),

            IconButton(

              icon:
                  const Icon(Icons.delete),

              onPressed: () async {

                for (var f
                    in selectedFiles) {

                  final file =
                      File(f);

                  if (await file.exists()) {

                    await file.delete();

                  }

                }

                selectedFiles.clear();

                selectionMode = false;

                loadFiles();

              },

            ),

            IconButton(

              icon:
                  const Icon(Icons.close),

              onPressed: () {

                setState(() {

                  selectionMode = false;

                  selectedFiles.clear();

                });

              },

            ),

          ]

          else ...[

            IconButton(

              icon: Icon(

                newestFirst

                    ? Icons.arrow_downward

                    : Icons.arrow_upward,

              ),

              onPressed: () {

                setState(() {

                  newestFirst =
                      !newestFirst;

                });

              },

            ),

            IconButton(

              icon:
                  const Icon(Icons.refresh),

              onPressed: loadFiles,

            ),

          ],

        ],

        bottom: TabBar(

          controller: mainTab,

          tabs: [

            Tab(text: "PHOTOS", height: ResponsiveHelper.getButtonHeight(context)),

            Tab(text: "VIDEOS", height: ResponsiveHelper.getButtonHeight(context)),

            Tab(text: "DOCUMENTS", height: ResponsiveHelper.getButtonHeight(context)),

            Tab(text: "CONVERTED", height: ResponsiveHelper.getButtonHeight(context)),

          ],

        ),

      ),

      body: loading

          ? const Center(

              child:
                  CircularProgressIndicator())

          : Column(

              children: [

                Padding(

                  padding:
                      EdgeInsets.all(
                          ResponsiveHelper.scale(context, 10)),

                  child:
                      TextField(

                    controller:
                        searchController,

                    decoration:
                        InputDecoration(

                      hintText:
                          "Search files",

                      prefixIcon:
                          Icon(
                              Icons.search,
                              size: ResponsiveHelper.getIconSize(context)),

                      border:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(
                                ResponsiveHelper.getBorderRadius(context)),

                      ),

                    ),

                  ),

                ),

                Expanded(

                  child:
                      TabBarView(

                    controller:
                        mainTab,

                    children: [

                      buildGrid(
                          photos),

                      buildGrid(
                          videos),

                      buildGrid(
                          docs),

                      convertSection(),

                    ],

                  ),

                ),

              ],

            ),

    );

  }

}