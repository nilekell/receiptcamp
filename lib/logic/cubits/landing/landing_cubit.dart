import 'package:hydrated_bloc/hydrated_bloc.dart';

class LandingCubit extends HydratedCubit<int> {
  LandingCubit() : super(0);

  updateIndex(int value) {
    emit(value);
  }
  
  @override
  int fromJson(Map<String, dynamic> json) => json['value'] as int;

  
  @override
  Map<String, dynamic>? toJson(int state) => {'value': state};
}
