// defining a custom route class to animate transition
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, unused_element, prefer_final_fields, unused_field, must_be_immutable
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/utils/utilities.dart';
import 'package:receiptcamp/logic/cubits/file_explorer/file_explorer_cubit.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/logic/cubits/select_multple/select_multiple_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/ui/select_multiple/multi_delete_dialog.dart';
import 'package:receiptcamp/presentation/ui/select_multiple/multi_move_dialog.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

class SlidingSelectMultipleTransitionRoute extends PageRouteBuilder {
  SlidingSelectMultipleTransitionRoute({required ListItem item})
      : super(
          opaque: false,
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return Dismissible(
              onDismissed: (direction) {
                Navigator.of(context).pop();
              },
              key: UniqueKey(),
              direction: DismissDirection.down,
              child: SelectMultipleView(
                initiallySelectedItem: item,
              ),
            );
          },
          transitionsBuilder: (BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;

            const curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: BlocProvider(
                  create: (BuildContext context) =>
                      SelectMultipleCubit(context.read<FolderViewCubit>(), context.read<FileExplorerCubit>())..init(item),
                  child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class ListItem {
  final String id;
  final Object item;

  ListItem({required this.item}) :
  id = Utility.generateUid();
}

class SelectMultipleView extends StatefulWidget {
  const SelectMultipleView({Key? key, required this.initiallySelectedItem})
      : super(key: key);

  final Object initiallySelectedItem;

  @override
  State<SelectMultipleView> createState() =>
      _SelectMultipleViewState();
}

class _SelectMultipleViewState extends State<SelectMultipleView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  List<ListItem> allItems = <ListItem>[];

  ValueNotifier<List<ListItem>> currentlySelectedListItemsNotifier = ValueNotifier<List<ListItem>>([]);
  ValueNotifier<bool> allSelectedNotifier = ValueNotifier<bool>(false);


  ValueNotifier<bool> _moveActionEnabled = ValueNotifier<bool>(true);
  ValueNotifier<bool> _deleteActionEnabled = ValueNotifier<bool>(true);

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    allSelectedNotifier.dispose();
    currentlySelectedListItemsNotifier.dispose();
    _moveActionEnabled.dispose();
    _deleteActionEnabled.dispose();
    _animationController.dispose();
  }

  void _showMoveMultipleDialog() async {
    await showMultiMoveDialog(context, context.read<SelectMultipleCubit>(), widget.initiallySelectedItem, currentlySelectedListItemsNotifier.value);
  }

  void _showDeleteMultipleDialog() async {
    await showMultiDeleteDialog(context, context.read<SelectMultipleCubit>(), widget.initiallySelectedItem, currentlySelectedListItemsNotifier.value);
  }

  void addItem(ListItem listItem) {
    bool itemAlreadySelected = currentlySelectedListItemsNotifier.value.any((element) => listItem.id == element.id);
    if (!itemAlreadySelected) {
      currentlySelectedListItemsNotifier.value.add(listItem);
      print('added ${listItem.runtimeType}');
      print('num in currentlySelectedListItems: ${currentlySelectedListItemsNotifier.value.length}');
    } else {
      print('cannot add item, item already in list');
    }
    
  }

  void removeItem(ListItem listItem) {
    bool itemAlreadySelected = currentlySelectedListItemsNotifier.value.any((element) => listItem.id == element.id);
    if (itemAlreadySelected) {
      currentlySelectedListItemsNotifier.value.removeWhere((element) => element.id == listItem.id);
      print('num in currentlySelectedListItems: ${currentlySelectedListItemsNotifier.value.length}');
    } else {
      print('cannot remove item, item not found in list');
    }
  }

  void toggleItem(ListItem listItem, bool value) {
    print('toggleItem');
    if (!value) removeItem(listItem);
    if (value) addItem(listItem);

    allSelectedNotifier.value =
        currentlySelectedListItemsNotifier.value.length == allItems.length;

    isDeleteEnabled();
    isMoveEnabled();
  }

  void isDeleteEnabled() {
    _deleteActionEnabled.value = currentlySelectedListItemsNotifier.value.isNotEmpty;
    print('_deleteActionEnabled.value: ${_deleteActionEnabled.value}');
  }

  void isMoveEnabled() {
    _moveActionEnabled.value = currentlySelectedListItemsNotifier.value.isNotEmpty;
  }

  bool isItemSelected(ListItem listItem) {
    // Check if the ListItem is in the currentlySelectedListItems list
    bool listItemIsCurrentlySelected = currentlySelectedListItemsNotifier.value.any((element) => element.id == listItem.id);

    // Return true if either condition is met
    return listItemIsCurrentlySelected || allSelectedNotifier.value; 
  }

  void _toggleSelectAll() {
    print('allSelected before toggle: ${allSelectedNotifier.value}');
    print(
        'currentlySelectedListItems before toggle: ${currentlySelectedListItemsNotifier.value}');
    if (!allSelectedNotifier.value) {
      currentlySelectedListItemsNotifier.value = List.from(allItems);
      print('allItems assigned to currentlySelectedListItems');
    } else {
      currentlySelectedListItemsNotifier.value.clear();
    }

    allSelectedNotifier.value = !allSelectedNotifier.value;
    print('allSelected after toggle: ${allSelectedNotifier.value}');
    print(
        'currentlySelectedListItems after toggle: ${currentlySelectedListItemsNotifier.value}');

    isDeleteEnabled();
    isMoveEnabled();
  }

  Widget _buildItem(ListItem listItem) {
    Object itemProp = listItem.item;
    if (itemProp is Receipt) {
      if (itemProp is ReceiptWithSize) {
        return SizedBox(
            height: 60,
            child: ReceiptCheckboxListTile(
              receipt: itemProp,
              withSize: true,
              isSelected: isItemSelected(listItem),
              onChanged: (newValue) {
                toggleItem(listItem, newValue!);
              },
            ));
      }
      if (itemProp is ReceiptWithPrice) {
        return SizedBox(
            height: 60,
            child: ReceiptCheckboxListTile(
              receipt: itemProp,
              isSelected: isItemSelected(listItem),
              price: itemProp.priceString,
              onChanged: (newValue) {
                toggleItem(listItem, newValue!);
              },
            ));
      } else {
        return SizedBox(
            height: 60,
            child: ReceiptCheckboxListTile(
              receipt: itemProp,
              isSelected: isItemSelected(listItem),
              onChanged: (newValue) {
                toggleItem(listItem, newValue!);
              },
            ));
      }
    } else if (itemProp is Folder) {
      if (itemProp is FolderWithSize) {
        return SizedBox(
            height: 60,
            child: FolderCheckboxListTile(
              folder: itemProp,
              storageSize: itemProp.storageSize,
              isSelected: isItemSelected(listItem),
              onChanged: (newValue) {
                toggleItem(listItem, newValue!);
              },
            ));
      }
      if (itemProp is FolderWithPrice) {
        return SizedBox(
            height: 60,
            child: FolderCheckboxListTile(
              folder: itemProp,
              price: itemProp.price,
              isSelected: isItemSelected(listItem),
              onChanged: (newValue) {
                toggleItem(listItem, newValue!);
              },
            ));
      } else {
        return SizedBox(
            height: 60,
            child: FolderCheckboxListTile(
              folder: itemProp,
              isSelected: isItemSelected(listItem),
              onChanged: (newValue) {
                toggleItem(listItem, newValue!);
              },
            ));
      }
    } else {
      return const ListTile(title: Text('Unknown file type'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SelectMultipleCubit, SelectMultipleState>(
      listener: (context, state) {
        if (state is SelectMultipleActivated) {
          // this code should only run once, when the SelectMultipleView is setup
          // currently SelectMultipleActivated is only emitted once so it is fine
          final initiallySelectedListItem = state.initiallySelectedItem;
          final restOfListItems = state.items;
          // adding initially selected item to currentlySelectedListItems
          currentlySelectedListItemsNotifier.value.add(initiallySelectedListItem);
          // adding initially selected item to allItems first
          allItems.add(initiallySelectedListItem);
          // adding rest of folder contents to allItems
          allItems.addAll(restOfListItems);
        }
        if (state is SelectMultipleActionSuccess) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
          appBar: AppBar(
            elevation: 0.0,
            leading: IconButton(
                  icon: const Icon(Icons.close, size: 26,),
                  onPressed: () => Navigator.of(context).pop()
            ),
            backgroundColor: const Color(primaryDarkBlue),
            actions: [
             // select all
             IconButton(onPressed: _toggleSelectAll, icon: Icon(Icons.select_all)),
             // delete selected items
             ValueListenableBuilder(
              valueListenable: _deleteActionEnabled,
              builder: (context, bool value, child) {
                return IconButton(onPressed: value ? _showDeleteMultipleDialog : null, icon: Icon(Icons.delete));}),
             // move selected items
             ValueListenableBuilder(
              valueListenable: _moveActionEnabled,
               builder: (context, bool value, child) {
                 return IconButton(onPressed: value? _showMoveMultipleDialog : null, icon: Icon(Icons.drive_file_move));
               }
             )
            ],
          ),
          body: BlocBuilder<SelectMultipleCubit, SelectMultipleState>(
            buildWhen: (previous, current) => previous is! SelectMultipleActionState || current is! SelectMultipleActionState,
              builder: (context, state) {
            switch (state) {
              case SelectMultipleInitial() || SelectMultipleLoading():
                return const Center(child: CircularProgressIndicator());
              case SelectMultipleError():
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: const Text(
                            'Uh oh, an unexpected error occured. Please go back and/or report the error', textAlign: TextAlign.center, textScaleFactor: 1.2,),
                      ),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Color(primaryDarkBlue))),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Go back'))
                  ],
                );
              case SelectMultipleActivated():
                _animationController.forward(from: 0.0);
                return FadeTransition(
                  opacity: _animationController,
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      slivers: <Widget>[
                                        SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: allItems.length,
                              (context, index) {
                                  return Column(
                                    children: [
                                      SizedBox(height: 4.0,),
                                      ValueListenableBuilder(
                                        valueListenable: allSelectedNotifier,
                                        builder: (context, bool value, child) {
                                          return ValueListenableBuilder(
                                          valueListenable:
                                              currentlySelectedListItemsNotifier,
                                          builder:
                                              (context, List<ListItem> value, child) {
                                            return _buildItem(allItems[index]);
                                          },
                                        );
                                        },
                                      ),
                                    ],
                                  );
                              },
                            ),
                          )
                                      ],
                                    ),
                      ),
                    ],
                  ),
                );
              default:
                return Container();
            }
          })),
    );
  }
}

