// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'upload_bloc.dart';

sealed class UploadEvent extends Equatable {
  const UploadEvent();

  // props declared when we want State to be compared against the values
  // declared inside props List
  @override
  List<Object> get props => [];
}

final class UploadInitialEvent extends UploadEvent {}

final class UploadTapEvent extends UploadEvent {
  final String folderId;

  const UploadTapEvent({required this.folderId});
  
}

final class CameraTapEvent extends UploadEvent {
  final String folderId;

  const CameraTapEvent({required this.folderId});
}

final class FolderCreateEvent extends UploadEvent {
  const FolderCreateEvent({required this.name, required this.parentId});

  final String name;
  final String parentId; 
}