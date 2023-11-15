// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/logic/cubits/file_explorer/file_explorer_cubit.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/models/folder.dart';
import 'package:receiptcamp/models/receipt.dart';
import 'package:receiptcamp/presentation/screens/error_view.dart';
import 'package:receiptcamp/presentation/screens/shimmer.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/folder/folder_list_tile.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/order_sheet.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/receipt/receipt_list_tile.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/snackbar_utility.dart';
import 'package:receiptcamp/presentation/ui/file_explorer/upload_sheet.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  final ValueNotifier<bool> _showUploadButtonNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      // Hide the upload button when user scroll down
      if (_showUploadButtonNotifier.value) _showUploadButtonNotifier.value = false;
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      // Show the upload button when user scroll up
      if (!_showUploadButtonNotifier.value) _showUploadButtonNotifier.value = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<FileExplorerCubit, FileExplorerCubitState>(
          listener: (context, state) {
        switch (state) {
          case FileExplorerCubitFolderInformationSuccess():
          // listening to state here so RefreshableFolderView can be built with the new folder contents, whenever
          // a folder is navigated to
            print('FileExplorer: fetchFiles for ${state.folder.name}');
            context
                .read<FolderViewCubit>()
                .fetchFilesInFolderSortedBy(state.folder.id);
          default:
            print('FileExplorer builder state: ${state.toString()}');
        }
      }, builder: ((context, state) {
        switch (state) {
          case FileExplorerCubitInitial() || FileExplorerCubitLoading():
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: CircularProgressIndicator()),
              ],
            );
          case FileExplorerCubitFolderInformationSuccess():
            _animationController.forward(from: 0.0);
            return FadeTransition(
              opacity: _animationController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          BackButton(
                            previousFolderId: state.folder.parentId,
                            currentFolderId: state.folder.id,
                            visible: state.folder.id != rootFolderId,
                          ),
                        ],
                      ),
                      FolderName(
                        name: state.folder.id != rootFolderId
                            ? state.folder.name
                            : 'Expenses',
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const Divider(
                    thickness: 2,
                    height: 1,
                    indent: 25,
                    endIndent: 25,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        RefreshableFolderView(
                            scrollController: _scrollController),
                        ValueListenableBuilder<bool>(
                          valueListenable: _showUploadButtonNotifier,
                          child: Positioned(
                                right: 28,
                                bottom: 28,
                                child: UploadButton(currentFolder: state.folder),
                              ),
                          builder: (context, showUploadButton, child) {
                            if (showUploadButton) {
                              return child!;
                            } else {
                              return const SizedBox.shrink(); // Return an empty widget that takes up no space
                            }
                          },
                          )
                      ],
                    ),
                  ),
                ],
              ),
            );
          case FileExplorerCubitError():
            print(
                'FileExplorerCubitError with state: ${state.runtimeType.toString()}');
            return const ErrorView();
          default:
            print(
                'FileExplorer BlocBuilder - Unaccounted for state: ${state.runtimeType.toString()}');
            return Container();
        }
      })),
    );
  }
}

class FolderName extends StatelessWidget {
  final String name;
  FolderName({
    super.key,
    required this.name,
  }) : displayName = name.length > 20
            ? "${name.substring(0, 20)}..."
            : name;

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 5),
      child: Text(
        displayName,
        style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Color(primaryGrey)),
      ),
    );
  }
}

class BackButton extends StatelessWidget {
  final String previousFolderId;
  final String currentFolderId;
  final bool visible;

  const BackButton(
      {super.key,
      required this.previousFolderId,
      required this.currentFolderId,
      required this.visible});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: visible,
      child: Transform.translate(
        offset: const Offset(10, 6),
        child: IconButton(
            onPressed: () {
              context.read<FileExplorerCubit>().navigateBack(previousFolderId);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(primaryDarkBlue),
              size: 26.0,
            )),
      ),
    );
  }
}

class SortOption extends StatelessWidget {
  final String currentColumn;
  final String currentOrder;
  final String folderId;
  final FolderViewCubit cubit;

  const SortOption({
    required this.currentColumn,
    required this.currentOrder,
    required this.folderId,
    required this.cubit,
    Key? key,
  }) : super(key: key);

  final sortOptionPadding = const EdgeInsets.only(top: 12.0, left: 30.0);

  Widget _getSortDisplayWidget(String orderedBy, String order,
      BuildContext context, FolderViewCubit cubit, String folderId) {
    const sortTextStyle = TextStyle(
        fontSize: 16, color: Color(primaryGrey), fontWeight: FontWeight.w600);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4.0),
        onTap: () =>
            showOrderOptions(context, cubit, order, orderedBy, folderId),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              () {
                switch (orderedBy) {
                  case 'name':
                    return 'Name';
                  case 'storageSize':
                    return 'Storage used';
                  case 'lastModified':
                    return 'Last modified';
                  case 'price':
                    return 'Price';
                  default:
                    return 'Name';
                }
              }(),
              style: sortTextStyle,
            ),
            OrderIcon(order),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: sortOptionPadding,
      child: _getSortDisplayWidget(
          currentColumn, currentOrder, context, cubit, folderId),
    );
  }
}

class OrderIcon extends Icon {
  const OrderIcon(String order, {super.key})
      : super(
            order == 'ASC'
                ? Icons.arrow_upward
                : order == 'DESC'
                    ? Icons.arrow_downward
                    : Icons.error,
            size: 18.0,
            color: const Color(primaryGrey));
}

class RefreshableFolderView extends StatefulWidget {
  final ScrollController scrollController;

