// ignore_for_file: avoid_types_as_parameter_names, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/explorer/explorer_bloc.dart';
import 'package:receiptcamp/logic/blocs/upload/upload_bloc.dart';
import 'package:receiptcamp/logic/cubits/file_edit/file_editing_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/ui/file_navigator/folder/folder_sheet.dart';
import 'package:receiptcamp/presentation/ui/file_navigator/receipt/receipt_sheet.dart';
import 'package:receiptcamp/presentation/ui/file_navigator/upload_sheet.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({Key? key}) : super(key: key);

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
            create: (context) => ExplorerBloc()..add(ExplorerFetchFilesEvent()),
          ),
          BlocProvider<FileEditingCubit>(
            create: (context) => FileEditingCubit(),
          ),
        ],
        child: BlocConsumer<UploadBloc, UploadState>(
          listener: (context, state) {
            switch (state) {
              case UploadReceiptSuccess():
                context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Receipt ${state.receipt.name} added successfully'),
                    duration: const Duration(milliseconds: 2000)));
              case UploadFolderSuccess():
                context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Folder ${state.folder.name} added successfully'),
                    duration: const Duration(milliseconds: 2000)));
              case UploadFailed():
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Failed to save file object'),
                    duration: Duration(milliseconds: 900)));
              default:
                print('Explorer Screen: ${state.toString()}');
                return;
            }
          },
          builder: (context, state) {
            return BlocBuilder<ExplorerBloc, ExplorerState>(
              builder: (context, state) {
                switch (state) {
                  case ExplorerInitialState():
                    return const CircularProgressIndicator();
                  case ExplorerLoadingState():
                    return const CircularProgressIndicator();
                  case ExplorerEmptyFilesState():
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: RefreshIndicator(
                              onRefresh: () async {
                                context
                                    .read<ExplorerBloc>()
                                    .add(ExplorerFetchFilesEvent());
                              },
                              child: const Center(
                                  child: Text('No files/folders to show'))),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: FloatingActionButton.large(
                                onPressed: () {
                                  showUploadOptions(
                                      context, context.read<UploadBloc>());
                                },
                                child: const Icon(Icons.add)),
                          ),
                        ),
                      ],
                    );
                  case ExplorerLoadedSuccessState():
                    return Stack(
                      children: [
                        Align(
                            alignment: Alignment.topCenter,
                            child: RefreshIndicator(
                                onRefresh: () async {
                                  context
                                      .read<ExplorerBloc>()
                                      .add(ExplorerFetchFilesEvent());
                                },
                                child: BlocListener<FileEditingCubit,
                                    FileEditingCubitState>(
                                  listener: (context, state) {
                                    switch (state) {
                                      case FileEditingCubitRenameSuccess():
                                        // reloading list to show new changes
                                        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    '${state.oldName} renamed to ${state.newName}'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitRenameFailure():
                                        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Failed to rename ${state.oldName}'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitMoveSuccess():
                                        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    '${state.oldName} moved to ${state.newName}'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitMoveFailure():
                                        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Failed to move ${state.oldName}'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitDeleteSuccess():
                                        context
                                            .read<ExplorerBloc>()
                                            .add(ExplorerFetchFilesEvent());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Deleted ${state.deletedName}'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitDeleteFailure():
                                        context.read<ExplorerBloc>().add(ExplorerFetchFilesEvent());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Failed to delete ${state.deletedName}'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitShareSuccess():
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Shared ${state.receiptName}'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitShareFailure():
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Failed to share ${state.receiptName}'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitSaveImageSuccess():
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Saved ${state.receiptName} to camera roll'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      case FileEditingCubitSaveImageFailure():
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Failed to save ${state.receiptName} to camera roll'),
                                                duration: const Duration(
                                                    milliseconds: 2000)));
                                      default:
                                        return;
                                    }
                                  },
                                  child: ListView.builder(
                                    itemCount: state.files.length,
                                    itemBuilder: (context, index) {
                                      final file = state.files[index];
                                      if (file is Receipt) {
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
                                                  context,
                                                  context
                                                      .read<FileEditingCubit>(),
                                                  file);
                                            },
                                          ),
                                          title: Text(file.name.split('.').first),
                                          // can return some properties specific to Receipt
                                        );
                                      } else if (file is Folder) {
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
                                                  context,
                                                  context
                                                      .read<FileEditingCubit>(),
                                                  file);
                                            },
                                          ),
                                          title: Text(file.name.split('.').first),
                                          // can return some properties specific to Receipt
                                        );
                                      } else {
                                        return const ListTile(
                                          title: Text('Unknown file'),
                                        );
                                      }
                                    },
                                  ),
                                ))),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: FloatingActionButton.large(
                                onPressed: () {
                                  showUploadOptions(
                                      context, context.read<UploadBloc>());
                                },
                                child: const Icon(Icons.add)),
                          ),
                        ),
                      ],
                    );
                  default:
                    print('Explorer Screen: ${state.toString()}');
                    return Container();
                }
              },
            );
          },
        ));
  }
}
