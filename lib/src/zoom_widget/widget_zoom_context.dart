import 'package:appflowy_editor/src/glass_widget.dart';
import 'package:appflowy_editor/src/zoom_widget/widget_zoom_full_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:pull_down_button/pull_down_button.dart';

class WidgetZoomContext extends StatefulWidget {
  final Widget zoomWidget;
  final double minScale;
  final double maxScale;
  final Object heroAnimationTag;
  final double? fullScreenDoubleTapZoomScale;
  final VoidCallback? onSharePressed; // Callback for share button
  final VoidCallback? onDeletePressed;

  const WidgetZoomContext({
    Key? key,
    required this.zoomWidget,
    required this.minScale,
    required this.maxScale,
    required this.heroAnimationTag,
    this.fullScreenDoubleTapZoomScale,
    required this.onSharePressed,
    required this.onDeletePressed,
  }) : super(key: key);

  @override
  State<WidgetZoomContext> createState() => _ImageZoomFullscreenState();
}

class _ImageZoomFullscreenState extends State<WidgetZoomContext>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  late double closingTreshold = MediaQuery.of(context).size.height /
      8; //the higher you set the last value the earlier the full screen gets closed

  Animation<Matrix4>? _animation;

  final ValueNotifier<double> _opacity = ValueNotifier(1);
  final ValueNotifier<double> _imagePositionY = ValueNotifier(0);
  final ValueNotifier<double> _imagePositionX = ValueNotifier(0);
  final ValueNotifier<Duration> _animationDuration =
      ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _opacityDuration = ValueNotifier(Duration.zero);

  late double _currentScale = widget.minScale;
  TapDownDetails? _doubleTapDownDetails;
  IconData arrow_down = CupertinoIcons.arrow_down_to_line_alt;

  String save_image = "Save Image";

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
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.pop(context);
        },
        child: ValueListenableBuilder<double>(
          valueListenable: _opacity,
          builder: (BuildContext context, double opacity, Widget? child) {
            return Glass(
                tintColor: Colors.black,
                blurX: (opacity * 10) + 0.01,
                blurY: (opacity * 10) + 0.01,
                child: child!);
          },
          child: Stack(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: _opacity,
                builder: (BuildContext context, double opacity, Widget? child) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: _opacityDuration,
                    builder: (BuildContext context, Duration opacityDuration,
                        Widget? child) {
                      return Positioned.fill(
                        child: AnimatedOpacity(
                          duration: opacityDuration,
                          opacity: opacity,
                          child: ColoredBox(
                            color: color(context, Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.1)),
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
                    builder: (BuildContext context, double imagePositionY,
                        Widget? _) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _imagePositionX,
                        builder: (BuildContext context, double imagePositionX,
                            Widget? _) {
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
                    maxScale: widget.minScale,
                    onInteractionStart: _onInteractionStart,
                    onInteractionUpdate: _onInteractionUpdate,
                    onInteractionEnd: _onInteractionEnd,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<double>(
                          valueListenable: _opacity,
                          builder: (BuildContext context, double opacity,
                              Widget? child) {
                            return ValueListenableBuilder<Duration>(
                              valueListenable: _opacityDuration,
                              builder: (BuildContext context,
                                  Duration opacityDuration, Widget? _) {
                                return AnimatedScale(
                                    alignment: Alignment.bottomCenter,
                                    scale: 1.0 - (0.1 * (1.0 - opacity)),
                                    duration: opacityDuration,
                                    child: child);
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Hero(
                              tag: widget.heroAnimationTag,
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.2),
                                        blurRadius: 20,
                                      ),
                                    ]),
                                child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.sizeOf(context).height *
                                                0.65),
                                    child: SizedBox(
                                        width: double.infinity,
                                        child: Material(
                                          type: MaterialType.transparency,
                                          color: Colors.transparent,
                                          surfaceTintColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          child: InkWell(
                                              focusColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              splashColor: Colors.transparent,
                                              splashFactory:
                                                  NoSplash.splashFactory,
                                              onTap: () {
                                                openFullScreen(context);
                                              },
                                              child: widget.zoomWidget),
                                        ))),
                              ),
                            ),
                          ),
                        ),
                        ValueListenableBuilder<double>(
                          valueListenable: _opacity,
                          builder: (BuildContext context, double opacity,
                              Widget? child) {
                            return AnimatedScale(
                              alignment: Alignment.topCenter,
                              scale: opacity > 0.5 ? 1 : 0.5,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.ease,
                              child: AnimatedOpacity(
                                  curve: Curves.ease,
                                  duration: const Duration(milliseconds: 200),
                                  opacity: opacity > 0.5 ? 1 : 0,
                                  child: child),
                            );
                          },
                          child: PullDownMenu(
                              routeTheme: const PullDownMenuRouteTheme(
                                shadow: BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                  blurRadius: 64,
                                ),
                              ),
                              items: [
                                PullDownMenuItem(
                                  itemTheme: const PullDownMenuItemTheme(),
                                  title: 'Share',
                                  onTap: widget.onSharePressed,
                                  icon: CupertinoIcons.share,
                                ),
                                PullDownMenuItem(
                                  itemTheme: const PullDownMenuItemTheme(),
                                  title: save_image,
                                  onTap: () {
                                    setState(() {
                                      arrow_down =
                                          CupertinoIcons.check_mark_circled;
                                      save_image = "Saved";
                                    });
                                    Gal.putImage(
                                        widget.heroAnimationTag.toString());
                                    Future.delayed(
                                        const Duration(milliseconds: 500), () {
                                      Navigator.pop(context);
                                    });
                                  },
                                  icon: arrow_down,
                                ),
                                PullDownMenuItem(
                                  itemTheme: const PullDownMenuItemTheme(),
                                  onTap: widget.onDeletePressed,
                                  title: 'Delete',
                                  isDestructive: true,
                                  icon: CupertinoIcons.delete,
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  void openFullScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation1, animation2) => FadeTransition(
          opacity: animation1,
          child: WidgetZoomFullscreen(
            onDeletePressed: widget.onDeletePressed,
            onSharePressed: widget.onSharePressed,
            zoomWidget: widget.zoomWidget,
            minScale: 1,
            maxScale: 4,
            heroAnimationTag: widget.heroAnimationTag,
            fullScreenDoubleTapZoomScale: widget.fullScreenDoubleTapZoomScale,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
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

Color color(context, Color dark, Color light) =>
    Theme.of(context).brightness == Brightness.light ? light : dark;
