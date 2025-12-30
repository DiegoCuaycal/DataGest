import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:lottie/lottie.dart';

/// Widget de indicador de carga profesional con logo animado
///
/// Muestra el logo de DataGest con una animación profesional y
/// un texto de "Cargando..." opcional.
/// ```
class LoadingIndicator extends StatelessWidget {
  /// Tamaño del logo
  final double size;

  /// Mostrar texto de cargando
  final bool showText;

  /// Texto personalizado
  final String? text;

  /// Color del fondo (para overlays)
  final Color? backgroundColor;

  /// Opacidad del fondo
  final double backgroundOpacity;

  /// Mostrar animación Lottie si está disponible
  final bool useLottie;

  const LoadingIndicator({
    super.key,
    this.size = 120,
    this.showText = true,
    this.text,
    this.backgroundColor,
    this.backgroundOpacity = 0.0,
    this.useLottie = true,
  });

  /// Constructor para uso en overlays con fondo semi-transparente
  const LoadingIndicator.overlay({
    super.key,
    this.size = 120,
    this.showText = true,
    this.text,
  })  : backgroundColor = Colors.black54,
        backgroundOpacity = 0.7,
        useLottie = true;

  /// Constructor para versión compacta
  const LoadingIndicator.small({
    super.key,
    this.showText = false,
    this.text,
    this.backgroundColor,
  })  : size = 60,
        backgroundOpacity = 0.0,
        useLottie = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor?.withOpacity(backgroundOpacity),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contenedor del logo con animación
            _buildAnimatedLogo(),

            if (showText) ...[
              const SizedBox(height: 24),
              _buildLoadingText(),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye el logo animado
  Widget _buildAnimatedLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Spinner circular alrededor
        SizedBox(
          width: size + 16,
          height: size + 16,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary.withOpacity(0.8),
            ),
          ),
        ),

        // Contenedor del logo
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fondo con gradiente vibrante
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.white,
                        AppColors.primary.withOpacity(0.08),
                        AppColors.secondary.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),

                // Logo con animación de escala
                _LogoWithPulse(
                  size: size * 0.7,
                  useLottie: useLottie,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el texto de cargando con animación
  Widget _buildLoadingText() {
    return Column(
      children: [
        _AnimatedLoadingText(text: text ?? 'Cargando'),
        const SizedBox(height: 16),
        // Indicador de progreso
        SizedBox(
          width: 200,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: null, // Indeterminado
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 3,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget interno para el logo con animación de pulso
class _LogoWithPulse extends StatefulWidget {
  final double size;
  final bool useLottie;

  const _LogoWithPulse({
    required this.size,
    required this.useLottie,
  });

  @override
  State<_LogoWithPulse> createState() => _LogoWithPulseState();
}

class _LogoWithPulseState extends State<_LogoWithPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Siempre usar el logo animado para garantizar consistencia
    return _buildAnimatedLogo();
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Image.asset(
              'assets/images/DataGestIcon.png',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}

/// Widget interno para el texto animado de cargando
class _AnimatedLoadingText extends StatefulWidget {
  final String text;

  const _AnimatedLoadingText({required this.text});

  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..addListener(() {
        setState(() {
          _dotCount = (_controller.value * 3).floor() % 4;
        });
      });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '.' * _dotCount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
