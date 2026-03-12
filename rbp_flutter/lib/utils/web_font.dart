import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Platform-aware font weights.
//
// CanvasKit (web) + FreeType renders Roboto thinner than Windows DirectWrite.
// We compensate by bumping to the next REAL Roboto weight step on web:
//   Regular(400) → Medium(500) | Medium(500) → Bold(700) |
//   SemiBold(600) → Bold(700)   | Bold(700)   → Black(900)
//
// Roboto-Black.ttf is bundled in assets/fonts so Skia can actually use w900.
// [kIsWeb] is a compile-time constant — unused branch is tree-shaken.
const FontWeight fw400 = kIsWeb ? FontWeight.w500 : FontWeight.w400;
const FontWeight fw500 = kIsWeb ? FontWeight.w700 : FontWeight.w500;
const FontWeight fw600 = kIsWeb ? FontWeight.w700 : FontWeight.w600;
const FontWeight fw700 = kIsWeb ? FontWeight.w900 : FontWeight.w700;
const FontWeight fw800 = kIsWeb ? FontWeight.w900 : FontWeight.w800;
