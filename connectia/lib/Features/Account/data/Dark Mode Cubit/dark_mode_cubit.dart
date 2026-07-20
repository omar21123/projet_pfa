import 'package:bloc/bloc.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/storage/AppPreferencesService.dart';
import 'package:meta/meta.dart';

part 'dark_mode_state.dart';

class DarkModeCubit extends Cubit<DarkModeState> {
  DarkModeCubit() : super(DarkModeInitial());
  Future<void> initiale(bool withDarkMode) async {
    var prefer = locator<AppPreferencesService>();
    bool mode = await prefer.initialeDarkModeStatus(withDarkMode);
    if (mode) {
      emit(DarkModeActive());
    } else {
      emit(DarkModeInactive());
    }
  }
  Future<void> setDarkMode() async {
    var prefer = locator<AppPreferencesService>();
    await prefer.changeDarkModeStatus(true);
    emit(DarkModeActive());
  }
  Future<void> setLightMode() async {
    var prefer = locator<AppPreferencesService>();
    await prefer.changeDarkModeStatus(false);
    emit(DarkModeInactive());
  }
}
