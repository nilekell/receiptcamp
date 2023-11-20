import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/screens/image_view.dart';
import 'package:receiptcamp/presentation/screens/select_multiple_screen.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/receipt/receipt_sheet.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';

class ReceiptListTile extends StatelessWidget {
  final Receipt receipt;
  final String displayName;
  final String displayDate;
  final String displaySize;
  final String price;
  final bool withSize;
  // Optional withSize parameter used to determine whether to show displaySize in subtitle & ReceiptListTileVisual
  final String draggableName;

  ReceiptListTile({Key? key, required this.receipt, this.withSize = false, this.price = ''})
      // displayName is the file name without the file extension and is cut off when the receipt name
      // is > 25 chars or would require 2 lines to be shown completely
      : displayName = receipt.name.length > 25
            ? "${receipt.name.substring(0, 25)}..."
            : receipt.name.split('.').first,
        draggableName = receipt.name.length > 10
            ? "${receipt.name.substring(0, 10)}..."
            : receipt.name,
        displayDate = Utility.formatDisplayDateFromDateTime(
            Utility.formatDateTimeFromUnixTimestamp(receipt.lastModified)),
        displaySize = Utility.bytesToSizeString(receipt.storageSize),
        super(key: key);

  final TextStyle displayNameStyle = const TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: Color(primaryGrey));
  final TextStyle displayDateStyle =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  String calculateSubtitle(String price, bool withSize, String displayDate) {
    if (withSize == true) {
      return displaySize;
    } else if (price != '') {
      return price;
    } else {
      return 'Modified $displayDate';
    }
  }

  final ValueNotifier<bool> _showReceiptOptionsButton = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: GestureDetector(
            onLongPress: () {
              Navigator.of(context).push(SlidingSelectMultipleTransitionRoute(
                  item: ListItem(item: receipt)));
            },
            child: ListTile(
                leading: Draggable<Receipt>(
                  onDragStarted: () {
                    _showReceiptOptionsButton.value = false;
                  },
                  onDragEnd: (details) {
                    _showReceiptOptionsButton.value = true;
                  },
                  maxSimultaneousDrags: 1,
                  dragAnchorStrategy: (draggable, context, position) {
                    return const Offset(50, 50);
                  },
                  data: receipt,
                  childWhenDragging: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                    // adjusting position of visual list tile so it matches receipt list tile position
                    child: Transform.translate(
                      offset: const Offset(-26, -16),
                      child: ReceiptListTileVisual(
                        receipt: receipt,
                        subtitle: calculateSubtitle(price, withSize, displayDate),
                      ),
                    ),
                  ),
                  feedback: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Opacity(
                          opacity: 0.7,
                          child: SizedBox(
                            height: 100,
                            width: 100,
                            child: ClipRRect(
                              // square image corners
                              borderRadius: const BorderRadius.all(Radius.zero),
                              child: Image.file(
                                File(receipt.localPath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, 10),
                          child: Text(
                            draggableName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: ClipRRect(
                      // square image corners
                      borderRadius: const BorderRadius.all(Radius.zero),
                      child: Image.file(
                        File(receipt.localPath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                subtitle: Text(
                  calculateSubtitle(price, withSize, displayDate),
                  style: displayDateStyle,
                ),
                trailing: ValueListenableBuilder(
                  valueListenable: _showReceiptOptionsButton,
                  builder: (context, value, child) {
                    return Visibility(
                      visible: _showReceiptOptionsButton.value,
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(primaryGrey),
                          size: 30,
                        ),
                        onPressed: () {
                          showReceiptOptions(
                              context, context.read<FolderViewCubit>(), receipt);
                        },
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.of(context)
                      .push(SlidingImageTransitionRoute(receipt: receipt));
                },
                title: Text(displayName,
                    style: displayNameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          )),
    );
  }
}

// placeholder widget while draggable is active
class ReceiptListTileVisual extends StatelessWidget {
  final Receipt receipt;
  final String displayName;
  final String subtitle;

  ReceiptListTileVisual(
      {Key? key, required this.receipt, required this.subtitle})
      // displayName is the file name without the file extension and is cut off when the receipt name
      // is > 25 chars or would require 2 lines to be shown completely
      : displayName = receipt.name.length > 25
            ? "${receipt.name.substring(0, 25)}...".split('.').first
            : receipt.name.split('.').first,
        super(key: key);

  final TextStyle displayNameStyle = const TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: Color(primaryGrey));

  final TextStyle subTextStyle =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SizedBox(
            width: 300,
            child: ListTile(
                leading: SizedBox(
                  height: 50,
                  width: 50,
                  child: ClipRRect(
                    // square image corners
                    borderRadius: const BorderRadius.all(Radius.zero),
                    child: Image.file(
                      File(receipt.localPath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                subtitle: Text(
                  subtitle, // Ternary operator to decide text
                  style: subTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                title: Text(displayName,
                    style: displayNameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          )),
    );
  }
}
