import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutFocusKey {
  final int sessionExerciseId;
  final int setIndex;
  final String fieldType; // 'weight', 'reps', 'duration'

  WorkoutFocusKey(this.sessionExerciseId, this.setIndex, this.fieldType);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutFocusKey &&
          runtimeType == other.runtimeType &&
          sessionExerciseId == other.sessionExerciseId &&
          setIndex == other.setIndex &&
          fieldType == other.fieldType;

  @override
  int get hashCode => sessionExerciseId.hashCode ^ setIndex.hashCode ^ fieldType.hashCode;
}

class WorkoutFocusRegistry {
  final Map<WorkoutFocusKey, FocusNode> _nodes = {};

  void register(int sessionExerciseId, int setIndex, String fieldType, FocusNode node) {
    final key = WorkoutFocusKey(sessionExerciseId, setIndex, fieldType);
    _nodes[key] = node;
  }

  void unregister(int sessionExerciseId, int setIndex, String fieldType) {
    final key = WorkoutFocusKey(sessionExerciseId, setIndex, fieldType);
    _nodes.remove(key);
  }

  void focus(int sessionExerciseId, int setIndex, String fieldType) {
    final key = WorkoutFocusKey(sessionExerciseId, setIndex, fieldType);
    final node = _nodes[key];
    if (node != null && node.canRequestFocus) {
      node.requestFocus();
    }
  }

  void clear() {
    _nodes.clear();
  }
}

final workoutFocusRegistryProvider = Provider((ref) {
  final registry = WorkoutFocusRegistry();
  ref.onDispose(() => registry.clear());
  return registry;
});

