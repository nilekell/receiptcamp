import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/logic/cubits/file_explorer/file_explorer_cubit.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/screens/select_multiple_screen.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/folder/folder_sheet.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';


class FolderListTile extends StatelessWidget {
  final Folder folder;
  final String displayName;
  final String displayDate;
  final String displaySize;
  final String displayPrice;
  final String draggableName;
  final String? price;
  final int? storageSize;
   // Optional storageSize parameter used to determine whether to show displaySize in subtitle & FolderListTileVisual

  FolderListTile({Key? key, required this.folder, this.storageSize, this.price})
      : displayName = folder.name.length > 25
            ? "${folder.name.substring(0, 25)}..."
            : folder.name,
        draggableName = folder.name.length > 10
            ? "${folder.name.substring(0, 10)}..."
            : folder.name,
        displayDate = Utility.formatDisplayDateFromDateTime(
            Utility.formatDateTimeFromUnixTimestamp(folder.lastModified)),
        displaySize =
            storageSize != null ? Utility.bytesToSizeString(storageSize) : '',
        displayPrice = price ?? '',
        super(key: key);

  final TextStyle displayNameStyle = const TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: Color(primaryGrey));
  final TextStyle displayDateStyle =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

    static String calculateSubtitle(
      int? storageSize, String? price, String displayDate) {
    if (storageSize != null) {
      return Utility.bytesToSizeString(storageSize);
    } else if (price != null && price != '') {
      return price;
    } else {
      return 'Modified $displayDate';
    }
  }

  final ValueNotifier<bool> _showFolderOptionsButton = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAccept: (data) {
        if (data is Receipt) {
          return true;
        } else if (data is Folder) {
          return data.id != folder.id;
        } else {
          return false;
        }
      },
      onAccept: (data) {
        if (data is Receipt) {
          context.read<FolderViewCubit>().moveReceipt(data, folder.id);
          return;
        } else if (data is Folder) {
          context.read<FolderViewCubit>().moveFolder(data, folder.id);
          return;
        }
      },
      builder: (context, candidateData, rejectedData) {
        return SizedBox(
          height: 60,
          child: Container(
            color: candidateData.isNotEmpty ? Colors.grey : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(
                onLongPress: () {
                  Navigator.of(context).push(SlidingSelectMultipleTransitionRoute(
                      item: ListItem(item: folder)));
                },
                child: ListTile(
                  subtitle: Text(
                    calculateSubtitle(storageSize, price, displayDate),
                    style: displayDateStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // only the icon is draggable
                  leading: Draggable<Folder>(
                    // hiding/showing options button when visual list tile is shown
                    onDragStarted: () {
                      _showFolderOptionsButton.value = false;
                    },
                    onDragEnd: (details) {
                      _showFolderOptionsButton.value = true;
                    },
                    maxSimultaneousDrags: 1,
                    dragAnchorStrategy: (draggable, context, position) {
                      return const Offset(50, 50);
                    },
                    data: folder,
                    childWhenDragging: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.srcIn,
                        ),
                        // adjusting position of visual list tile so it matches folder list tile posiiton
                        child: Transform.translate(
                            offset: const Offset(-26, -8),
                            child: FolderListTileVisual(
                                folder: folder,
                                subtitle: calculateSubtitle(
                                    storageSize, price, displayDate)))),
                    feedback: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Opacity(
                            opacity: 0.7,
                    child: Icon(
                      Icons.folder,
                      size: 100,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Text(
                      draggableName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                              ],
                            ),
                          ),
                    child: const Icon(
                      Icons.folder,
                      size: 50,
                    ),
                  ),
                  trailing: ValueListenableBuilder(
                    valueListenable: _showFolderOptionsButton,
                    builder: (context, value, child) {
                      return Visibility(
                        visible: _showFolderOptionsButton.value,
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(primaryGrey),
                          size: 30,
                        ),
                        onPressed: () {
                          showFolderOptions(
                              context, context.read<FolderViewCubit>(), folder);
                        },
                      ),
                    );
                    },
                  ),
                  onTap: () {
                    context.read<FileExplorerCubit>().selectFolder(folder.id);
                  },
                  title: Text(
                    displayName,
                    style: displayNameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// placeholder widget while draggable is active
class FolderListTileVisual extends StatelessWidget {
  final Folder folder;
  final String displayName;
  final String subtitle;

  final TextStyle displayNameStyle = const TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: Color(primaryGrey));
  
  final TextStyle subTextStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  FolderListTileVisual({Key? key, required this.folder, required this.subtitle})
      : displayName = folder.name.length > 25

            ? "${folder.name.substring(0, 25)}..."
            : folder.name,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: SizedBox(
          width: 300,
          child: ListTile(
            subtitle: Text(
              subtitle,
              style: subTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: const Icon(
              Icons.folder,
              size: 50,
            ),
            title: Text(
              displayName,
              style: displayNameStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
