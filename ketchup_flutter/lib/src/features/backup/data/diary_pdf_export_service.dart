import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_image_paths.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 일기 항목을 쓰기 화면·인스타 공유와 동일한 흰 카드 레이아웃으로 렌더링한 뒤 PNG로 찍어 PDF에 담습니다.
class DiaryPdfExportService {
  DiaryPdfExportService._();

  static const double _cardW = 325;
  static const double _photoSize = 285;

  static Future<File?> exportToPdf({
    required BuildContext context,
    required List<DiaryEntry> entries,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (entries.isEmpty) {
      return null;
    }
    final List<DiaryEntry> sorted = List<DiaryEntry>.from(entries)
      ..sort((DiaryEntry a, DiaryEntry b) {
        final int c = a.date.compareTo(b.date);
        return c != 0 ? c : a.id.compareTo(b.id);
      });

    final int total = sorted.length;
    onProgress?.call(0, total);

    final List<Uint8List> pages = <Uint8List>[];
    for (final DiaryEntry diary in sorted) {
      if (!context.mounted) {
        return null;
      }
      final Uint8List? png = await _captureCardPng(
        context,
        diary,
        diaryCount: total,
      );
      if (png == null) {
        return null;
      }
      pages.add(png);
      onProgress?.call(pages.length, total);
      // toImage·PNG 인코딩이 UI 스레드를 잡고 있어 로티가 멈춘 것처럼 보이지 않도록 한 프레임씩 넘깁니다.
      await Future<void>.delayed(Duration.zero);
    }

    final pw.Document doc = pw.Document();
    for (final Uint8List png in pages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Center(
              child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    // 대용량 PDF 생성 시에도 이벤트 루프에 양보해 로딩 애니메이션이 돌아가게 합니다.
    final Uint8List out = await doc.save(enableEventLoopBalancing: true);
    final Directory dir = await getTemporaryDirectory();
    final String name =
        'ketchup_diary_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(p.join(dir.path, name));
    await file.writeAsBytes(out);
    return file;
  }

  /// 내보내기 개수가 많을수록 해상도·메모리 부담을 줄입니다.
  static double _exportPixelRatio(double deviceDpr, int diaryCount) {
    final double d = deviceDpr.clamp(1.0, 3.0);
    if (diaryCount > 150) {
      return d.clamp(1.0, 1.5);
    }
    if (diaryCount > 80) {
      return d.clamp(1.0, 2.0);
    }
    if (diaryCount > 40) {
      return d.clamp(1.5, 2.5);
    }
    return d.clamp(2.0, 3.0);
  }

  static Future<Uint8List?> _captureCardPng(
    BuildContext context,
    DiaryEntry entry, {
    required int diaryCount,
  }) async {
    final GlobalKey boundaryKey = GlobalKey();
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (BuildContext ctx) {
        return Positioned(
          left: -8000,
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: Theme(
              data: Theme.of(context),
              child: RepaintBoundary(
                key: boundaryKey,
                child: _ExportWhiteCard(
                  entry: entry,
                  cardW: _cardW,
                  photoSize: _photoSize,
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final String? resolved = DiaryImagePaths.resolveDisplay(entry.imagePath);
      if (resolved != null) {
        await precacheImage(FileImage(File(resolved)), context);
      } else {
        final int di = entry.defaultImage.clamp(0, 2);
        await precacheImage(
          AssetImage(KetchupIosAssets.imgDefault(di)),
          context,
        );
      }
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));

      final RenderObject? ro = boundaryKey.currentContext?.findRenderObject();
      final RenderRepaintBoundary? boundary = ro is RenderRepaintBoundary
          ? ro
          : null;
      if (boundary == null) {
        return null;
      }
      final double dpr = _exportPixelRatio(
        MediaQuery.devicePixelRatioOf(context),
        diaryCount,
      );
      final ui.Image image = await boundary.toImage(pixelRatio: dpr);
      final ByteData? bytes = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      return bytes?.buffer.asUint8List();
    } finally {
      overlayEntry.remove();
    }
  }
}

class _ExportWhiteCard extends StatelessWidget {
  const _ExportWhiteCard({
    required this.entry,
    required this.cardW,
    required this.photoSize,
  });

  final DiaryEntry entry;
  final double cardW;
  final double photoSize;

  static const Color _photoEmptyBg = Color(0xFFFFF7CB);

  @override
  Widget build(BuildContext context) {
    final String? resolved = DiaryImagePaths.resolveDisplay(entry.imagePath);
    final int di = entry.defaultImage.clamp(0, 2);

    return Container(
      width: cardW,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: photoSize,
                height: photoSize,
                child: ColoredBox(
                  color: _photoEmptyBg,
                  child: _buildPhoto(resolved, di),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            entry.text,
            textAlign: TextAlign.center,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: ketchupContentWeight(context),
              color: const Color(0xFF303030),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String? resolved, int defaultImage) {
    if (resolved != null) {
      final File f = File(resolved);
      if (f.existsSync()) {
        return Image.file(
          f,
          fit: BoxFit.cover,
          width: photoSize,
          height: photoSize,
        );
      }
    }
    return Image.asset(
      KetchupIosAssets.imgDefault(defaultImage),
      fit: BoxFit.cover,
      width: photoSize,
      height: photoSize,
    );
  }
}
