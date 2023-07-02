import 'package:flutter/material.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();  
    // - FolderName
    // - BackButton
    // - RefreshableFolderView
    //     - RefreshIndicator
    //     - ListView
    //         - ReceiptTile
    //         - FolderTile
    //     - UploadButton (Should float above list tile)
  }
}