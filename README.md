# 🐔 Poultry Feed Formulation Calculator

> **KASU/19/CSC/1069** — Final Year Project  
> Department of Computer Science, Kaduna State University (KASU)

A production-ready **Flutter** mobile application that calculates precise, balanced daily feed mixtures for different poultry types using a **goal-programming / non-linear optimisation** approach. All calculations are stored offline in a local **SQLite** database for historical reference.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Formulation Data Matrix](#formulation-data-matrix)
- [Business Logic](#business-logic)
- [Database Schema](#database-schema)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Running the App](#running-the-app)
- [Academic Context](#academic-context)
- [License](#license)

---

## Overview

Poultry farmers and feed mill operators need accurate, age-specific feed formulations to maximise growth rates, egg production, and flock health while minimising cost. This application automates that process: given the **poultry type**, **age in weeks**, and **flock size**, it instantly produces an ingredient-level feed recipe in kilograms per day.

The formulation engine is based on **nutrient-proportion matrices** derived from established poultry nutrition science, modelled after the goal-programming linear method commonly applied in agricultural research.

---

## Features

| Category | Detail |
|---|---|
| **Poultry Types** | Broilers, Layers, Noilers, Turkey |
| **Age-Aware Formulation** | Automatic age-group resolution per species |
| **Offline Storage** | Full SQLite persistence via `sqflite` |
| **History Portal** | Draggable bottom sheet with full recipe view |
| **Delete Records** | One-tap delete with live list refresh |
| **Input Validation** | Real-time field validation with red error snackbars |
| **Result Dialog** | Scrollable, selectable monospace recipe output |
| **Material 3 Design** | Dynamic colour scheme, cards, elevated buttons |
| **Null-safe & typed** | Strict Dart null safety throughout |

---

## Screenshots

> _Add screenshots here after building the app._

| Home Screen | Result Dialog | History Sheet |
|---|---|---|
| _(home.png)_ | _(result.png)_ | _(history.png)_ |

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Material 3) |
| **Language** | Dart 3.x (null-safe) |
| **Local Database** | SQLite via [`sqflite ^2.3.3`](https://pub.dev/packages/sqflite) |
| **Path Utilities** | [`path ^1.9.0`](https://pub.dev/packages/path) |
| **Platform** | Android (iOS-compatible structure) |
| **Architecture** | Single-file, self-contained `main.dart` |

---

## Formulation Data Matrix

Ingredient proportions (normalised to 1.0 = 100 % of feed weight) used by the calculation engine:

### Broilers

| Ingredient | 1–4 weeks | 5–8 weeks |
|---|---|---|
| Maize (8.5% CP) | 54 % | 61 % |
| Soybean Meal (44% CP) | 35 % | 29 % |
| Fish Meal (65% CP) | 5 % | 3 % |
| Bone Meal | 3 % | 3 % |
| Limestone | 2 % | 3 % |
| Lysine + Methionine | 0.5 % | 0.4 % |
| Vitamin/Mineral Premix | 0.5 % | 0.6 % |

### Layers

| Ingredient | 1–4 weeks | 18+ weeks |
|---|---|---|
| Maize (8.5% CP) | 58 % | 50 % |
| Soybean Meal (44% CP) | 25 % | 22 % |
| Wheat Offal | 9 % | 12 % |
| Bone Meal | 3 % | 4 % |
| Limestone | 4 % | **11 %** *(eggshell Ca)* |
| Vitamin/Mineral Premix | 1 % | 1 % |

### Noilers

| Ingredient | 1–4 weeks | 5–8 weeks |
|---|---|---|
| Maize (8.5% CP) | 55 % | 60 % |
| Soybean Meal (44% CP) | 32 % | 26 % |
| Wheat Offal | 5 % | 6 % |
| Bone Meal | 3 % | 3 % |
| Limestone | 4 % | 4 % |
| Vitamin/Mineral Premix | 1 % | 1 % |

### Turkey

| Ingredient | 1–4 weeks | 5–8 weeks | 9–16 weeks |
|---|---|---|---|
| Maize (8.5% CP) | 44 % | 50 % | 58 % |
| Soybean Meal (44% CP) | 43 % | 38 % | 30 % |
| Fish Meal (65% CP) | 7 % | 5 % | 4 % |
| Bone Meal | 3 % | 3 % | 3 % |
| Limestone | 2 % | 3 % | 4 % |
| Lysine + Methionine | 0.5 % | 0.5 % | 0.4 % |
| Vitamin/Mineral Premix | 0.5 % | 0.6 % | 0.6 % |

---

## Business Logic

### Age Group Resolution

```
Broilers : age ≤ 4 → "1-4",  else → "5-8"
Layers   : age < 18 → "1-4", else → "18+"
Noilers  : age ≤ 4 → "1-4",  else → "5-8"
Turkey   : age ≤ 4 → "1-4",  age ≤ 8 → "5-8", else → "9-16"
```

### Feed Rate

```
Standard (broilers / layers / noilers) : 0.15 kg per bird per day
Turkey                                 : 0.25 kg per bird per day
```

### Total Feed Calculation

```
Total Feed (kg/day) = Flock Size × Base Feed Rate
Ingredient kg       = Total Feed × Ingredient Proportion
```

---

## Database Schema

**File:** `feed_formulation.db`  
**Table:** `formulations`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique record identifier |
| `type` | TEXT | NOT NULL | Poultry type (e.g. `broilers`) |
| `age` | TEXT | NOT NULL | Age group key (e.g. `1-4`) |
| `amount` | INTEGER | NOT NULL | Number of birds in the flock |
| `formulation` | TEXT | NOT NULL | Full formatted recipe string |

---

## Project Structure

```
feed_formulation_calculator_linear_method/
├── lib/
│   └── main.dart               # Complete single-file app
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/example/.../MainActivity.kt
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
├── pubspec.yaml
└── README.md
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0.0
- Dart SDK ≥ 3.0.0 (bundled with Flutter)
- Android SDK (API 21+) or a connected Android device / emulator

### Install Dependencies

```bash
flutter pub get
```

---

## Running the App

```bash
# Run on a connected device or emulator
flutter run

# Build a release APK
flutter build apk --release

# Build for iOS (macOS required)
flutter build ios --release
```

---

## Academic Context

This application was developed as part of a final-year Computer Science project at **Kaduna State University (KASU)**, matric number **KASU/19/CSC/1069**. It demonstrates:

- Applied use of **linear / goal-programming** methods in agricultural software
- Offline-first mobile architecture with **SQLite**
- Clean, production-grade **Flutter / Dart** development practices
- Real-world problem solving in the Nigerian poultry farming sector

---

## License

This project is submitted for academic evaluation. All rights reserved by the author.  
© 2024 KASU/19/CSC/1069 — Kaduna State University.
