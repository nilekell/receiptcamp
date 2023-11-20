import 'dart:io' show Platform;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:receiptcamp/data/services/purchases.dart';

part 'purchases_state.dart';

class PurchasesCubit extends Cubit<PurchasesState> {
  PurchasesCubit() : super(PurchasesInitial());

  final PurchasesService _purchasesService = PurchasesService.instance;

  checkUserPurchaseStatus() {
    print('checkUserPurchaseStatus');
    bool userIsPro = _purchasesService.userIsPro;
    emit(PurchasesUserStatus(isPro: userIsPro));
    // emitting initial state which does nothing
    // different state means listener can be called again
    emit(PurchasesInitial());
  }

  makeProPurchase() async {
    emit(PurchasesPending());
    try {
      // works on android only
      if (Platform.isAndroid && !(await _purchasesService.canMakePayments())) {
        emit(UserCannotMakePayments());
        return;
      }

      if (_purchasesService.userIsPro) {
        emit(UserIsAlreadyPro());
        return;
      }
      
      final bool isPurchaseSuccessful =
          await _purchasesService.makeProLifetimePurchase();
      if (isPurchaseSuccessful) {
        emit(PurchasesSuccess());
      } else {
        emit(PurchasesFailed());
      }
    } on Exception catch (e) {
      print(e.toString());
      emit(PurchasesFailed());
    }
  }

  restorePurchases() async {
    emit(PurchasesPending());
    try {
      if (_purchasesService.userIsPro) {
        emit(UserIsAlreadyPro());
        return;
      }

      await _purchasesService.restorePurchases();
      if (_purchasesService.userIsPro) {
        emit(PurchasesRestoreSuccess());
      } else {
        emit(PurchasesRestoreFailed());
      }
    } on Exception catch (e) {
      print(e.toString());
      emit(PurchasesRestoreFailed());
    }
  }
}
