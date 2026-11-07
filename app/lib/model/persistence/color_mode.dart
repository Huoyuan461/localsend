enum ColorMode {
  system, // dynamic colors
  zhichuan,
  oled,
  yaru,
  custom, // user-defined seed color
  charcoal, // Pro: dark charcoal grey
  forest, // Pro: deep forest green
  obsidian, // Pro: near-black
}

extension ColorModeExt on ColorMode {
  /// Whether this theme is a Pro-only theme.
  bool get isProTheme => this == ColorMode.charcoal || this == ColorMode.forest || this == ColorMode.obsidian;
}
