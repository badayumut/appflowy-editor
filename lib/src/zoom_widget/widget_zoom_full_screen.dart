import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

class WidgetZoomFullscreen extends StatefulWidget {
  final Widget zoomWidget;
  final double minScale;
  final double maxScale;
  final Object heroAnimationTag;
  final double? fullScreenDoubleTapZoomScale;
  final VoidCallback? onSharePressed; // Callback for share button
  final VoidCallback? onDeletePressed; // Callback for delete button

  const WidgetZoomFullscreen({
    super.key,
    required this.zoomWidget,
    required this.minScale,
    required this.maxScale,
    required this.heroAnimationTag,
    this.fullScreenDoubleTapZoomScale,
    required this.onSharePressed,
    required this.onDeletePressed,
  });

  @override
  State<WidgetZoomFullscreen> createState() => _ImageZoomFullscreenState();
}

class _ImageZoomFullscreenState extends State<WidgetZoomFullscreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  late double closingTreshold = MediaQuery.of(context).size.height /
      7; //the higher you set the last value the earlier the full screen gets closed

  Animation<Matrix4>? _animation;
  final ValueNotifier<double> _opacity = ValueNotifier(1);
  final ValueNotifier<double> _imagePositionY = ValueNotifier(0);
  final ValueNotifier<double> _imagePositionX = ValueNotifier(0);
  final ValueNotifier<Duration> _animationDuration =
      ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _opacityDuration = ValueNotifier(Duration.zero);
  late double _currentScale = widget.minScale;
  TapDownDetails? _doubleTapDownDetails;

  double alpha = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() => _transformationController.value = _animation!.value);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder<double>(
          valueListenable: _opacity,
          builder: (BuildContext context, double opacity, Widget? child) {
            return ValueListenableBuilder<Duration>(
              valueListenable: _opacityDuration,
              builder:
                  (BuildContext context, Duration opacityDuration, Widget? _) {
                return Positioned.fill(
                  child: AnimatedOpacity(
                    duration: opacityDuration,
                    opacity: opacity,
                    child: Container(
                      color: color(context, Colors.black, Colors.white),
                    ),
                  ),
                );
              },
            );
          },
        ),
        ValueListenableBuilder<Duration>(
          valueListenable: _animationDuration,
          builder: (BuildContext context, Duration animationDuration,
              Widget? child) {
            return ValueListenableBuilder<double>(
              valueListenable: _imagePositionY,
              builder:
                  (BuildContext context, double imagePositionY, Widget? _) {
                return ValueListenableBuilder<double>(
                  valueListenable: _imagePositionX,
                  builder:
                      (BuildContext context, double imagePositionX, Widget? _) {
                    return AnimatedPositioned(
                      duration: animationDuration,
                      top: imagePositionY,
                      bottom: -imagePositionY,
                      left: imagePositionX,
                      right: -imagePositionX,
                      child: child!,
                    );
                  },
                );
              },
            );
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 200,
            child: InteractiveViewer(
              constrained: true,
              transformationController: _transformationController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              onInteractionStart: _onInteractionStart,
              onInteractionUpdate: _onInteractionUpdate,
              onInteractionEnd: _onInteractionEnd,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    alpha = alpha == 1.0 ? 0.0 : 1.0;
                  });
                },
                // need to have both methods, otherwise the zoom will be triggered before the second tap releases the screen
                onDoubleTapDown: (details) => _doubleTapDownDetails = details,
                onDoubleTap: _zoomInOut,
                child: ValueListenableBuilder<double>(
                  valueListenable: _opacity,
                  builder:
                      (BuildContext context, double opacity, Widget? child) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: _opacityDuration,
                      builder: (BuildContext context, Duration opacityDuration,
                          Widget? _) {
                        return AnimatedScale(
                          scale: 1.0 - (0.1 * (1.0 - opacity)),
                          duration: opacityDuration,
                          child: Hero(
                            tag: widget.heroAnimationTag,
                            child: widget.zoomWidget,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _opacity,
              builder: (BuildContext context, double opacity, Widget? child) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: _opacityDuration,
                  builder: (BuildContext context, Duration opacityDuration,
                      Widget? _) {
                    return AnimatedOpacity(
                        duration: opacityDuration,
                        opacity: opacity,
                        child: child);
                  },
                );
              },
              child: AnimatedOpacity(
                opacity: alpha,
                duration: Duration(milliseconds: 150),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: color(context, const Color(0x26ffffff),
                            const Color(0x33000000)),
                        width: 0.0, // 0.0 means one physical pixel
                      ),
                    ),
                    color: color(context, const Color(0x99000000),
                        CupertinoTheme.of(context).barBackgroundColor),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom),
                    child: SizedBox(
                      height: 65,
                      child: IgnorePointer(
                        ignoring: alpha == 0,
                        child: TripleBar(
                          leading: CupertinoButton(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(
                                CupertinoIcons.share,
                                size: 26,
                              ),
                              onPressed: widget.onSharePressed),
                          padding: EdgeInsets.zero,
                          trailing: CupertinoButton(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(CupertinoIcons.delete, size: 26),
                            onPressed: widget.onDeletePressed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).asGlass(tintColor: Colors.transparent),
              ),
            )),
        ValueListenableBuilder<double>(
          valueListenable: _opacity,
          builder: (BuildContext context, double opacity, Widget? child) {
            return ValueListenableBuilder<Duration>(
              valueListenable: _opacityDuration,
              builder:
                  (BuildContext context, Duration opacityDuration, Widget? _) {
                return AnimatedOpacity(
                    duration: opacityDuration, opacity: opacity, child: child!);
              },
            );
          },
          child: AnimatedOpacity(
            opacity: alpha,
            curve: Curves.ease,
            duration: Duration(milliseconds: 150),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color(context, const Color(0x99000000),
                    CupertinoTheme.of(context).barBackgroundColor),
                border: Border(
                  bottom: BorderSide(
                    color: color(context, const Color(0x26ffffff),
                        const Color(0x33000000)),
                    width: 0.0, // 0.0 means one physical pixel
                  ),
                ),
              ),
              child: Padding(
                padding:
                    EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
                child: SizedBox(
                  height: 56,
                  child: IgnorePointer(
                    ignoring: alpha == 0,
                    child: TripleBar(
                      padding: EdgeInsets.zero,
                      trailing: CupertinoButton(
                        padding: const EdgeInsets.only(right: 16.0, left: 4),
                        child: Text(
                          "Close",
                          style: TextStyle(
                              letterSpacing: 0,
                              fontFamily: "pretenda",
                              fontSize: 17,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ).asGlass(tintColor: Colors.transparent),
          ),
        ),
      ],
    );
  }

  void _zoomInOut() {
    final Offset tapPosition = _doubleTapDownDetails!.localPosition;
    final double zoomScale =
        widget.fullScreenDoubleTapZoomScale ?? widget.maxScale;

    final double x = -tapPosition.dx * (zoomScale - 1);
    final double y = -tapPosition.dy * (zoomScale - 1);

    final Matrix4 zoomedMatrix = Matrix4.identity()
      ..translate(x, y)
      ..scale(zoomScale);

    final Matrix4 widgetMatrix = _transformationController.value.isIdentity()
        ? zoomedMatrix
        : Matrix4.identity();

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: widgetMatrix,
    ).animate(
      CurveTween(curve: Curves.easeOut).animate(_animationController),
    );

    _animationController.forward(from: 0);
    _currentScale = _transformationController.value.isIdentity()
        ? zoomScale
        : widget.minScale;
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _animationDuration.value = Duration.zero;
    _opacityDuration.value = Duration.zero;
  }

  void _onInteractionEnd(ScaleEndDetails details) async {
    _currentScale = _transformationController.value.getMaxScaleOnAxis();
    _animationDuration.value = const Duration(milliseconds: 300);
    if (_imagePositionY.value.abs() > closingTreshold) {
      Navigator.of(context).pop();
    } else {
      _imagePositionY.value = 0;
      _imagePositionX.value = 0;
      _opacity.value = 1;
      _opacityDuration.value = const Duration(milliseconds: 300);
    }
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) async {
    // chose 1.05 because maybe the image was not fully zoomed back but it almost looks like that
    if (details.pointerCount == 1 && _currentScale <= 1.05) {
      _imagePositionY.value += details.focalPointDelta.dy;
      _imagePositionX.value += details.focalPointDelta.dx;
      if (_opacity.value != 0) {
        _opacity.value = (1 - (_imagePositionY.value.abs() / closingTreshold))
            .clamp(0, 1)
            .toDouble();
      }
    }
  }
}

class TripleBar extends StatelessWidget {
  const TripleBar(
      {super.key, this.leading, this.middle, this.trailing, this.padding});

  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
              child: Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1,
            child: leading,
          )),
          if (middle != null) middle!,
          Expanded(
              child: Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: trailing,
          ))
        ],
      ),
    );
  }
}

Color color(context, Color dark, Color light) =>
    Theme.of(context).brightness == Brightness.light ? light : dark;
