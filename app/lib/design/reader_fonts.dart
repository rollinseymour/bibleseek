import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stored values stay the iOS names so settings round-trip through backups;
/// browsers can't use Apple's system fonts, so each maps to an open stand-in.
const readerFontOptions = [
  'New York',
  'Georgia',
  'Avenir Next',
  'Helvetica Neue',
];
const readerFontDefault = 'New York';

String readerFontLabel(String family) => switch (family) {
  'Georgia' => 'Gelasio',
  'Avenir Next' => 'Nunito Sans',
  'Helvetica Neue' => 'Inter',
  _ => 'Source Serif',
};

TextStyle readerTextStyle(
  String family, {
  required double fontSize,
  Color? color,
  FontWeight? fontWeight,
  double? height,
}) {
  final f = switch (family) {
    'Georgia' => GoogleFonts.gelasio,
    'Avenir Next' => GoogleFonts.nunitoSans,
    'Helvetica Neue' => GoogleFonts.inter,
    _ => GoogleFonts.sourceSerif4,
  };
  return f(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    height: height,
  );
}
