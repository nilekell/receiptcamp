import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/upload/upload_bloc.dart';
import 'package:receiptcamp/models/folder.dart';

Future<void> showCreateFolderDialog(
    BuildContext context, UploadBloc uploadBloc,  Folder currentFolder) async {
  return await showDialog(
      context: context,
      builder: (createFolderDialogContext) {
        return BlocProvider.value(
          value: uploadBloc,
          child: FolderDialog(currentFolder: currentFolder),
        );
      });
}

class FolderDialog extends StatefulWidget {
  final Folder currentFolder;

  const FolderDialog({super.key,
  required this.currentFolder});

  @override
  State<FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<FolderDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController textEditingController = TextEditingController();
  bool isEnabled = false;

  @override
  void initState() {
    context.read<UploadBloc>();
    isEnabled = textEditingController.text.isNotEmpty;
    textEditingController.addListener(_textPresenceListener);
    super.initState();
  }

  void _textPresenceListener() {
    if (isEnabled != textEditingController.text.isNotEmpty) {
      setState(() {
        // disabling/enabling create button when text is empty/present
        isEnabled = textEditingController.text.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: textEditingController,
                decoration:
                    const InputDecoration(hintText: "Enter folder name"),
              ),
            ],
          )),
      title: const Text('New Folder'),
      actions: <Widget>[
        TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              // closing folder dialog
              Navigator.of(context).pop();
            }),
        TextButton(
          onPressed: isEnabled
              ? () {
                  context.read<UploadBloc>().add(FolderCreateEvent(
                      name: textEditingController.value.text, parentId: widget.currentFolder.id));
                  // closing folder dialog
                  Navigator.of(context).pop();
                }
              // only enabling button when isEnabled is true
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    textEditingController.removeListener(_textPresenceListener);
    textEditingController.dispose();
    super.dispose();
  }
}
