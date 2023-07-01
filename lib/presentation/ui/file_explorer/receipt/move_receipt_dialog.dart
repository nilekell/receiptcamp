import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/logic/cubits/file_edit/file_editing_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';

Future<void> showMoveReceiptDialog(BuildContext context,
    FileEditingCubit fileEditingCubit, Receipt receipt) async {
  return await showDialog(
      context: context,
      builder: (moveReceiptDialogContext) {
        return BlocProvider.value(
            value: fileEditingCubit,
            child: MoveReceiptDialog(receipt: receipt));
      });
}

class MoveReceiptDialog extends StatefulWidget {
  final Receipt receipt;

  const MoveReceiptDialog({super.key, required this.receipt});

  @override
  State<MoveReceiptDialog> createState() => _MoveReceiptDialogState();
}

class _MoveReceiptDialogState extends State<MoveReceiptDialog> {
  List<Folder> folders = [];
  Folder? selectedFolder;

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  Future<void> loadFolders() async {
    folders = await DatabaseRepository.instance.getFoldersExceptSpecified([widget.receipt.parentId]);
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
      content: SingleChildScrollView(
        child: Center(
          child: DropdownButton<Folder>(
            value: selectedFolder,
            items: folders.map<DropdownMenuItem<Folder>>((Folder folder) {
              return DropdownMenuItem<Folder>(
                  value: folder, child: Text(folder.name));
            }).toList(),
            onChanged: (Folder? value) {
              setState(() {
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
              Navigator.of(context).pop();
            }),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<FileEditingCubit>().moveReceipt(widget.receipt, selectedFolder!.id);
          },
          child: const Text('Move'),
        ),
      ],
    );
  }
}
