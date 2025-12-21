import 'package:flutter/material.dart';

/// Utilidades para diseño responsive
class ResponsiveUtils {
  /// Tipos de dispositivos basados en el ancho de pantalla
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 900;
  static const double desktopMaxWidth = 1200;
  static const double smallMobileMaxWidth = 360;

  /// Determina si el dispositivo es móvil pequeño
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < smallMobileMaxWidth;
  }

  /// Determina si el dispositivo es móvil
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  /// Determina si el dispositivo es tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < desktopMaxWidth;
  }

  /// Determina si el dispositivo es desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMaxWidth;
  }

  /// Obtiene el número de columnas para un grid basándose en el ancho de pantalla
  static int getGridCrossAxisCount(
    BuildContext context, {
    int smallMobile = 1,
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < smallMobileMaxWidth) {
      return smallMobile;
    } else if (width < mobileMaxWidth) {
      return mobile;
    } else if (width < tabletMaxWidth) {
      return tablet;
    } else if (width < desktopMaxWidth) {
      return desktop;
    } else {
      return desktop + 1;
    }
  }

  /// Calcula el padding horizontal basándose en el ancho de pantalla
  static double getHorizontalPadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return 12.0;
    } else if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 32.0;
    }
  }

  /// Calcula el padding vertical basándose en el ancho de pantalla
  static double getVerticalPadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return 12.0;
    } else if (isMobile(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  /// Calcula el tamaño de fuente basándose en el ancho de pantalla
  static double getFontSize(
    BuildContext context, {
    required double base,
    double? smallMobile,
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isSmallMobile(context) && smallMobile != null) {
      return smallMobile;
    } else if (isMobile(context) && mobile != null) {
      return mobile;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    return base;
  }

  /// Calcula un valor escalado basándose en el ancho de pantalla
  static double getScaledValue(
    BuildContext context, {
    required double base,
    double scaleFactor = 1.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    final referenceWidth = 375.0; // iPhone X width como referencia

    if (width < smallMobileMaxWidth) {
      // Para pantallas muy pequeñas, escalar hacia abajo
      return base * (width / referenceWidth) * scaleFactor * 0.9;
    } else if (width < mobileMaxWidth) {
      return base * (width / referenceWidth) * scaleFactor;
    } else {
      // Para pantallas grandes, limitar el escalado
      return base * scaleFactor;
    }
  }

  /// Devuelve EdgeInsets apropiados basándose en el tamaño de pantalla
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: getVerticalPadding(context),
    );
  }

  /// Calcula el aspect ratio para un grid basándose en el ancho disponible
  static double getGridAspectRatio(
    BuildContext context, {
    required int columns,
    required double itemHeight,
  }) {
    final width = MediaQuery.of(context).size.width;
    final padding = getHorizontalPadding(context);
    final spacing = 8.0 * (columns - 1);
    final availableWidth = width - (padding * 2) - spacing;
    final itemWidth = availableWidth / columns;

    return itemWidth / itemHeight;
  }

  /// Obtiene el ancho máximo para un contenedor centrado (como formularios)
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 600.0;
    } else {
      return 800.0;
    }
  }

  /// Determina si se debe mostrar el drawer permanentemente (para desktop)
  static bool shouldShowPermanentDrawer(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Calcula el espaciado apropiado para un grid
  static double getGridSpacing(BuildContext context) {
    if (isSmallMobile(context)) {
      return 6.0;
    } else if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  /// Calcula el border radius apropiado basándose en el tamaño de pantalla
  static double getBorderRadius(BuildContext context, {double base = 12.0}) {
    if (isSmallMobile(context)) {
      return base * 0.8;
    } else {
      return base;
    }
  }

  /// Envuelve un widget con SafeArea si es móvil
  static Widget withSafeArea(BuildContext context, Widget child) {
    if (isMobile(context)) {
      return SafeArea(child: child);
    }
    return child;
  }
}