  const RefreshableFolderView({super.key, required this.scrollController});

  @override
  State<RefreshableFolderView> createState() => _RefreshableFolderViewState();
}

class _RefreshableFolderViewState extends State<RefreshableFolderView> {

  void _showEmptySnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: Color(primaryDeepBlue),
      behavior: SnackBarBehavior.floating,
      content: Text("Folder is empty, add some receipts to export"),
      duration: Duration(milliseconds: 2000),
    ));
  }

  Future<void> _showZipProcessingDialog(BuildContext context) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: ((context) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(40.0))),
            backgroundColor: const Color(primaryDeepBlue),
            content: Row(
              children: [
                const CircularProgressIndicator(),
                Container(
                    margin: const EdgeInsets.only(left: 16),
                    child: const Text(
                      "Creating zip file...",
                      style: TextStyle(color: Colors.white),
                    )),
              ],
            ),
          );
        }));
  }

  Future<void> _showErrorDialog(BuildContext context) {
    return showDialog(
        barrierDismissible: true,
        context: context,
        builder: ((context) {
          return const AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(40.0))),
            backgroundColor: Color(primaryDeepBlue),
            content: Text(
              "Failed to create zip file, please try again later",
              style: TextStyle(color: Colors.white),
            ),
          );
        }));
  }

  Widget _buildItem(FolderViewLoadedSuccess state, int index) {
    var item = state.files[index];
    switch (item) {
      case ReceiptWithSize receiptWithSize:
        return ReceiptListTile(
          receipt: receiptWithSize,
          withSize: true,
        );
      case ReceiptWithPrice receiptWithPrice:
        return ReceiptListTile(
          receipt: receiptWithPrice,
          price: receiptWithPrice.priceString,
        );
      case Receipt receipt:
        return ReceiptListTile(receipt: receipt);
      case FolderWithSize folderWithSize:
        return FolderListTile(
          folder: folderWithSize,
          storageSize: folderWithSize.storageSize,
        );
      case FolderWithPrice folderWithPrice:
        return FolderListTile(
          folder: folderWithPrice,
          price: folderWithPrice.price,
        );
      case Folder folder:
        return FolderListTile(folder: folder);
      default:
        return const ListTile(title: Text('Unknown file type'));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FolderViewCubit, FolderViewState>(
      listenWhen: (previous, current) => current is FolderViewActionState || current is FolderViewLoadedSuccess,
      listener: (context, state) {
        if (state is FolderViewActionState) {
          SnackBarUtility.showSnackBar(context, state);
          return;
        }
        if (state is FolderViewFileLoading) {
          _showZipProcessingDialog(context);
          return;
        }
        if (state is FolderViewError) {
          _showErrorDialog(context);
          return;
        }
        if (state is FolderViewFileEmpty) {
          _showEmptySnackBar(context);
        }
        if (state is FolderViewFileLoaded) {
          final folder = state.folder;
          final zipFile = state.zipFile;
          Navigator.of(context).pop();
          context.read<FolderViewCubit>().shareFolder(folder, zipFile);
          return;
        }
      },
      buildWhen: (previous, current) =>
          previous is! FolderViewActionState ||
          current is! FolderViewActionState,
      builder: (context, state) {
        switch (state) {
          case FolderViewInitial() || FolderViewLoading():
            return const Shimmer(child: ShimmerLoading());
          case FolderViewLoadedSuccess():
            print(
                'RefreshableFolderView built with folder: ${state.folder.name}, ${state.orderedBy}, ${state.order}');
            return RefreshIndicator(
              onRefresh: () async {
                print('refreshing folder ${state.folder.name}');
                context
                    .read<FolderViewCubit>()
                    .fetchFilesInFolderSortedBy(state.folder.id);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: widget.scrollController,
                slivers: <Widget>[
                  state.files.isNotEmpty ||
                          state is FolderViewFileState
                      ? SliverToBoxAdapter(
                          child: Row(
                            children: [
                              SortOption(
                                currentColumn: state.orderedBy,
                                currentOrder: state.order,
                                folderId: state.folder.id,
                                cubit: context.read<FolderViewCubit>(),
                              ),
                            ],
                          ),
                        )
                      : SliverToBoxAdapter(child: Container()),
                  state.files.isNotEmpty || state is FolderViewFileState
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildItem(state, index);
                            },
                            childCount: state.files
                                .length, // specifies the number of children this delegate will build
                          ),
                        )
                      : SliverFillRemaining(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 80,),
                                SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Image.asset('assets/x2_retina_receipt_icon.png')),
                                const SizedBox(
                                  height: 12,
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text(
                                    'To add receipts, tap the + button below',
                                    style: TextStyle(
                                        color: Color(primaryGrey),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w100),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            );
          case FolderViewError():
            print(
                'FolderViewCubitError with state: ${state.runtimeType.toString()}');
            return const ErrorView();
          default:
            print(
                'RefreshableFolderView BlocBuilder - Unaccounted for state: ${state.runtimeType.toString()}');
            return Container();
        }
      },
    );
  }
}

class UploadButton extends StatelessWidget {
  final Folder currentFolder;

  const UploadButton({super.key, required this.currentFolder});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      onPressed: () {
        showUploadOptions(
            context, context.read<FolderViewCubit>(), currentFolder);
      },
      child: Stack(alignment: Alignment.center, children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: AssetImage('assets/circle_gradient.png')),
          ),
        ),
        const Icon(
          Icons.add,
          size: 70,
        )
      ]),
    );
  }
}
