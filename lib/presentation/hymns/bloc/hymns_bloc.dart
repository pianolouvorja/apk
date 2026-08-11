library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/louvorja_api_impl.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/repositories/hymn_repository.dart';

// --- Events ---

abstract class HymnsEvent {
  const HymnsEvent();
}

class HymnsLoadRequested extends HymnsEvent {}

class HymnsRefreshRequested extends HymnsEvent {}

// --- States ---

abstract class HymnsState {
  const HymnsState();
}

class HymnsInitial extends HymnsState {}

class HymnsLoading extends HymnsState {}

class HymnsLoaded extends HymnsState {
  final List<AlbumCategory> categories;

  const HymnsLoaded(this.categories);
}

class HymnsError extends HymnsState {
  /// Código i18n da mensagem de erro (ex: 'errors.connection').
  final String code;

  const HymnsError(this.code);
}

// --- BLoC ---

class HymnsBloc extends Bloc<HymnsEvent, HymnsState> {
  final HymnRepository _repository;

  HymnsBloc(this._repository) : super(HymnsInitial()) {
    on<HymnsLoadRequested>(_onLoad);
    on<HymnsRefreshRequested>(_onRefresh);
  }

  /// Exposto para páginas filhas (AlbumDetailPage) buscarem hinos.
  HymnRepository get repository => _repository;

  Future<void> _onLoad(HymnsLoadRequested event, Emitter<HymnsState> emit) async {
    emit(HymnsLoading());
    try {
      final categories = await _repository.getCategories();
      emit(HymnsLoaded(categories));
    } on LouvorjaApiException catch (e) {
      emit(HymnsError(e.code));
    } catch (_) {
      emit(const HymnsError('errors.unknown'));
    }
  }

  Future<void> _onRefresh(HymnsRefreshRequested event, Emitter<HymnsState> emit) async {
    try {
      final categories = await _repository.getCategories();
      emit(HymnsLoaded(categories));
    } on LouvorjaApiException catch (e) {
      emit(HymnsError(e.code));
    } catch (_) {
      emit(const HymnsError('errors.unknown'));
    }
  }
}
