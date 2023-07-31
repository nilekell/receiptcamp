import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/logic/cubits/file_system/file_system_cubit.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/folder/folder_sheet.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/receipt/receipt_sheet.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/snackbar_utility.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/upload_sheet.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  late ScrollController _scrollController;
  bool _showUploadButton = true;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    context.read<FileSystemCubit>().initializeFileSystemCubit();
    super.initState();
  }

  _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // Hide the upload button when user scroll down
      if (_showUploadButton) setState(() => _showUploadButton = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      // Show the upload button when user scroll up or stop scrolling
      if (!_showUploadButton) setState(() => _showUploadButton = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FileSystemCubit, FileSystemCubitState>(
          builder: ((context, state) {
        switch (state) {
          case FileSystemCubitInitial() || FileSystemCubitLoading():
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: CircularProgressIndicator()),
              ],
            );
          case FileSystemCubitFolderInformationSuccess():
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                state.folder.id != rootFolderId
                    ? FolderName(
                        name: state.folder.name,
                      )
                    : const FolderName(
                        name: 'All Receipts',
                      ),
                const Divider(thickness: 2),
                state.folder.id != rootFolderId
                    ? BackButton(
                        previousFolderId: state.folder.parentId,
                        currentFolderId: state.folder.id,
                      )
                    : Container(),
                Expanded(
                  child: Stack(
                    children: [
                      BlocListener<FileSystemCubit, FileSystemCubitState>(
                      listener: (context, state) {
                        switch (state) {
                          case FileSystemCubitFolderInformationSuccess():
                            print(
                                'RefreshableFolderView: fetchFiles for ${state.folder.name}');
                            context
                                .read<FolderViewCubit>()
                                .fetchFiles(state.folder.id);
                          default:
                            print(
                                'RefreshableFolderViewState: ${state.toString()}');
                        }
                      },
                      child: RefreshableFolderView(scrollController: _scrollController),
                    ),
                  if (_showUploadButton) 
                    Positioned(
                      right: 28,
                      bottom: 28,
                      child: UploadButton(currentFolder: state.folder),
                    )
                  ],
                  ),
                ),
              ],
            );
          case FileSystemCubitError():
            print(
                'FileSystemCubitError with state: ${state.runtimeType.toString()}');
            return const Center(
              child: Text('Error State'),
            );
          default:
            print(
                'FileExplorer BlocBuilder - Unaccounted for state: ${state.runtimeType.toString()}');
            return Container();
        }
      })),
    );
  }
}

class FolderName extends StatelessWidget {
  final String name;
  const FolderName({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 34.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class BackButton extends StatelessWidget {
  final String previousFolderId;
  final String currentFolderId;

  const BackButton(
      {super.key,
      required this.previousFolderId,
      required this.currentFolderId});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          context.read<FileSystemCubit>().navigateBack(previousFolderId);
        },
        icon: const Icon(Icons.arrow_back));
  }
}

class RefreshableFolderView extends StatefulWidget {
  final ScrollController scrollController;

  const RefreshableFolderView({super.key, required this.scrollController});

  @override
  State<RefreshableFolderView> createState() => _RefreshableFolderViewState();
}

class _RefreshableFolderViewState extends State<RefreshableFolderView> {
  @override
  void initState() {
    print('RefreshableFolderView instantiated');
    context.read<FolderViewCubit>().initFolderView(rootFolderId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FolderViewCubit, FolderViewState>(
      listenWhen: (previous, current) => current is FolderViewActionState,
      listener: (context, state) {
        SnackBarUtility.showSnackBar(context, state);
      },
      builder: (context, state) {
        switch (state) {
          case FolderViewInitial() || FolderViewLoading():
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: CircularProgressIndicator()),
              ],
            );
          case FolderViewLoadedSuccess():
            print(
                'RefreshableFolderView built with folder: ${state.folder.name}');
            return RefreshIndicator(
              onRefresh: () async {
                print('refreshing folder ${state.folder.name}');
                context.read<FolderViewCubit>().fetchFiles(state.folder.id);
              },
              child: state.files.isNotEmpty
                  ? ListView.builder(
                    controller: widget.scrollController,
                      itemCount: state.files.length,
                      itemBuilder: (context, index) {
                        var item = state.files[index];
                        if (item is Receipt) {
                          return SizedBox(
                              height: 60,
                              child: ReceiptListTile(receipt: item));
                        } else if (item is Folder) {
                          return SizedBox(
                              height: 60, child: FolderListTile(folder: item));
                        } else {
                          return const ListTile(
                              title: Text('Unknown file type'));
                        }
                      },
                    )
                  : const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 20),
                          Text(
                            "To add receipts, tap the upload button below",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            );
          case FolderViewError():
            print(
                'FolderViewCubitError with state: ${state.runtimeType.toString()}');
            return const Center(
              child: Text('Error State'),
            );
          default:
            print(
                'RefreshableFolderView BlocBuilder - Unaccounted for state: ${state.runtimeType.toString()}');
            return Container();
        }
      },
    );
  }
}

class FolderListTile extends StatelessWidget {
  final Folder folder;
  final String displayName;
  final String displayDate;

  FolderListTile({Key? key, required this.folder})
      : displayName = folder.name.length > 25
            ? "${folder.name.substring(0, 25)}..."
            : folder.name,
        displayDate = Utility.formatDisplayDateFromDateTime(
            Utility.formatDateTimeFromUnixTimestamp(folder.lastModified)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      subtitle: Text('Modified $displayDate'),
      leading: const Icon(
        Icons.folder,
        size: 35,
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.more_horiz,
        ),
        onPressed: () {
          showFolderOptions(context, context.read<FolderViewCubit>(), folder);
        },
      ),
      onTap: () {
        context.read<FileSystemCubit>().selectFolder(folder.id);
      },
      title: Text(displayName),
    );
  }
}

class ReceiptListTile extends StatelessWidget {
  final Receipt receipt;
  final String displayName;
  final String displayDate;

  ReceiptListTile({Key? key, required this.receipt})
      : displayName = receipt.name.length > 25
            ? "${receipt.name.substring(0, 25)}..."
            : receipt.name,
        displayDate = Utility.formatDisplayDateFromDateTime(
            Utility.formatDateTimeFromUnixTimestamp(receipt.lastModified)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: ClipRRect(
          // square image corners
          borderRadius: const BorderRadius.all(Radius.zero),
          child: Image.file(
            File(receipt.localPath),
            fit: BoxFit.cover,
          ),
        ),
        subtitle: Text('Created $displayDate'),
        trailing: IconButton(
          icon: const Icon(
            Icons.more_horiz,
          ),
          onPressed: () {
            showReceiptOptions(
                context, context.read<FolderViewCubit>(), receipt);
          },
        ),
        onTap: () {
          final imageProvider = Image.file(File(receipt.localPath)).image;
          showImageViewer(context, imageProvider);
        },
        title: Text(displayName));
  }
}

class UploadButton extends StatelessWidget {
  final Folder currentFolder;

  const UploadButton({super.key, required this.currentFolder});

  @override
  Widget build(BuildContext context) {
    print('UploadButton built with folder: ${currentFolder.name}');
    return FloatingActionButton.large(
      onPressed: () {
        showUploadOptions(
            context, context.read<FolderViewCubit>(), currentFolder);
      },
      child: const Icon(Icons.add),
    );
  }
}
