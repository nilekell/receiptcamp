// ignore_for_file: unused_local_variable
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/logic/cubits/file_explorer/file_explorer_cubit.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/screens/select_multiple_screen.dart';

part 'select_multiple_state.dart';

class SelectMultipleCubit extends Cubit<SelectMultipleState> {
  SelectMultipleCubit(this.folderViewCubit, this.fileExplorerCubit) : super(SelectMultipleInitial());

  final FolderViewCubit folderViewCubit;
  final FileExplorerCubit fileExplorerCubit;

  void init(ListItem selectedItem) {
    emit(SelectMultipleInitial());
    activate(selectedItem);
  }

  Future<void> activate(ListItem selectedItem) async {
    // activate does not actually contain any async code
    // adding an await here means that 
    // SelectMultipleInitial, SelectMultipleLoading, SelectMultipleActivated
    // are not emitted immediately after init() is called,
    // which means there is not enough time for SelectMultipleView build()
    // method to be called, so BlocListener has not been inserted into widget tree yet,
    // resulting in listener not being able to respond to any states
    await Future.delayed(const Duration(seconds: 0));
    emit(SelectMultipleLoading());

    try {
      // Get the parent ID and type of the selected item
      String parentId;
      dynamic selectedObject;

      if (selectedItem.item is Folder) {
        parentId = (selectedItem.item as Folder).parentId;
        selectedObject = selectedItem.item as Folder;
      } else if (selectedItem.item is Receipt) {
        parentId = (selectedItem.item as Receipt).parentId;
        selectedObject = selectedItem.item as Receipt;
      } else {
        emit(SelectMultipleError());
        return;
      }

      List<Object> items = List.from(folderViewCubit.cachedCurrentlyDisplayedFiles);

      // Remove the selected item from the list
      items.removeWhere((element) {
        if (element is Folder && selectedObject is Folder) {
          return element.id == selectedObject.id;
        } else if (element is Receipt && selectedObject is Receipt) {
          return element.id == selectedObject.id;
        }
        return false;
      });

      // Convert items to ListItems
      List<ListItem> listItems =
          items.map((item) => ListItem(item: item)).toList();

      emit(SelectMultipleActivated(
          items: listItems, initiallySelectedItem: selectedItem));
    } on Exception catch (e) {
      print(e.toString());
      emit(SelectMultipleError());
    }
  }

  void moveMultiItems(String destinationFolderId, List<ListItem> items) async {
    emit(SelectMultipleActionLoading());
    try {
      List<Object> objectList = [];

      for (final listItem in items) {
        Object item = listItem.item;
        objectList.add(item);
      }

      await folderViewCubit.moveMultipleItems(objectList, destinationFolderId);
      await fileExplorerCubit.fetchFolderInformation(destinationFolderId);

      emit(SelectMultipleActionSuccess());
    } on Exception catch (e) {
      print(e.toString());
      emit(SelectMultipleError());
    }
  }

  void deleteMultiItems(List<ListItem> items) async {
    emit(SelectMultipleActionLoading());

    try {
      List<Object> objectList = [];

      for (final listItem in items) {
        Object item = listItem.item;
        objectList.add(item);
      }

      await folderViewCubit.deleteMultiItems(objectList);
      await fileExplorerCubit.fetchFolderInformation(rootFolderId);

      emit(SelectMultipleActionSuccess());
    } on Exception catch (e) {
      print(e.toString());
      emit(SelectMultipleError());
    }
  }
}
