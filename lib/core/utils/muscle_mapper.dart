/// Maps muscle name strings from the exercise database to Grit SVG group IDs.
///
/// Available SVG IDs:
/// Front: calves, quads, abdominals, obliques, forearms, biceps, front-shoulders, chest, traps
/// Back:  traps, calves, hamstrings, glutes, forearms, triceps, lats, lowerback, traps-middle, rear-shoulders
class MuscleMapper {
  /// Maps a single muscle name string (from exercises.json) to a Grit SVG group ID.
  static String toSvgId(String muscle) {
    final m = muscle.toLowerCase().trim();

    switch (m) {
      // ── CHEST ─────────────────────────────────────────────
      case 'chest':
      case 'upper chest':
      case 'lower chest':
      case 'pectoralis':
        return 'chest';

      // ── FRONT SHOULDERS / DELTS ──────────────────────────
      case 'front delts':
      case 'front delt':
      case 'shoulders':
      case 'side delts':
      case 'lateral delts':
      case 'shoulder':
      case 'anterior deltoid':
      case 'internal rotators': // Map shoulder internal rotators to front delts
        return 'shoulder_front';

      // ── REAR SHOULDERS ───────────────────────────────────
      case 'rear delts':
      case 'rear delt':
      case 'posterior delts':
      case 'posterior deltoid':
      case 'external rotators': // Map shoulder external rotators to rear delts
        return 'shoulder_back';

      // ── BICEPS ───────────────────────────────────────────
      case 'biceps':
      case 'brachialis':
      case 'biceps long head':
      case 'biceps short head':
        return 'biceps';

      // ── TRICEPS ──────────────────────────────────────────
      case 'triceps':
      case 'triceps long head':
      case 'triceps lateral head':
      case 'triceps medial head':
        return 'triceps';

      // ── FOREARMS ─────────────────────────────────────────
      case 'forearms':
      case 'brachioradialis': // Brachioradialis is the large forearm muscle
      case 'wrist flexors':
      case 'wrist extensors':
        return 'forearms';

      // ── LATS ─────────────────────────────────────────────
      case 'lats':
      case 'latissimus dorsi':
        return 'lats';

      // ── TRAPS (upper / visible from front) ───────────────
      case 'traps':
      case 'upper traps':
      case 'neck extensors':
      case 'neck flexors':
      case 'neck':
        return 'traps';

      // ── MID TRAPS / RHOMBOIDS (back middle) ──────────────
      case 'mid traps':
      case 'rhomboids':
      case 'upper back':
      case 'middle traps':
      case 'lower traps':
        return 'traps_middle';

      // ── LOWER BACK / ERECTORS ────────────────────────────
      case 'erectors':
      case 'lowerback':
      case 'lower back':
      case 'erector spinae':
      case 'spinal erectors':
        return 'lower_back';

      // ── QUADS / ADDUCTORS ────────────────────────────────
      case 'quads':
      case 'adductors':
      case 'quadriceps':
      case 'vastus lateralis':
      case 'vastus medialis':
      case 'rectus femoris':
      case 'thighs':
        return 'quads';

      // ── HAMSTRINGS ───────────────────────────────────────
      case 'hamstrings':
      case 'biceps femoris':
        return 'hamstrings';

      // ── GLUTES / ABDUCTORS ────────────────────────────────
      case 'glutes':
      case 'gluteus maximus':
      case 'glutes med':
      case 'gluteus medius':
      case 'gluteus minimus':
      case 'hip abductors': // Glute med/min are primary abductors
      case 'tfl': // Tensor fasciae latae is a hip abductor/rotator, glute-adjacent
        return 'glutes';

      // ── CALVES ───────────────────────────────────────────
      case 'calves':
      case 'soleus':
      case 'gastrocnemius':
      case 'tibialis':
        return 'calves';

      // ── CORE / ABS ───────────────────────────────────────
      case 'abs':
      case 'core':
      case 'hip flexors':
      case 'abdominals':
      case 'rectus abdominis':
      case 'transverse abdominis':
        return 'abs';

      // ── OBLIQUES ─────────────────────────────────────────
      case 'obliques':
      case 'external obliques':
      case 'internal obliques':
        return 'obliques';

      // ── DEFAULT FALLBACK (Generalized) ────────────────────
      default:
        // Fuzzy match for partial strings
        if (m.contains('chest') || m.contains('pec')) return 'chest';
        if (m.contains('delt') || m.contains('shoulder')) {
          if (m.contains('rear') || m.contains('post')) return 'shoulder_back';
          return 'shoulder_front';
        }
        if (m.contains('bicep') || m.contains('brachio')) return 'biceps';
        if (m.contains('tricep')) return 'triceps';
        if (m.contains('forearm') || m.contains('wrist')) return 'forearms';
        if (m.contains('lat') && !m.contains('later')) return 'lats';
        if (m.contains('trap')) return 'traps';
        if (m.contains('erector') || m.contains('lower back') || m.contains('spine')) return 'lower_back';
        if (m.contains('quad') || m.contains('adduct') || m.contains('vastus') || m.contains('leg')) return 'quads';
        if (m.contains('ham')) return 'hamstrings';
        if (m.contains('glute') || m.contains('abductor')) return 'glutes';
        if (m.contains('calf') || m.contains('calve') || m.contains('soleus') || m.contains('gastro')) return 'calves';
        if (m.contains('oblique')) return 'obliques';
        if (m.contains('abs') || m.contains('core') || m.contains('abdom') || m.contains('flexor')) return 'abs';
        
        // Final fallback: return empty to avoid false highlights if unknown
        return '';

    }
  }

