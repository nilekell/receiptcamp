import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/cubits/file_edit/file_editing_cubit.dart';
import 'package:receiptcamp/models/receipt.dart';

Future<void> showDeleteReceiptDialog(BuildContext context,
    FileEditingCubit fileEditingCubit, Receipt receipt) async {
  return await showDialog(
    context: context,
    builder: (deleteReceiptDialogContext) {
      return BlocProvider.value(
        value: fileEditingCubit,
        child: DeleteReceiptDialog(receipt: receipt)
      );
    },
  );
}

class DeleteReceiptDialog extends StatelessWidget {
  final Receipt receipt;

  const DeleteReceiptDialog({
    super.key, required this.receipt
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Forever'),
      content: Text('${receipt.name} will be deleted forever.'),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Delete'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
