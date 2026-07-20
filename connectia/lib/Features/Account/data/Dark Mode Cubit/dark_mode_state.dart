part of 'dark_mode_cubit.dart';

@immutable
sealed class DarkModeState {}

final class DarkModeInitial extends DarkModeState {}

final class DarkModeActive extends DarkModeState {}

final class DarkModeInactive extends DarkModeState {}
