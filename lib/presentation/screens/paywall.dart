import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/cubits/purchases/purchases_cubit.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';

class PaywallView extends StatelessWidget {
  const PaywallView({super.key});

  void _showOkDialog(BuildContext context, String message) async {
    showAdaptiveDialog(
        context: context,
        builder: (context) {
          return AlertDialog.adaptive(
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Ok')),
            ],
          );
        });
  }

  Future<void> _showPurchasePendingDialog(BuildContext context) {
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
                      "Purchase is pending...",
                      style: TextStyle(color: Colors.white),
                    )),
              ],
            ),
          );
        }));
  }

  void _closePendingDialogAndBottomSheet(BuildContext context) {
    Navigator.of(context).pop(); // hiding pending dialog
    Navigator.of(context).pop(); // hiding bottom sheet
  }

  void _paywallPurchasesListener(BuildContext context, PurchasesState state) {
    switch (state) {
      case PurchasesPending():
        _showPurchasePendingDialog(context);
        break;
      case PurchasesSuccess():
        _closePendingDialogAndBottomSheet(context);
        _showOkDialog(
            context, 'Purchase successful. Welcome to ReceiptCamp Pro!');
        break;
      case PurchasesFailed():
        Navigator.pop(context); // hiding pending dialog
        _showOkDialog(
            context, 'Uh oh, purchase failed. Please try again later.');
        break;
      case PurchasesRestoreSuccess():
        _closePendingDialogAndBottomSheet(context);
        _showOkDialog(
            context, 'Purchases successfully restored. Welcome back.');
        break;
      case PurchasesRestoreFailed():
        _closePendingDialogAndBottomSheet(context);
        _showOkDialog(
            context, 'Purchase restore failed. Please try again later.');
        break;
      case UserIsAlreadyPro():
        _showOkDialog(context, 'User is already pro.');
        break;
      case UserCannotMakePayments():
        _showOkDialog(context, 'Purchase failed. Please check your payment settings.');
      default:
        _closePendingDialogAndBottomSheet(context);
        _showOkDialog(context, 'Uh oh, unexpected error occured');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<PurchasesCubit>(),
      child: BlocConsumer<PurchasesCubit, PurchasesState>(
        listener: (context, state) {
          _paywallPurchasesListener(context, state);
        },
        builder: (context, state) {
          return DraggableScrollableSheet(
            initialChildSize: 0.95,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(primaryDeepBlue),
                      Color(primaryDarkBlue)
                    ], // Gradient colors
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.white,)),
                      ]),
                    const Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          const Text(
                            'Unlock these premium features:',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ...[
                            'Export expenses with excel spreadsheets',
                            'Share folders as PDFs',
                            'Backup all your expenses'
                          ].map((feature) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check,
                                        color: Color(primaryLightBlue)),
                                    const SizedBox(width: 8),
                                    Text(
                                      feature,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    )
                                  ],
                                ),
                              )),
                          const SizedBox(height: 24),
                          const Text(
                            'Only £4.99',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(primaryLightBlue),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () {
                              context.read<PurchasesCubit>().makeProPurchase();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 28, horizontal: 80),
                            ),
                            child: const Text('Upgrade now',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Pay once, access forever.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 260,),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: TextButton(
                              onPressed: () {
                                context
                                    .read<PurchasesCubit>()
                                    .restorePurchases();
                              },
                              child: const Text('Restore Purchases',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
