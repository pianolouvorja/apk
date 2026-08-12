library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvorja_piano_mobile/data/repositories/liturgy_repository.dart';
import 'package:louvorja_piano_mobile/domain/entities/liturgy_item.dart';

// --- Events ---

abstract class LiturgyEvent {
  const LiturgyEvent();
}

class LiturgyLoadRequested extends LiturgyEvent {
  final LiturgyWeekday day;
  const LiturgyLoadRequested(this.day);
}

class LiturgyDayChanged extends LiturgyEvent {
  final LiturgyWeekday day;
  // coverage:ignore-line
  const LiturgyDayChanged(this.day);
}

class LiturgyAddItem extends LiturgyEvent {
  final LiturgyItem item;
  // coverage:ignore-line
  const LiturgyAddItem(this.item);
}

class LiturgyUpdateItem extends LiturgyEvent {
  final LiturgyItem item;
  // coverage:ignore-line
  const LiturgyUpdateItem(this.item);
}

class LiturgyDeleteItem extends LiturgyEvent {
  final String itemId;
  // coverage:ignore-line
  const LiturgyDeleteItem(this.itemId);
}

class LiturgyToggleDone extends LiturgyEvent {
  final String itemId;
  // coverage:ignore-line
  const LiturgyToggleDone(this.itemId);
}

class LiturgyReorderItems extends LiturgyEvent {
  final int oldIndex;
  final int newIndex;
  // coverage:ignore-line
  const LiturgyReorderItems(this.oldIndex, this.newIndex);
}

class LiturgyCloneDay extends LiturgyEvent {
  final LiturgyWeekday from;
  // coverage:ignore-line
  const LiturgyCloneDay(this.from);
}

class LiturgyClearDay extends LiturgyEvent {}

class LiturgyUpdateNotes extends LiturgyEvent {
  final String notes;
  const LiturgyUpdateNotes(this.notes);
}

// --- State ---

abstract class LiturgyState {
  const LiturgyState();
}

class LiturgyInitial extends LiturgyState {}

class LiturgyLoaded extends LiturgyState {
  final LiturgyWeekday selectedDay;
  final List<LiturgyItem> items;
  final String notes;

  const LiturgyLoaded({
    required this.selectedDay,
    required this.items,
    required this.notes,
  });

  LiturgyLoaded copyWith({
    LiturgyWeekday? selectedDay,
    List<LiturgyItem>? items,
    String? notes,
  }) {
    return LiturgyLoaded(
      selectedDay: selectedDay ?? this.selectedDay,
      items: items ?? this.items,
      notes: notes ?? this.notes,
    );
  }
}

// --- Bloc ---

class LiturgyBloc extends Bloc<LiturgyEvent, LiturgyState> {
  final LiturgyRepository _repo;

  LiturgyBloc(this._repo) : super(LiturgyInitial()) {
    on<LiturgyLoadRequested>(_onLoad);
    on<LiturgyDayChanged>(_onDayChanged);
    on<LiturgyAddItem>(_onAddItem);
    on<LiturgyUpdateItem>(_onUpdateItem);
    on<LiturgyDeleteItem>(_onDeleteItem);
    on<LiturgyToggleDone>(_onToggleDone);
    on<LiturgyReorderItems>(_onReorder);
    on<LiturgyCloneDay>(_onCloneDay);
    on<LiturgyClearDay>(_onClearDay);
    on<LiturgyUpdateNotes>(_onUpdateNotes);
  }

  LiturgyRepository get repository => _repo;

  void _onLoad(LiturgyLoadRequested event, Emitter<LiturgyState> emit) {
    final items = _repo.loadItems(event.day);
    final notes = _repo.loadNotes(event.day);
    emit(LiturgyLoaded(
      selectedDay: event.day,
      items: items,
      notes: notes,
    ));
  }

  void _onDayChanged(LiturgyDayChanged event, Emitter<LiturgyState> emit) {
    final items = _repo.loadItems(event.day);
    final notes = _repo.loadNotes(event.day);
    emit(LiturgyLoaded(
      selectedDay: event.day,
      items: items,
      notes: notes,
    ));
  }

  void _onAddItem(LiturgyAddItem event, Emitter<LiturgyState> emit) {
    final state = this.state;
    if (state is! LiturgyLoaded) return;
    final items = [...state.items, event.item];
    _repo.saveItems(state.selectedDay, items);
    emit(state.copyWith(items: items));
  }

  void _onUpdateItem(LiturgyUpdateItem event, Emitter<LiturgyState> emit) {
    final state = this.state;
    if (state is! LiturgyLoaded) return;
    final items = state.items.map((e) => e.id == event.item.id ? event.item : e).toList();
    _repo.saveItems(state.selectedDay, items);
    emit(state.copyWith(items: items));
  }

  void _onDeleteItem(LiturgyDeleteItem event, Emitter<LiturgyState> emit) {
    final state = this.state;
    if (state is! LiturgyLoaded) return;
    final items = state.items.where((e) => e.id != event.itemId).toList();
    // Tambem remove sub-itens da categoria removida
    final children = items.where((e) => e.categoryId == event.itemId).toList();
    for (final child in children) {
      items.remove(child);
    }
    _repo.saveItems(state.selectedDay, items);
    emit(state.copyWith(items: items));
  }

  void _onToggleDone(LiturgyToggleDone event, Emitter<LiturgyState> emit) {
    final state = this.state;
    if (state is! LiturgyLoaded) return;
    final items = state.items.map((e) {
      if (e.id == event.itemId) {
        return e.copyWith(done: !e.done);
      }
      return e;
    }).toList();
    _repo.saveItems(state.selectedDay, items);
    emit(state.copyWith(items: items));
  }

  void _onReorder(LiturgyReorderItems event, Emitter<LiturgyState> emit) {
    final state = this.state;
    if (state is! LiturgyLoaded) return;
    final items = [...state.items];
    final adjustedNew = event.newIndex > event.oldIndex ? event.newIndex - 1 : event.newIndex;
    if (adjustedNew < 0 || adjustedNew >= items.length) return;
    final item = items.removeAt(event.oldIndex);
    items.insert(adjustedNew, item);
    _repo.saveItems(state.selectedDay, items);
    emit(state.copyWith(items: items));
  }

  Future<void> _onCloneDay(LiturgyCloneDay event, Emitter<LiturgyState> emit) async {
    final state = this.state;
    if (state is! LiturgyLoaded) return;
    await _repo.cloneDay(event.from, state.selectedDay);
    final items = _repo.loadItems(state.selectedDay);
    final notes = _repo.loadNotes(state.selectedDay);
    emit(state.copyWith(items: items, notes: notes));
  }

  Future<void> _onClearDay(LiturgyClearDay event, Emitter<LiturgyState> emit) async {
    final state = this.state;
    if (state is! LiturgyLoaded) return;
    await _repo.clearDay(state.selectedDay);
    emit(state.copyWith(items: [], notes: ''));
  }

  void _onUpdateNotes(LiturgyUpdateNotes event, Emitter<LiturgyState> emit) {
    final state = this.state;
    if (state is! LiturgyLoaded) return;
    _repo.saveNotes(state.selectedDay, event.notes);
    emit(state.copyWith(notes: event.notes));
  }
}
