import 'package:bloc/bloc.dart';
import 'package:connectia/Features/Home/data/CategoryRepo.dart';
import 'package:connectia/Features/Home/data/Models/CategoryModel.dart';

sealed class CategoryState {}

final class CategoryLoading extends CategoryState {}

final class CategoryLoaded extends CategoryState {
  final List<NavbarCategory> allCategories;
  final List<NavbarCategory> path;
  final List<NavbarCategory> currentChildren;

  CategoryLoaded({
    required this.allCategories,
    this.path = const [],
    this.currentChildren = const [],
  });

  bool get atTopLevel => path.isEmpty;
  int get selectedCategoryId =>
      path.isNotEmpty ? path.last.id : -1;
}

final class CategoryError extends CategoryState {
  final String message;
  CategoryError({required this.message});
}

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepo _repo;

  CategoryCubit({required CategoryRepo repo})
      : _repo = repo,
        super(CategoryLoading());

  Future<void> fetchCategories() async {
    emit(CategoryLoading());

    final result = await _repo.getNavbarCategories();

    result.fold(
      (failure) => emit(CategoryError(message: failure.displayMessage)),
      (categories) {
        emit(CategoryLoaded(
          allCategories: categories,
          path: [],
          currentChildren: categories,
        ));
      },
    );
  }

  void selectCategory(int categoryId) {
    final current = state;
    if (current is! CategoryLoaded) return;

    final idx = current.currentChildren.indexWhere(
      (c) => c.id == categoryId,
    );
    if (idx == -1) return;

    final tapped = current.currentChildren[idx];
    final newPath = [...current.path, tapped];

    emit(CategoryLoaded(
      allCategories: current.allCategories,
      path: newPath,
      currentChildren: tapped.children,
    ));
  }

  void navigateToLevel(int levelIndex) {
    final current = state;
    if (current is! CategoryLoaded) return;
    if (levelIndex >= current.path.length) return;

    final newPath = current.path.sublist(0, levelIndex);
    final parent = levelIndex > 0 ? newPath.last : null;
    final children =
        parent != null ? parent.children : current.allCategories;

    emit(CategoryLoaded(
      allCategories: current.allCategories,
      path: newPath,
      currentChildren: children,
    ));
  }

  void clearSelection() {
    final current = state;
    if (current is! CategoryLoaded) return;

    emit(CategoryLoaded(
      allCategories: current.allCategories,
      path: [],
      currentChildren: current.allCategories,
    ));
  }

  /// Go back to top level then select a top-level category by id.
  void selectTopLevel(int categoryId) {
    final current = state;
    if (current is! CategoryLoaded) return;

    final idx = current.allCategories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return;

    final tapped = current.allCategories[idx];
    emit(CategoryLoaded(
      allCategories: current.allCategories,
      path: [tapped],
      currentChildren: tapped.children,
    ));
  }
}
