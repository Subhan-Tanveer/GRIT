// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() async {
  final exercemusFile = File('exercemus.json');
  final yuhonasFile = File('yuhonas.json');

  if (!exercemusFile.existsSync() || !yuhonasFile.existsSync()) {
    print('Error: Input files not found.');
    return;
  }

  final exercemusData = jsonDecode(exercemusFile.readAsStringSync());
  final yuhonasData = jsonDecode(yuhonasFile.readAsStringSync());

  final List<dynamic> exercemusList = exercemusData['exercises'];
  final List<dynamic> yuhonasList = yuhonasData;

  final Map<String, Map<String, dynamic>> combined = {};

  // Process Exercemus
  for (var ex in exercemusList) {
    final name = ex['name'].toString().trim();
    final primaryMuscles = (ex['primary_muscles'] as List)
        .map((e) => e.toString().toLowerCase())
        .toList();
    final secondaryMuscles = (ex['secondary_muscles'] as List)
        .map((e) => e.toString().toLowerCase())
        .toList();
    final instructionsList = ex['instructions'] as List;
    final instructions = instructionsList.join('\n');
    final equipmentList = ex['equipment'] as List;
    final equipment = equipmentList.isNotEmpty
        ? equipmentList[0].toString().toLowerCase()
        : 'none';

    combined[name.toLowerCase()] = {
      'name': name,
      'muscle_group': primaryMuscles.isNotEmpty ? primaryMuscles[0] : 'other',
      'secondary_muscles': secondaryMuscles.join(', '),
      'equipment': equipment,
      'type': _detectType(ex['category'] ?? ''),
      'instructions': instructions,
    };
  }

  // Process Yuhonas (overwriting/filling gaps)
  for (var ex in yuhonasList) {
    final name = ex['name'].toString().trim();
    final key = name.toLowerCase();

    // If it already exists, maybe skip or merge instructions if empty?
    // Yuhonas often has better names or images (but we don't want images).
    // Let's just merge missing ones.
    if (!combined.containsKey(key)) {
      final primaryMuscles = (ex['primaryMuscles'] as List)
          .map((e) => e.toString().toLowerCase())
          .toList();
      final secondaryMuscles = (ex['secondaryMuscles'] as List)
          .map((e) => e.toString().toLowerCase())
          .toList();
      final instructionsList = ex['instructions'] as List;
      final instructions = instructionsList.join('\n');
      final equipment = ex['equipment']?.toString().toLowerCase() ?? 'none';

      combined[key] = {
        'name': name,
        'muscle_group': primaryMuscles.isNotEmpty ? primaryMuscles[0] : 'other',
        'secondary_muscles': secondaryMuscles.join(', '),
        'equipment': equipment,
        'type': 'weighted', // default
        'instructions': instructions,
      };
    }
  }

  // Add some dedicated Landmine and Smith Machine exercises and others to ensure we hit 1500+ and "latest equipment"
  _addBonusExercises(combined);

  print('Combined Count: ${combined.length}');

  final resultList = combined.values.toList();
  resultList.sort((a, b) => a['name'].compareTo(b['name']));

  final outputFile = File('assets/exercises.json');
  outputFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(resultList));
  print('Saved to assets/exercises.json');
}

String _detectType(String category) {
  category = category.toLowerCase();
  if (category.contains('cardio')) return 'cardio';
  if (category.contains('stretching')) return 'timed';
  if (category.contains('calisthenics')) return 'bodyweight';
  return 'weighted';
}

void _addBonusExercises(Map<String, Map<String, dynamic>> combined) {
  final bonuses = [
    {
      'name': 'Landmine Squat',
      'muscle_group': 'quads',
      'secondary_muscles': 'glutes, core',
      'equipment': 'landmine',
      'type': 'weighted',
      'instructions':
          '1. Load one end of a barbell into a landmine attachment or corner.\n2. Hold the weighted end of the barbell at chest height with both hands.\n3. Stand with feet shoulder-width apart.\n4. Squat down until thighs are parallel to the floor, keeping chest up.\n5. Drive through heels to return to starting position.',
    },
    {
      'name': 'Landmine Press',
      'muscle_group': 'shoulders',
      'secondary_muscles': 'triceps, core',
      'equipment': 'landmine',
      'type': 'weighted',
      'instructions':
          '1. Position one end of a barbell in a landmine attachment.\n2. Stand with feet staggered and grab the end of the bar with one hand at shoulder height.\n3. Press the bar up and away until your arm is fully extended.\n4. Slowly lower back to shoulder height.',
    },
    {
      'name': 'Landmine Row',
      'muscle_group': 'middle back',
      'secondary_muscles': 'biceps, lats',
      'equipment': 'landmine',
      'type': 'weighted',
      'instructions':
          '1. Position a barbell in a landmine.\n2. Stand over the bar and use a V-handle or grasp the bar behind the plates.\n3. Bend at the waist with a flat back.\n4. Pull the weight towards your abdomen, squeezing your shoulder blades together.\n5. Lower the weight under control.',
    },
    {
      'name': 'Smith Machine Squat',
      'muscle_group': 'quads',
      'secondary_muscles': 'glutes, hamstrings',
      'equipment': 'smith machine',
      'type': 'weighted',
      'instructions':
          '1. Set the Smith Machine bar to shoulder height.\n2. Step under the bar and rest it on your traps.\n3. Rotate the bar to unhook it.\n4. Step forward slightly so your feet are in front of your center of gravity.\n5. Squat down and return to the start.',
    },
    {
      'name': 'Smith Machine Bench Press',
      'muscle_group': 'chest',
      'secondary_muscles': 'triceps, shoulders',
      'equipment': 'smith machine',
      'type': 'weighted',
      'instructions':
          '1. Place a bench under the Smith Machine bar.\n2. Lie on the bench and align the bar with your mid-chest.\n3. Unhook the bar and lower it slowly until it nearly touches your chest.\n4. Press the bar back up until arms are extended.',
    },
    {
      'name': 'Cable Face Pull',
      'muscle_group': 'shoulders',
      'secondary_muscles': 'traps, middle back',
      'equipment': 'cable',
      'type': 'weighted',
      'instructions':
          '1. Set a cable pulley to eye level and attach a rope.\n2. Grasp the rope with an overhand grip.\n3. Pull the rope towards your face, pulling the ends apart as you go.\n4. Squeeze your rear delts and upper back at the end of the movement.',
    },
    {
      'name': 'Cable Crossover (High to Low)',
      'muscle_group': 'chest',
      'secondary_muscles': 'shoulders',
      'equipment': 'cable',
      'type': 'weighted',
      'instructions':
          '1. Set pulleys to the highest position on a cable machine.\n2. Grasp both handles and stand in the middle.\n3. Bring your arms down and across your body in a wide arc until hands meet at waist level.\n4. Squeeze your lower chest and return under control.',
    },
  ];

  for (var b in bonuses) {
    combined[b['name']!.toString().toLowerCase()] = b as Map<String, dynamic>;
  }
}
