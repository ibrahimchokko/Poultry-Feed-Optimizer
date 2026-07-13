// =============================================================================
// App-wide constants and formulation data matrix
// Student ID: KASU/19/CSC/1069
// =============================================================================

/// App bar title shown at all times.
const String kAppTitle = 'Feed Formulator (KASU/19/CSC/1069)';

/// Base daily feed rate per bird (kg) for standard poultry types.
const double kStandardFeedRate = 0.15;

/// Base daily feed rate per bird (kg) for turkeys.
const double kTurkeyFeedRate = 0.25;

/// All supported poultry types (display labels map to internal keys).
const List<String> kPoultryTypes = ['broilers', 'layers', 'noilers', 'turkey'];

/// Scientific feed proportion matrices.
/// Proportions are normalised to 1.0 (i.e., 100 % of feed weight mix).
/// Each inner map represents one age-group formulation for that bird type.
const Map<String, Map<String, Map<String, double>>> kFormulations = {
  'broilers': {
    '1-4': {
      'Maize (8.5% CP)': 0.54,
      'Soybean Meal (44% CP)': 0.35,
      'Fish Meal (65% CP)': 0.05,
      'Bone Meal': 0.03,
      'Limestone': 0.02,
      'Lysine + Methionine': 0.005,
      'Vitamin/Mineral Premix': 0.005,
    },
    '5-8': {
      'Maize (8.5% CP)': 0.61,
      'Soybean Meal (44% CP)': 0.29,
      'Fish Meal (65% CP)': 0.03,
      'Bone Meal': 0.03,
      'Limestone': 0.03,
      'Lysine + Methionine': 0.004,
      'Vitamin/Mineral Premix': 0.006,
    },
  },
  'layers': {
    '1-4': {
      'Maize (8.5% CP)': 0.58,
      'Soybean Meal (44% CP)': 0.25,
      'Wheat Offal': 0.09,
      'Bone Meal': 0.03,
      'Limestone': 0.04,
      'Vitamin/Mineral Premix': 0.01,
    },
    '18+': {
      'Maize (8.5% CP)': 0.50,
      'Soybean Meal (44% CP)': 0.22,
      'Wheat Offal': 0.12,
      'Bone Meal': 0.04,
      'Limestone': 0.11, // High Ca for eggshell strength
      'Vitamin/Mineral Premix': 0.01,
    },
  },
  'noilers': {
    '1-4': {
      'Maize (8.5% CP)': 0.55,
      'Soybean Meal (44% CP)': 0.32,
      'Wheat Offal': 0.05,
      'Bone Meal': 0.03,
      'Limestone': 0.04,
      'Vitamin/Mineral Premix': 0.01,
    },
    '5-8': {
      'Maize (8.5% CP)': 0.60,
      'Soybean Meal (44% CP)': 0.26,
      'Wheat Offal': 0.06,
      'Bone Meal': 0.03,
      'Limestone': 0.04,
      'Vitamin/Mineral Premix': 0.01,
    },
  },
  'turkey': {
    '1-4': {
      'Maize (8.5% CP)': 0.44,
      'Soybean Meal (44% CP)': 0.43,
      'Fish Meal (65% CP)': 0.07,
      'Bone Meal': 0.03,
      'Limestone': 0.02,
      'Lysine + Methionine': 0.005,
      'Vitamin/Mineral Premix': 0.005,
    },
    '5-8': {
      'Maize (8.5% CP)': 0.50,
      'Soybean Meal (44% CP)': 0.38,
      'Fish Meal (65% CP)': 0.05,
      'Bone Meal': 0.03,
      'Limestone': 0.03,
      'Lysine + Methionine': 0.005,
      'Vitamin/Mineral Premix': 0.006,
    },
    '9-16': {
      'Maize (8.5% CP)': 0.58,
      'Soybean Meal (44% CP)': 0.30,
      'Fish Meal (65% CP)': 0.04,
      'Bone Meal': 0.03,
      'Limestone': 0.04,
      'Lysine + Methionine': 0.004,
      'Vitamin/Mineral Premix': 0.006,
    },
  },
};
