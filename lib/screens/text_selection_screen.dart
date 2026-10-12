import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/localization/app_strings.dart';
import '../core/utils/image_utils.dart';
import '../data/models/detected_text_block.dart';
import '../providers/gemini_provider.dart';
import '../providers/image_provider.dart';
import '../providers/language_provider.dart';
import '../providers/text_selection_provider.dart';
import 'result_screen.dart';

enum SelectionTool {
  rectangle,
  freeform,
}

class TextSelectionScreen extends ConsumerStatefulWidget {
  const TextSelectionScreen({super.key});

  @override
  ConsumerState<TextSelectionScreen> createState() =>
      _TextSelectionScreenState();
}

class _TextSelectionScreenState extends ConsumerState<TextSelectionScreen> {
  Size? _imageSize;
  SelectionTool? _activeTool; // null = pan/zoom mode by default

  // Real-time drag coordinates (for rectangle mode)
  Offset? _dragStart;
  Offset? _dragCurrent;

  // Real-time points for freeform / lasso mode
  List<Offset> _freeformPoints = [];
  List<Offset>? _confirmedFreeformPoints;

  // Final selected normalized rectangle (0.0 to 1.0)
  Rect? _selectedNormalizedRect;

  // Loading state when analyzing the selected cropped area
  bool _isAnalyzingCrop = false;
  String _cropStatus = '';

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  void _loadImageSize() {
    final imageFile = ref.read(imageProvider);
    if (imageFile == null) return;

    final ImageProvider provider = kIsWeb
        ? NetworkImage(imageFile.path)
        : FileImage(File(imageFile.path));

    final ImageStream stream = provider.resolve(const ImageConfiguration());

    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      }),
    );
  }

  /// Analyze text from auto-detected block
  void _handleBlockTranslation(String text) {
    final image = ref.read(imageProvider);
    if (image != null) {
      ref
          .read(geminiNotifierProvider.notifier)
          .translateSelectedBlock(image, text);
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const ResultScreen()));
    }
  }

  /// Analyze cropped region directly with Gemini (Instant OCR + Translation)
  Future<void> _handleCropTranslation(Rect normRect) async {
    final imageFile = ref.read(imageProvider);
    if (imageFile == null) return;

    final l10n = ref.read(l10nProvider);
    setState(() {
      _isAnalyzingCrop = true;
      _cropStatus = l10n.analyzingCropStatus;
    });

    try {
      final Uint8List cropBytes = await ImageUtils.cropNormalizedArea(
        imageFile,
        normXmin: normRect.left,
        normYmin: normRect.top,
        normXmax: normRect.right,
        normYmax: normRect.bottom,
      );

      if (!mounted) return;

      await ref
          .read(geminiNotifierProvider.notifier)
          .translateCroppedArea(imageFile, cropBytes);

      if (!mounted) return;
      setState(() {
        _isAnalyzingCrop = false;
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            croppedImageBytes: cropBytes,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzingCrop = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('영역 분석 중 오류가 발생했습니다: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = ref.watch(imageProvider);
    final selectionState = ref.watch(textSelectionProvider);
    final activeLang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);

    if (imageFile == null) {
      return Scaffold(body: Center(child: Text(l10n.noPhotoSelected)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.textSelectionTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            ref.read(textSelectionProvider.notifier).clear();
            ref.read(imageProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Auto Detect All Button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedNormalizedRect = null;
              });
              ref.read(textSelectionProvider.notifier).detectBlocks(imageFile);
            },
            icon: const Icon(Icons.document_scanner_rounded, size: 18),
            label: Text(l10n.autoDetectAllBtn),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // If auto detection is currently running, show loading state
          if (selectionState.blocks.isLoading)
            _BuildDetectionLoadingState(imagePath: imageFile.path)
          else if (selectionState.blocks.hasError)
            _BuildErrorState(
              errorMessage: selectionState.blocks.error.toString(),
              onRetry: () =>
                  ref.read(textSelectionProvider.notifier).detectBlocks(imageFile),
            )
          else
            _buildInteractiveContent(
              context,
              imageFile,
              selectionState,
              activeLang,
              colorScheme,
              theme,
              l10n,
            ),

          // Loading overlay when analyzing selected crop
          if (_isAnalyzingCrop)
            _buildCropAnalyzingOverlay(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildInteractiveContent(
    BuildContext context,
    XFile imageFile,
    TextSelectionState selectionState,
    LanguageMode activeLang,
    ColorScheme colorScheme,
    ThemeData theme,
    AppStrings l10n,
  ) {
    final List<DetectedTextBlock> blocks =
        selectionState.blocks.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Switcher & Instruction Bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: colorScheme.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              // 2-Tool Toggle Buttons: [Rectangle] & [Freeform]
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTogglePill(
                      title: l10n.rectDragModeTitle,
                      icon: Icons.crop_square_rounded,
                      isActive: _activeTool == SelectionTool.rectangle,
                      onTap: () {
                        setState(() {
                          if (_activeTool == SelectionTool.rectangle) {
                            _activeTool = null; // Toggle OFF -> Revert to pan/zoom
                          } else {
                            _activeTool = SelectionTool.rectangle;
                            _freeformPoints = [];
                          }
                        });
                      },
                      colorScheme: colorScheme,
                    ),
                    _buildTogglePill(
                      title: l10n.freeformDragModeTitle,
                      icon: Icons.gesture_rounded,
                      isActive: _activeTool == SelectionTool.freeform,
                      onTap: () {
                        setState(() {
                          if (_activeTool == SelectionTool.freeform) {
                            _activeTool = null; // Toggle OFF -> Revert to pan/zoom
                          } else {
                            _activeTool = SelectionTool.freeform;
                            _dragStart = null;
                            _dragCurrent = null;
                          }
                        });
                      },
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _activeTool == null
                          ? Icons.pan_tool_rounded
                          : (_activeTool == SelectionTool.rectangle
                              ? Icons.crop_square_rounded
                              : Icons.gesture_rounded),
                      size: 15,
                      color: _activeTool == null
                          ? colorScheme.primary
                          : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _activeTool == null
                            ? l10n.defaultPanZoomInstruction
                            : (_activeTool == SelectionTool.freeform
                                ? l10n.freeformDragInstruction
                                : l10n.rectDragInstruction),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Interactive Image Canvas
        Expanded(
          child: _imageSize == null
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double scaleX =
                        constraints.maxWidth / _imageSize!.width;
                    final double scaleY =
                        constraints.maxHeight / _imageSize!.height;
                    final double scale =
                        scaleX < scaleY ? scaleX : scaleY;

                    final renderedWidth = _imageSize!.width * scale;
                    final renderedHeight = _imageSize!.height * scale;

                    return InteractiveViewer(
                      clipBehavior: Clip.hardEdge,
                      minScale: 1.0,
                      maxScale: 6.0,
                      panEnabled: _activeTool == null,
                      scaleEnabled: _activeTool == null,
                      boundaryMargin: const EdgeInsets.all(80),
                      child: Center(
                        child: SizedBox(
                          width: renderedWidth,
                          height: renderedHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. The Menu Image
                              Positioned.fill(
                                child: kIsWeb
                                    ? Image.network(
                                        imageFile.path,
                                        fit: BoxFit.fill,
                                      )
                                    : Image.file(
                                        File(imageFile.path),
                                        fit: BoxFit.fill,
                                      ),
                              ),

                              // 2. Auto-detected block boxes (if any)
                              ...blocks.map((block) {
                                final double ymin =
                                    block.box2d[0] * renderedHeight / 1000.0;
                                final double xmin =
                                    block.box2d[1] * renderedWidth / 1000.0;
                                final double ymax =
                                    block.box2d[2] * renderedHeight / 1000.0;
                                final double xmax =
                                    block.box2d[3] * renderedWidth / 1000.0;

                                final double boxWidth =
                                    (xmax - xmin).clamp(4.0, renderedWidth);
                                final double boxHeight =
                                    (ymax - ymin).clamp(4.0, renderedHeight);
                                final double left =
                                    xmin.clamp(0.0, renderedWidth - boxWidth);
                                final double top =
                                    ymin.clamp(0.0, renderedHeight - boxHeight);

                                final isSelected = selectionState.selectedBlocks
                                    .contains(block);

                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: boxWidth,
                                  height: boxHeight,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _activeTool == null
                                        ? () {
                                            ref
                                                .read(
                                                  textSelectionProvider
                                                      .notifier,
                                                )
                                                .selectBlock(block);
                                            HapticFeedback.selectionClick();
                                          }
                                        : null,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colorScheme.primary
                                                .withValues(alpha: 0.28)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : Colors.amber.shade700,
                                          width: isSelected ? 2.5 : 1.5,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // 3. Real-time Live Freeform Drawing
                              if (_freeformPoints.isNotEmpty)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _FreeformPainter(
                                      points: _freeformPoints,
                                      color: Colors.amber.shade700,
                                      isLive: true,
                                    ),
                                  ),
                                ),

                              // 4. Confirmed Freeform Shape Highlight
                              if (_confirmedFreeformPoints != null &&
                                  _confirmedFreeformPoints!.isNotEmpty)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _FreeformPainter(
                                      points: _confirmedFreeformPoints!,
                                      color: Colors.amber.shade700,
                                      isLive: false,
                                    ),
                                  ),
                                ),

                              // 5. Live Drag Bounding Box (Rectangle Mode)
                              if (_dragStart != null && _dragCurrent != null)
                                _buildLiveDragBox(
                                  _dragStart!,
                                  _dragCurrent!,
                                  colorScheme,
                                ),

                              // 6. Confirmed Selection Box (with handles)
                              if (_selectedNormalizedRect != null)
                                _buildConfirmedSelectionBox(
                                  _selectedNormalizedRect!,
                                  renderedWidth,
                                  renderedHeight,
                                  colorScheme,
                                  isFromFreeform:
                                      _confirmedFreeformPoints != null,
                                ),

                              // 7. Transparent Touch Listener Layer (Active only when a tool is selected)
                              if (_activeTool != null)
                                Positioned.fill(
                                  child: Listener(
                                    behavior: HitTestBehavior.translucent,
                                    onPointerDown: (event) {
                                      final localPos = event.localPosition;
                                      if (_activeTool ==
                                          SelectionTool.rectangle) {
                                        setState(() {
                                          _dragStart = localPos;
                                          _dragCurrent = localPos;
                                          _selectedNormalizedRect = null;
                                          _confirmedFreeformPoints = null;
                                        });
                                        ref
                                            .read(textSelectionProvider.notifier)
                                            .clear();
                                      } else if (_activeTool ==
                                          SelectionTool.freeform) {
                                        setState(() {
                                          _freeformPoints = [localPos];
                                          _selectedNormalizedRect = null;
                                          _confirmedFreeformPoints = null;
                                        });
                                        ref
                                            .read(textSelectionProvider.notifier)
                                            .clear();
                                      }
                                    },
                                    onPointerMove: (event) {
                                      final localPos = event.localPosition;
                                      if (_activeTool ==
                                              SelectionTool.rectangle &&
                                          _dragStart != null) {
                                        setState(() {
                                          _dragCurrent = localPos;
                                        });
                                      } else if (_activeTool ==
                                          SelectionTool.freeform) {
                                        setState(() {
                                          _freeformPoints.add(localPos);
                                        });
                                      }
                                    },
                                    onPointerUp: (event) {
                                      if (_activeTool ==
                                              SelectionTool.rectangle &&
                                          _dragStart != null &&
                                          _dragCurrent != null) {
                                        final double left = math.min(
                                          _dragStart!.dx,
                                          _dragCurrent!.dx,
                                        );
                                        final double right = math.max(
                                          _dragStart!.dx,
                                          _dragCurrent!.dx,
                                        );
                                        final double top = math.min(
                                          _dragStart!.dy,
                                          _dragCurrent!.dy,
                                        );
                                        final double bottom = math.max(
                                          _dragStart!.dy,
                                          _dragCurrent!.dy,
                                        );

                                        // Ensure minimum drag size (at least 15x15 px)
                                        if ((right - left) > 15 &&
                                            (bottom - top) > 15) {
                                          setState(() {
                                            _selectedNormalizedRect =
                                                Rect.fromLTRB(
                                              (left / renderedWidth)
                                                  .clamp(0.0, 1.0),
                                              (top / renderedHeight)
                                                  .clamp(0.0, 1.0),
                                              (right / renderedWidth)
                                                  .clamp(0.0, 1.0),
                                              (bottom / renderedHeight)
                                                  .clamp(0.0, 1.0),
                                            );
                                            _confirmedFreeformPoints = null;
                                          });
                                          HapticFeedback.selectionClick();
                                        } else {
                                          // Tap on block handling
                                          for (final block in blocks) {
                                            final double bxMin =
                                                block.box2d[1] *
                                                    renderedWidth /
                                                    1000.0;
                                            final double byMin =
                                                block.box2d[0] *
                                                    renderedHeight /
                                                    1000.0;
                                            final double bxMax =
                                                block.box2d[3] *
                                                    renderedWidth /
                                                    1000.0;
                                            final double byMax =
                                                block.box2d[2] *
                                                    renderedHeight /
                                                    1000.0;
                                            if (left >= bxMin &&
                                                left <= bxMax &&
                                                top >= byMin &&
                                                top <= byMax) {
                                              ref
                                                  .read(
                                                    textSelectionProvider
                                                        .notifier,
                                                  )
                                                  .selectBlock(block);
                                              HapticFeedback.selectionClick();
                                              break;
                                            }
                                          }
                                        }
                                        setState(() {
                                          _dragStart = null;
                                          _dragCurrent = null;
                                        });
                                      } else if (_activeTool ==
                                              SelectionTool.freeform &&
                                          _freeformPoints.length >= 3) {
                                        double minX = _freeformPoints.first.dx;
                                        double maxX = _freeformPoints.first.dx;
                                        double minY = _freeformPoints.first.dy;
                                        double maxY = _freeformPoints.first.dy;

                                        for (final pt in _freeformPoints) {
                                          minX = math.min(minX, pt.dx);
                                          maxX = math.max(maxX, pt.dx);
                                          minY = math.min(minY, pt.dy);
                                          maxY = math.max(maxY, pt.dy);
                                        }

                                        if ((maxX - minX) > 15 &&
                                            (maxY - minY) > 15) {
                                          setState(() {
                                            _selectedNormalizedRect =
                                                Rect.fromLTRB(
                                              (minX / renderedWidth)
                                                  .clamp(0.0, 1.0),
                                              (minY / renderedHeight)
                                                  .clamp(0.0, 1.0),
                                              (maxX / renderedWidth)
                                                  .clamp(0.0, 1.0),
                                              (maxY / renderedHeight)
                                                  .clamp(0.0, 1.0),
                                            );
                                            _confirmedFreeformPoints =
                                                List.from(_freeformPoints);
                                          });
                                          HapticFeedback.selectionClick();
                                        }
                                        setState(() {
                                          _freeformPoints = [];
                                        });
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Bottom Action Card
        _buildBottomCard(
          context,
          selectionState,
          colorScheme,
          theme,
          l10n,
          activeLang,
        ),
      ],
    );
  }

  Widget _buildTogglePill({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: colorScheme.onPrimary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Live dragging rectangle while finger is on the screen
  Widget _buildLiveDragBox(
    Offset start,
    Offset current,
    ColorScheme colorScheme,
  ) {
    final double left = math.min(start.dx, current.dx);
    final double top = math.min(start.dy, current.dy);
    final double width = (start.dx - current.dx).abs();
    final double height = (start.dy - current.dy).abs();

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.amber.shade700,
                width: 2.2,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.22),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Starting point indicator pin (Top-left / Press Point)
          Positioned(
            left: (start.dx <= current.dx) ? -4 : null,
            right: (start.dx > current.dx) ? -4 : null,
            top: (start.dy <= current.dy) ? -4 : null,
            bottom: (start.dy > current.dy) ? -4 : null,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          // Current drag finger pin
          Positioned(
            left: (current.dx < start.dx) ? -5 : null,
            right: (current.dx >= start.dx) ? -5 : null,
            top: (current.dy < start.dy) ? -5 : null,
            bottom: (current.dy >= start.dy) ? -5 : null,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade700, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmed selection box with glowing border and corner handles
  Widget _buildConfirmedSelectionBox(
    Rect normRect,
    double renderedWidth,
    double renderedHeight,
    ColorScheme colorScheme, {
    bool isFromFreeform = false,
  }) {
    final double left = normRect.left * renderedWidth;
    final double top = normRect.top * renderedHeight;
    final double width = normRect.width * renderedWidth;
    final double height = normRect.height * renderedHeight;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isFromFreeform
                  ? Colors.transparent
                  : colorScheme.primary.withValues(alpha: 0.20),
              border: Border.all(
                color: Colors.amber.shade700,
                width: isFromFreeform ? 1.8 : 2.5,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // 4 Corner handles for professional touch
          _buildHandle(top: -4, left: -4),
          _buildHandle(top: -4, right: -4),
          _buildHandle(bottom: -4, left: -4),
          _buildHandle(bottom: -4, right: -4),
        ],
      ),
    );
  }

  Widget _buildHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.amber.shade800, width: 2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildBottomCard(
    BuildContext context,
    TextSelectionState selectionState,
    ColorScheme colorScheme,
    ThemeData theme,
    AppStrings l10n,
    LanguageMode activeLang,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Case 1: Drag Area selected
            if (_selectedNormalizedRect != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '메뉴 영역 선택 완료',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedNormalizedRect = null;
                        _confirmedFreeformPoints = null;
                        _dragStart = null;
                        _dragCurrent = null;
                        _freeformPoints = [];
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('초기화'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _handleCropTranslation(
                  _selectedNormalizedRect!,
                ),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  l10n.analyzeSelectedAreaBtn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ]
            // Case 2: Auto-detected block selected
            else if (selectionState.selectedBlocks.isNotEmpty) ...[
              Text(
                l10n.selectedTextLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selectionState.combinedSelectedText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _handleBlockTranslation(
                  selectionState.combinedSelectedText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.viewGuideBtn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
            // Case 3: No selection yet
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: colorScheme.onSurface.withValues(alpha: 0.03),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.dragAreaInstruction,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Fullscreen modal overlay while analyzing cropped region
  Widget _buildCropAnalyzingOverlay(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'AI 메뉴 분석 중...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cropStatus,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildDetectionLoadingState extends ConsumerWidget {
  final String? imagePath;

  const _BuildDetectionLoadingState({this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeLang = ref.watch(languageProvider);
    final selectionState = ref.watch(textSelectionProvider);
    final l10n = ref.watch(l10nProvider);

    String statusTitle = l10n.detectingText(activeLang.name);
    String statusDesc = selectionState.loadingStatus.isNotEmpty
        ? selectionState.loadingStatus
        : l10n.detectionWaitDesc;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: kIsWeb
                  ? Image.network(imagePath!, fit: BoxFit.cover)
                  : Image.file(File(imagePath!), fit: BoxFit.cover),
            ),
          ),
        Container(color: colorScheme.surface.withValues(alpha: 0.85)),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                statusTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusDesc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuildErrorState extends ConsumerWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _BuildErrorState({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = ref.watch(l10nProvider);
    final cleanMessage = errorMessage.replaceAll('Exception:', '').trim();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.textDetectionError,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cleanMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retryBtn),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeformPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final bool isLive;

  _FreeformPainter({
    required this.points,
    required this.color,
    required this.isLive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = isLive ? 3.0 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isLive ? 0.16 : 0.20)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (points.length >= 3) {
      final closedPath = Path.from(path)..close();
      canvas.drawPath(closedPath, fillPaint);
    }

    canvas.drawPath(path, strokePaint);

    if (isLive && points.isNotEmpty) {
      final last = points.last;
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(last, 10, glowPaint);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(last, 4.5, dotPaint);

      final dotBorderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(last, 4.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FreeformPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.isLive != isLive ||
        oldDelegate.color != color;
  }
}
