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
import 'package:receiptcamp/presentation/ui/file_explorer/upload_sheet.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  List<int> items = List.generate(16, (i) => i);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UploadBloc>(
            create: (context) => UploadBloc()..add(UploadInitialEvent()),
          ),
          BlocProvider<ExplorerBloc>(
            create: (context) => ExplorerBloc()..add(ExplorerFetchFilesEvent(folderId: 'a1')),
          ),
          BlocProvider<FileEditingCubit>(
            create: (context) => FileEditingCubit(),
          ),
      ],
      child: ExplorerView(items: items),
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
  const ExplorerView({
    super.key,
    required this.items,
  });

  final List<int> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FolderName(),
          const SizedBox(
            height: 5.0,
          ),
          BackButton(),
          Expanded(
            child: RefreshableFolderView(items: items),
          )
        ],
      ),
      floatingActionButton: UploadButton(),
    );
  }
}

class FolderName extends StatelessWidget {
  const FolderName({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: const Text(
        'Folder Name',
        style: TextStyle(
          fontSize: 34.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class BackButton extends StatelessWidget {
  const BackButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {}, 
      icon: Icon(Icons.arrow_back));
  }
}

class RefreshableFolderView extends StatelessWidget {
  const RefreshableFolderView({
    super.key,
    required this.items,
  });

  final List<int> items;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () async {
          return Future.delayed(Duration(seconds: 1));
        },
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return FolderListTile(); // or ReceiptListTile()
          },
        ));
  }
}

class FolderListTile extends StatelessWidget {
  const FolderListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
            leading: const Icon(Icons.folder),
            trailing: IconButton(
              icon: Icon(
                Icons.more,
                size: 20.0,
                color: Colors.brown[900],
              ),
              onPressed: () {
                // showFolderOptions(
                //     context,
                //     context
                //         .read<FileEditingCubit>(),
                //     folder);
              },
            ),
            title: Text('Folder name'), // folder.name
            // can return some properties specific to Folder
          );
  }
}

class ReceiptListTile extends StatelessWidget {
  const ReceiptListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
            leading: const Icon(Icons.receipt),
            trailing: IconButton(
              icon: Icon(
                Icons.more,
                size: 20.0,
                color: Colors.brown[900],
              ),
              onPressed: () {
                // showReceiptOptions(
                //     context,
                //     context
                //         .read<FileEditingCubit>(),
                //     receipt);
              },
            ),
            title: Text('Receipt name w/o file ending') // receipt.name.split('.').first
            // can return some properties specific to Receipt
          );
  }
}

class UploadButton extends StatelessWidget {
  const UploadButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showUploadOptions(context, context.read<UploadBloc>());
      },
      child: const Icon(Icons.add),
    );
  }
}