class FolderCheckboxListTile extends StatefulWidget {
  final Folder folder;
  bool isSelected;
  final ValueChanged<bool?> onChanged; 
  final String displayName;
  final String displayDate;
  final String displaySize;
  final String displayPrice;
  final String? price;
  final int? storageSize;
   // Optional storageSize parameter used to determine whether to show displaySize in subtitle & FolderListTileVisual

  FolderCheckboxListTile({Key? key, required this.folder, required this.onChanged, this.isSelected = false, this.storageSize, this.price})
      : displayName = folder.name.length > 25
            ? "${folder.name.substring(0, 25)}..."
            : folder.name,
        displayDate = Utility.formatDisplayDateFromDateTime(
            Utility.formatDateTimeFromUnixTimestamp(folder.lastModified)),
        displaySize =
            storageSize != null ? Utility.bytesToSizeString(storageSize) : '',
        displayPrice = price ?? '',
        super(key: key);

  @override
  State<FolderCheckboxListTile> createState() => _FolderCheckboxListTileState();
}

class _FolderCheckboxListTileState extends State<FolderCheckboxListTile> {
  final TextStyle displayNameStyle = const TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: Color(primaryGrey));

  final TextStyle checkedDisplayNameeStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white);

  final TextStyle subtitleStyle =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  final TextStyle checkedSubtitleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white);
      
  String calculateSubtitle(
      String displaySize, String displayPrice, String displayDate) {
    if (displaySize.isNotEmpty) {
      return displaySize;
    } else if (displayPrice != '') {
      return displayPrice;
    } else {
      return 'Modified $displayDate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      decoration: widget.isSelected ? BoxDecoration(
        color: Color(primaryDarkBlue),
        borderRadius: BorderRadius.only(topRight: Radius.circular(25.0), bottomRight: Radius.circular(25.0))) : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: GestureDetector(
          onTap: () {
            setState(() {
                  widget.isSelected = !widget.isSelected;
                  widget.onChanged(widget.isSelected);
                });
          },
          child: Transform.translate(
            offset: Offset(0, -6.0),
            child: ListTile(
              leading: Icon(
                Icons.folder,
                size: 50,
                color: widget.isSelected ? Colors.white : null,
              ),
              subtitle: Text(
                calculateSubtitle(widget.displaySize, widget.displayPrice, widget.displayDate),
                style: widget.isSelected ? checkedSubtitleStyle : subtitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: RoundCheckBox(
                animationDuration: const Duration(microseconds: 0),
                borderColor: widget.isSelected ? Colors.white : Color(primaryDarkBlue),
                checkedColor: Color(primaryDarkBlue),
                onTap: (selected) {
                  setState(() {
                    widget.isSelected = !widget.isSelected;
                    widget.onChanged(widget.isSelected);
                  });
                },
                size: 30,
                isChecked: widget.isSelected,
              ),
              title: Text(
                widget.displayName,
                style: widget.isSelected ? checkedDisplayNameeStyle : displayNameStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReceiptCheckboxListTile extends StatefulWidget {
  final Receipt receipt;
  bool isSelected;
  final ValueChanged<bool?> onChanged; 
  final String displayName;
  final String displayDate;
  final String displaySize;
  final String price;
  final bool withSize;

  ReceiptCheckboxListTile({Key? key, required this.receipt, required this.onChanged, this.isSelected = false, this.withSize = false, this.price = ''})
      // displayName is the file name without the file extension and is cut off when the receipt name
      // is > 25 chars or would require 2 lines to be shown completely
      : displayName = receipt.name.length > 25
            ? "${receipt.name.substring(0, 25)}..."
            : receipt.name.split('.').first,
        displayDate = Utility.formatDisplayDateFromDateTime(
            Utility.formatDateTimeFromUnixTimestamp(receipt.lastModified)),
        displaySize = Utility.bytesToSizeString(receipt.storageSize),
          
        super(key: key);

  @override
  State<ReceiptCheckboxListTile> createState() =>
      _ReceiptCheckboxListTileState();
}

class _ReceiptCheckboxListTileState extends State<ReceiptCheckboxListTile> {
  final TextStyle displayNameStyle = const TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: Color(primaryGrey));

  final TextStyle checkedDisplayNameeStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white);

  final TextStyle subtitleStyle =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  final TextStyle checkedSubtitleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white);

    String calculateSubtitle(
      bool withSize, String displayPrice, String displayDate) {
    if (withSize) {
      return widget.displaySize;
    } else if (displayPrice != '') {
      return displayPrice;
    } else {
      return 'Modified $displayDate';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      decoration: widget.isSelected ? BoxDecoration(
        color: Color(primaryDarkBlue),
        borderRadius: BorderRadius.only(topRight: Radius.circular(25.0), bottomRight: Radius.circular(25.0))) : null,
      child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap:() {
              setState(() {
                    widget.isSelected = !widget.isSelected;
                    widget.onChanged(widget.isSelected);
                  });
            },
            child: Transform.translate(
              offset: Offset(0, -6.0),
              child: ListTile(
                  trailing: RoundCheckBox(
                    animationDuration: const Duration(microseconds: 0),
                    borderColor:
                        widget.isSelected ? Colors.white : Color(primaryDarkBlue),
                    checkedColor: Color(primaryDarkBlue),
                    onTap: (selected) {
                      setState(() {
                        widget.isSelected = !widget.isSelected;
                        widget.onChanged(widget.isSelected);
                      });
                    },
                    size: 30,
                    isChecked: widget.isSelected,
                  ),
                  leading: SizedBox(
                    height: 50,
                    width: 50,
                    child: ClipRRect(
                      // square image corners
                      borderRadius: const BorderRadius.all(Radius.zero),
                      child: Image.file(
                        File(widget.receipt.localPath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    calculateSubtitle(
                        widget.withSize, widget.price, widget.displayDate),
                    style: widget.isSelected ? checkedSubtitleStyle : subtitleStyle,
                  ),
                  title: Text(widget.displayName,
                      style: widget.isSelected ? checkedDisplayNameeStyle : displayNameStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ),
          )),
    );
  }
}
