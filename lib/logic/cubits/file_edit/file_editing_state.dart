part of 'file_editing_cubit.dart';

sealed class FileEditingCubitState extends Equatable {
  const FileEditingCubitState();

  @override
  List<Object> get props => [];
}

final class FileEditingCubitInitial extends FileEditingCubitState {}

// Renaming States

final class FileEditingCubitRenameSuccess extends FileEditingCubitState {
  const FileEditingCubitRenameSuccess({required this.oldName, required this.newName});
  final String oldName;
  final String newName;

  @override
  List<Object> get props => [oldName, newName];
}

final class FileEditingCubitRenameFailure extends FileEditingCubitState {
  final String oldName;
  final String newName;

  const FileEditingCubitRenameFailure({required this.oldName, required this.newName});

  @override
  List<Object> get props => [oldName, newName];
}

// Moving states

final class FileEditingCubitMoveSuccess extends FileEditingCubitState {
  const FileEditingCubitMoveSuccess({required this.oldName, required this.newName});

  final String oldName;
  final String newName;

  @override
  List<Object> get props => [oldName, newName];
}

final class FileEditingCubitMoveFailure extends FileEditingCubitState {
  const FileEditingCubitMoveFailure({required this.oldName, required this.newName});

  final String oldName;
  final String newName;

  @override
  List<Object> get props => [oldName, newName];
}

// Deleting states

final class FileEditingCubitDeleteSuccess extends FileEditingCubitState {
  const FileEditingCubitDeleteSuccess({required this.deletedName});

  final String deletedName;

  @override
  List<Object> get props => [deletedName];
}

final class FileEditingCubitDeleteFailure extends FileEditingCubitState {
  const FileEditingCubitDeleteFailure({required this.deletedName});

  final String deletedName;

  @override
  List<Object> get props => [deletedName];
}

// Sharing states

final class FileEditingCubitShareSuccess extends FileEditingCubitState {
  const FileEditingCubitShareSuccess({required this.receiptName});

  final String receiptName;

  @override
  List<Object> get props => [receiptName];
}

final class FileEditingCubitShareFailure extends FileEditingCubitState {
  const FileEditingCubitShareFailure({required this.receiptName});

  final String receiptName;

  @override
  List<Object> get props => [receiptName];
}

// Saving states

final class FileEditingCubitSaveImageSuccess extends FileEditingCubitState {
  const FileEditingCubitSaveImageSuccess({required this.receiptName});

  final String receiptName;

  @override
  List<Object> get props => [receiptName];
}

final class FileEditingCubitSaveImageFailure extends FileEditingCubitState {
  const FileEditingCubitSaveImageFailure({required this.receiptName});

  final String receiptName;

  @override
  List<Object> get props => [receiptName];
}
