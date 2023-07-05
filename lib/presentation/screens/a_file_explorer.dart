// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, unused_import
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/explorer/explorer_bloc.dart';
import 'package:receiptcamp/logic/blocs/upload/upload_bloc.dart';
import 'package:receiptcamp/logic/cubits/file_edit/file_editing_cubit.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/folder/folder_sheet.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/receipt/receipt_sheet.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/snackbars/snackbar_utility.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/upload_sheet.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  @override
  void initState() {
    super.initState();
    context.read<ExplorerBloc>().add(ExplorerInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UploadBloc>(
          create: (context) => UploadBloc()..add(UploadInitialEvent()),
        ),
        BlocProvider<ExplorerBloc>(
          create: (context) =>
              ExplorerBloc()..add(ExplorerFetchFilesEvent(folderId: 'a1')),
        ),
        BlocProvider<FileEditingCubit>(
          create: (context) => FileEditingCubit(),
        ),
      ],
      child: BlocBuilder<ExplorerBloc, ExplorerState>(
        builder: (context, state) {
          switch (state.runtimeType) {
            case ExplorerLoadedSuccessState:
              ExplorerLoadedSuccessState currentState =
                  state as ExplorerLoadedSuccessState;
              return ExplorerView(
                items: currentState.files,
                folder: currentState.folder,
                previousFolderId: currentState.folder.parentId,
              );
            default:
              print(state.runtimeType.toString());
              return CircularProgressIndicator();
          }
        },
      ),
      // ExplorerView
      // - FolderName
      // - BackButton
      // - RefreshableFolderView
      //     - RefreshIndicator
      //     - ListView
      //         - ReceiptTile
      //         - FolderTile
      //     - UploadButton
    );
  }
}

class ExplorerView extends StatelessWidget {
  const ExplorerView(
      {super.key,
      required this.items,
      required this.folder,
      required this.previousFolderId});

  final List<dynamic> items;
  final Folder folder;
  final String previousFolderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          folder.id != 'a1'
              ? FolderName(
                  name: folder.name,
                )
              : FolderName(
                  name: 'All Receipts',
                ),
          const SizedBox(
            height: 5.0,
          ),
          folder.id != 'a1'
              ? BackButton(
                  previousFolderId: previousFolderId,
                  currentFolderId: folder.id,
                )
              : Container(),
          Expanded(
            child: RefreshableFolderView(folderId: folder.id, items: items),
          )
        ],
      ),
      floatingActionButton: UploadButton(currentFolder: folder),
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
        style: TextStyle(
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
          context.read<ExplorerBloc>().add(ExplorerGoBackEvent(
              currentFolderId: currentFolderId,
              previousFolderId: previousFolderId));
        },
        icon: Icon(Icons.arrow_back));
  }
}

class RefreshableFolderView extends StatelessWidget {
  const RefreshableFolderView(
      {super.key, required this.items, required this.folderId});

  final List<dynamic> items;
  final String folderId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadBloc, UploadState>(
      listener: (context, state) {
        SnackBarUtility.showUploadSnackBar(context, state);
      },
      builder: (context, state) {
        return BlocBuilder<UploadBloc, UploadState>(
          builder: (context, state) {
            return RefreshIndicator(
                onRefresh: () async {
                  // figure out how to only rebuild the listview with a refresh
                  context
                      .read<ExplorerBloc>()
                      .add(ExplorerFetchFilesEvent(folderId: folderId));
                },
                child: items.isNotEmpty
                    ? ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          var item = items[index];
                          if (item is Receipt) {
                            return ReceiptListTile(receipt: item);
                          } else if (item is Folder) {
                            return FolderListTile(folder: item);
                          }
                          return null;
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.all(100.0),
                        child: Text('No receipts/folders to show'),
                      ));
          },
        );
      },
    );
  }
}

class FolderListTile extends StatelessWidget {
  final Folder folder;

  const FolderListTile({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FileEditingCubit, FileEditingCubitState>(
      listener: (context, state) {
        SnackBarUtility.showFileEditSnackBar(context, state);
      },
      builder: (context, state) {
        return ListTile(
              leading: const Icon(Icons.folder),
              trailing: IconButton(
                icon: Icon(
                  Icons.more,
                  size: 20.0,
                  color: Colors.brown[900],
                ),
                onPressed: () {
                  showFolderOptions(
                      context, context.read<FileEditingCubit>(), folder);
                },
              ),
              onTap: () {
                context.read<ExplorerBloc>().add(ExplorerChangeFolderEvent(
                    currentFolderId: folder.parentId, nextFolderId: folder.id));
              },
              title: Text(folder.name),
            );
          },
        );
  }
}

class ReceiptListTile extends StatelessWidget {
  final Receipt receipt;

  const ReceiptListTile({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FileEditingCubit, FileEditingCubitState>(
      listener: (context, state) {
        SnackBarUtility.showFileEditSnackBar(context, state);
      },
      builder: (context, state) {
        return BlocBuilder<FileEditingCubit, FileEditingCubitState>(
          builder: (context, state) {
            return ListTile(
                leading: const Icon(Icons.receipt),
                trailing: IconButton(
                  icon: Icon(
                    Icons.more,
                    size: 20.0,
                    color: Colors.brown[900],
                  ),
                  onPressed: () {
                    showReceiptOptions(
                        context, context.read<FileEditingCubit>(), receipt);
                  },
                ),
                onTap: () {
                  // show receipt preview
                },
                title: Text(receipt.name.split('.').first));
          },
        );
      },
    );
  }
}

class UploadButton extends StatelessWidget {
  final Folder currentFolder;

  const UploadButton({super.key, required this.currentFolder});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showUploadOptions(context, context.read<UploadBloc>(), currentFolder);
      },
      child: const Icon(Icons.add),
    );
  }
}