  /// Maps a list of muscle names (e.g. muscles_primary) to a set of unique SVG IDs.
  static List<String> mapMuscleList(List<String> muscles) {
    return muscles.map(toSvgId).toSet().toList();
  }

  /// Derives the primary SVG ID (muscle_group) from a list of primary muscles.
  static String primarySvgId(List<dynamic> muscles) {
    if (muscles.isEmpty) return 'abs';
    return toSvgId(muscles.first as String);
  }

  /// Human-readable label for a SVG ID.
  static String toDisplayLabel(String svgId) {
    switch (svgId.toLowerCase()) {
      case 'chest': return 'CHEST';
      case 'lats': return 'LATS';
      case 'traps': return 'TRAPS';
      case 'traps_middle': return 'MID TRAPS';
      case 'lower_back': return 'LOWER BACK';
      case 'shoulder_front': return 'FRONT DELTS';
      case 'shoulder_back': return 'REAR DELTS';
      case 'biceps': return 'BICEPS';
      case 'triceps': return 'TRICEPS';
      case 'forearms': return 'FOREARMS';
      case 'quads': return 'QUADS';
      case 'hamstrings': return 'HAMSTRINGS';
      case 'glutes': return 'GLUTES';
      case 'calves': return 'CALVES';
      case 'abs': return 'ABS';
      case 'obliques': return 'OBLIQUES';
      default: return svgId.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Returns true if the muscle is primarily visible from the back view.
  static bool isBackMuscle(String svgId) {
    final m = svgId.toLowerCase();
    return [
      'lats',
      'traps',
      'lower_back',
      'triceps',
      'glutes',
      'hamstrings',
      'calves',
      'shoulder_back',
      'back', // Legacy
      'legs', // Legacy
    ].contains(m);
  }

  /// Maps a high-level category (e.g. 'BACK') to a list of granular SVG IDs.
  static List<String> getSvgIdsForCategory(String category) {
    final c = category.toUpperCase();
    switch (c) {
      case 'CHEST': return ['chest'];
      case 'BACK': return ['lats', 'traps', 'traps_middle', 'lower_back', 'back'];
      case 'SHOULDERS': return ['shoulder_front', 'shoulder_back', 'shoulders', 'shoulder'];
      case 'BICEPS':
        return ['biceps'];
      case 'TRICEPS':
        return ['triceps'];
      case 'FOREARMS':
        return ['forearms', 'brachioradialis'];
      case 'LEGS':
        return ['quads', 'hamstrings', 'glutes', 'calves', 'glutes med', 'glutes min', 'adductors', 'abductors', 'hip flexors', 'soleus', 'tibialis'];
      default: return [category.toLowerCase()];
    }
  }

  // Legacy: used by older parts of the code (mapToPackageGroups)
  static List<String> mapToPackageGroups(Set<String> appMuscles) {
    return mapMuscleList(appMuscles.toList());
  }

  // Legacy: single string target -> SVG ID (used by old ExerciseDB format)
  static String mapTargetToSvgId(String target) => toSvgId(target);
}
