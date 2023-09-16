import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';

Future<void> showRenameReceiptDialog(BuildContext context,
    FolderViewCubit folderViewCubit, Receipt receipt) async {
  return await showDialog(
      context: context,
      builder: (renameReceiptDialogContext) {
        return BlocProvider.value(
          value: folderViewCubit,
          child: RenameReceiptDialog(receipt: receipt),
        );
      });
}

class RenameReceiptDialog extends StatefulWidget {
  final Receipt receipt;

  const RenameReceiptDialog({super.key, required this.receipt});

  @override
  State<RenameReceiptDialog> createState() => _RenameReceiptDialogState();
}

class _RenameReceiptDialogState extends State<RenameReceiptDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isEnabled = false;

  @override
  void initState() {
    context.read<FolderViewCubit>();
    // setting initial text shown in form to name of receipt without extension
    String nameWithoutExtension = widget.receipt.name.split('.').first;
    textEditingController.text = nameWithoutExtension;
    textEditingController.addListener(_textPresenceListener);
    // highlighting initial text after first frame is rendered so the Focus can be requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
      textEditingController.selection = TextSelection(
          baseOffset: 0, extentOffset: textEditingController.text.length);
    });

    super.initState();
  }

  void _textPresenceListener() {
    setState(() {
      // disabling create button when text is empty & text value != receipt's current name
      isEnabled = textEditingController.text.isNotEmpty &&
          textEditingController.value.text.trim() !=
              widget.receipt.name.split('.').first;
    });
  }

  final ButtonStyle textButtonStyle =
      TextButton.styleFrom(foregroundColor: Colors.white);

  final TextStyle actionButtonTextStyle = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(40.0))),
      backgroundColor: const Color(primaryDarkBlue),
      content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  style: const TextStyle(color: Colors.white),
                  focusNode: _focusNode,
                  autofocus: true,
                  controller: textEditingController,
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: "Enter new Receipt name",
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              Colors.white), // <-- Set color for normal state
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              Colors.white), // <-- Set color for focused state
                    ),
                  ),
                  // This ensures that any input that doesn't match the filename format is ignored.
                  inputFormatters: [
                    // Regex disallows special characters like ., /, \, $, etc.
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[^./\\$?*|:"><]*'))
                  ]),
            ],
          )),
      title: const Text('Rename Receipt',
          textAlign: TextAlign.left,
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      actions: <Widget>[
        TextButton(
            style: textButtonStyle,
            child: Text(
              'Cancel',
              style: actionButtonTextStyle,
            ),
            onPressed: () {
              // closing dialog
              Navigator.of(context).pop();
            }),
        TextButton(
          style: textButtonStyle,
          onPressed: isEnabled
              ? () {
                  context.read<FolderViewCubit>().renameReceipt(
                      widget.receipt, textEditingController.value.text);
                  // closing folder dialog
                  Navigator.of(context).pop();
                }
              // only enabling button when isEnabled is true
              : null,
          child: Text('Rename', style: actionButtonTextStyle),
        ),
      ],
    );
  }

  @override
  void dispose() {
    textEditingController.removeListener(_textPresenceListener);
    textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
