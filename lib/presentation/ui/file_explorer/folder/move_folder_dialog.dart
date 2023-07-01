import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/logic/cubits/file_edit/file_editing_cubit.dart';
import 'package:receiptcamp/models/folder.dart';

Future<void> showMoveFolderDialog(BuildContext context,
    FileEditingCubit fileEditingCubit, Folder thisFolder) async {
  return await showDialog(
      context: context,
      builder: (moveFolderDialogContext) {
        return BlocProvider.value(
            value: fileEditingCubit,
            child: MoveFolderDialog(thisFolder: thisFolder));
      });
}

class MoveFolderDialog extends StatefulWidget {
  final Folder thisFolder;

  const MoveFolderDialog({super.key, required this.thisFolder});

  @override
  State<MoveFolderDialog> createState() => _MoveFolderDialogState();
}

class _MoveFolderDialogState extends State<MoveFolderDialog> {
  List<Folder> folders = [];
  Folder? selectedFolder;
  bool currentFolderIsSelected = false;

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  // this method is only called once, when the widget is inserted into them widget tree
  Future<void> loadFolders() async {
    // getting all folders except for the folder to be moved and its parent folder
    // this ensure we don't show any folders that are illogical to move to in the dropdown menu
    folders = await DatabaseRepository.instance
        .getFoldersExceptSpecified([widget.thisFolder.id, widget.thisFolder.parentId]);
    if (folders.isNotEmpty) {
      setState(() {
        selectedFolder = folders[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Move To Folder'),
      // single child scroll view prevents dropdown menu overflow
      content: SingleChildScrollView(
        child: Center(
          child: DropdownButton<Folder>(
            value: selectedFolder,
            // mapping the list of folders to a list of DropdownMenuItem widgets
            items: folders.map<DropdownMenuItem<Folder>>((Folder folder) {
              return DropdownMenuItem<Folder>(
                  value: folder, child: Text(folder.name));
            }).toList(), // converting the Iterable returned from .map() back to a list
            // onChanged is called when the user selects a new option from the dropdown menu
            onChanged: (Folder? value) {
              setState(() {
                // updating the user selected value to be stored as the selectedFolder
                selectedFolder = value;
              });
            },
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              // closing folder dialog
              Navigator.of(context).pop();
            }),
        TextButton(
          onPressed: () {
            // closing folder dialog
            Navigator.of(context).pop();
            context.read<FileEditingCubit>().moveFolder(widget.thisFolder, selectedFolder!.id);
          },
          child: const Text('Move'),
        ),
      ],
    );
  }
}
