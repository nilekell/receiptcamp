import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/models/receipt.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends HydratedBloc<HomeEvent, HomeState> {
  final DatabaseRepository databaseRepository;

  HomeBloc({required this.databaseRepository}) : super(HomeInitialState()) {
    on<HomeLoadReceiptsEvent>(onHomeLoadReceipts);
    on<HomeInitialEvent>(onHomeInitialEvent);
  }

  FutureOr<void> onHomeInitialEvent(
      HomeInitialEvent event, Emitter<HomeState> emit) {
    emit(HomeLoadingState());
    add(HomeLoadReceiptsEvent());
  }

  FutureOr<void> onHomeLoadReceipts(
      HomeLoadReceiptsEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    try {
      final receipts = await databaseRepository.getRecentReceipts();
      if (receipts.isNotEmpty) {
      emit(HomeLoadedSuccessState(receipts: receipts));
    } else {
      emit(HomeEmptyReceiptsState());
    }
    } catch (_) {
      emit(HomeErrorState());
    }
  }
  
  @override
  HomeState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['receipts'] != null) {
        final receipts = (json['receipts'] as List).map((e) => Receipt.fromJson(e)).toList();
        return HomeLoadedSuccessState(receipts: receipts);
      } else if (json['error'] == true) {
        return HomeErrorState();
      } else if (json['loading'] == true) {
        return HomeLoadingState();
      } else {
        return HomeEmptyReceiptsState();
      }
    } catch (_) {
      return null;
    }
  }
  
  @override
  Map<String, dynamic>? toJson(HomeState state) {
    try {
      if (state is HomeLoadedSuccessState) {
        return {
          'receipts': state.receipts.map((e) => e.toJson()).toList(),
        };
      } else if (state is HomeErrorState) {
        return {'error': true};
      } else if (state is HomeLoadingState) {
        return {'loading': true};
      } else if (state is HomeEmptyReceiptsState) {
        return {'empty': true};
      }
    } catch (_) {
      return {'error': true};
    }
    return null;
  }
}
