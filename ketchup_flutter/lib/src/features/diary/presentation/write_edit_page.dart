import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/dialogs/ketchup_ios_alert_dialog.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';
import 'package:ketchup_flutter/src/core/share/instagram_story_share.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/write_draft_storage.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_providers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum WriteEditMode { view, create, edit }

class WriteEditArgs {
  const WriteEditArgs.create()
      : mode = WriteEditMode.create,
        entry = null;
  const WriteEditArgs.view({required this.entry}) : mode = WriteEditMode.view;
  const WriteEditArgs.edit({required this.entry}) : mode = WriteEditMode.edit;

  final WriteEditMode mode;
  final DiaryEntry? entry;
}

/// iOS `WriteView.xib` 레이아웃 (패턴 배경, 흰 카드, 상단 닫기/액션, 하단 수정·삭제).
class WriteEditPage extends ConsumerStatefulWidget {
  const WriteEditPage({super.key, required this.args});

  static const String routeName = '/write-edit';
  final WriteEditArgs args;

  @override
  ConsumerState<WriteEditPage> createState() => _WriteEditPageState();
}

class _WriteEditPageState extends ConsumerState<WriteEditPage> with WidgetsBindingObserver {
  static const String _iosPlaceholder = '내용을 입력하세요';
  static const Color _textActive = Color(0xFF303030);
  static const Color _textHint = Color(0xFF868686);
  /// WriteView.xib `8pf-FS-Voz` 배경과 동일 (1, 0.9686, 0.7961)
  static const Color _photoEmptyBg = Color(0xFFFFF7CB);
  static const Color _divider = Color(0xFFD0D0D0);
  /// 캘린더 다이얼로그 테두리 (인스타 계열 핑크)
  static const Color _calendarPinkBorder = Color(0xFFE4405F);

  final GlobalKey _cardCaptureKey = GlobalKey();
  late final ScrollController _writeScrollController;

  late WriteEditMode _mode;
  late TextEditingController _textController;
  late DateTime _selectedDate;
  late int _defaultImage;
  late String _initialText;
  late DateTime _initialDate;
  late int _initialDefaultImage;
  String? _imagePath;
  String? _initialImagePath;
  bool _iosPlaceholderActive = false;
  bool _imageDirty = false;
  /// 오른쪽으로 쓸어 닫기(iOS 뒤로 제스처) — 느린 스와이프도 인식
  double _horizontalDismissDx = 0;
  /// 줄바꿈(\n)으로 줄 수가 늘 때만 스크롤 보정
  late int _writeLineCount;
  Timer? _draftSaveTimer;

  String _formatDate(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _sameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _writeScrollController = ScrollController();
    _mode = widget.args.mode;
    final DiaryEntry? entry = widget.args.entry;
    if (_mode == WriteEditMode.create) {
      _textController = TextEditingController(text: _iosPlaceholder);
      _iosPlaceholderActive = true;
      _selectedDate = DateTime.now();
      // iOS 기본 이미지는 고정입니다. (랜덤 제거)
      _defaultImage = 0;
    } else {
      _textController = TextEditingController(text: entry?.text ?? '');
      _selectedDate = entry?.date ?? DateTime.now();
      _defaultImage = entry?.defaultImage ?? 0;
      _defaultImage = _defaultImage.clamp(0, 2);
    }
    _initialText = _textController.text;
    _initialDate = _selectedDate;
    _initialDefaultImage = _defaultImage;
    _imagePath = entry?.imagePath;
    _initialImagePath = entry?.imagePath;
    _textController.addListener(_onTextChanged);
    _writeLineCount = _countWriteLines(_textController.text);
    if (_mode == WriteEditMode.create) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_tryLoadComposeDraft());
      });
    }
  }

  static int _countWriteLines(String t) {
    if (t.isEmpty) {
      return 1;
    }
    return t.split('\n').length;
  }

  void _onTextChanged() {
    if (_iosPlaceholderActive && _textController.text != _iosPlaceholder) {
      setState(() {
        _iosPlaceholderActive = false;
        _writeLineCount = _countWriteLines(_textController.text);
      });
      _schedulePersistComposeDraft();
      return;
    }
    if (_editable) {
      final int prev = _writeLineCount;
      final int n = _countWriteLines(_textController.text);
      // 줄 수만 바뀔 때는 setState 하지 않음 → 글자 입력 시 패딩/레이아웃 점프 방지
      _writeLineCount = n;
      if (n > prev) {
        final int delta = n - prev;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _bumpWriteScrollByLines(context, delta);
        });
      }
      _schedulePersistComposeDraft();
    }
  }

  void _schedulePersistComposeDraft() {
    if (_mode != WriteEditMode.create) {
      return;
    }
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || _mode != WriteEditMode.create) {
        return;
      }
      unawaited(
        WriteDraftStorage.save(
          text: _textController.text,
          date: _selectedDate,
          defaultImage: _defaultImage,
          imagePath: _imagePath,
          iosPlaceholderActive: _iosPlaceholderActive,
        ),
      );
    });
  }

  Future<void> _tryLoadComposeDraft() async {
    if (_mode != WriteEditMode.create || !mounted) {
      return;
    }
    final WriteDraftSnapshot? snap = await WriteDraftStorage.load();
    if (snap == null || !mounted) {
      return;
    }
    // 텍스트를 마지막에 넣어야 함: `text`를 먼저 바꾸면 리스너가 동기 실행되며
    // 그 시점 `_imagePath`가 아직 null이면 디바운스 저장이 이미지 없는 초안으로 덮어씁니다.
    setState(() {
      _iosPlaceholderActive = snap.iosPlaceholderActive;
      _selectedDate = snap.date;
      _defaultImage = snap.defaultImage;
      _imagePath = snap.imagePath;
      _imageDirty = snap.imagePath != null;
      _textController.text = snap.text;
      _writeLineCount = _countWriteLines(_textController.text);
      _initialText = _textController.text;
      _initialDate = _selectedDate;
      _initialDefaultImage = _defaultImage;
      _initialImagePath = _imagePath;
    });
  }

  /// 줄바꿈(\n)마다 스크롤을 한 줄 분량만큼 올려 흰 카드·입력이 키보드에 가리지 않게 함.
  void _bumpWriteScrollByLines(BuildContext context, int deltaLines) {
    if (deltaLines <= 0) {
      return;
    }
    if (!_writeScrollController.hasClients) {
      return;
    }
    final double oneLine = MediaQuery.textScalerOf(context).scale(24);
    final double step = oneLine * deltaLines;
    final ScrollPosition pos = _writeScrollController.position;
    final double next = (pos.pixels + step).clamp(0.0, pos.maxScrollExtent);
    _writeScrollController.animateTo(
      next,
      duration: Duration(milliseconds: (220 + 40 * deltaLines).clamp(220, 420)),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _writeScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_mode == WriteEditMode.create) {
        unawaited(_flushComposeDraftNow());
      }
    }
  }

  Future<void> _flushComposeDraftNow() async {
    if (_mode != WriteEditMode.create) {
      return;
    }
    await WriteDraftStorage.save(
      text: _textController.text,
      date: _selectedDate,
      defaultImage: _defaultImage,
      imagePath: _imagePath,
      iosPlaceholderActive: _iosPlaceholderActive,
    );
  }

  bool get _editable => _mode == WriteEditMode.create || _mode == WriteEditMode.edit;
  bool get _isView => _mode == WriteEditMode.view;

  String _textForSave() {
    if (_mode == WriteEditMode.create && _iosPlaceholderActive) {
      return '';
    }
    return _textController.text.trim();
  }

  bool get _isDirty {
    if (_isView) {
      return false;
    }
    if (_imageDirty) {
      return true;
    }
    return _textForSave() != _initialText.trim() ||
        !_sameCalendarDate(_selectedDate, _initialDate) ||
        _defaultImage != _initialDefaultImage ||
        _imagePath != _initialImagePath;
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.sizeOf(context).width;
    final double cardW = (screenW - 50).clamp(260.0, 400.0);
    final double photoSize = (cardW - 40).clamp(200.0, 285.0);
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // 줄 수에 따른 동적 하단 패딩 제거 — 엔터 시에만 스크롤 보정(_bumpWriteScrollByLines)
    final double keyboardExtraPad =
        (keyboardInset > 0 && _editable) ? 120.0 : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        await _finishCloseAfterConfirmIfOk();
      },
      child: GestureDetector(
        // deferToChild면 스크롤/입력 영역에서 수평 제스처가 상위로 잘 안 올라옴 → translucent
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          _horizontalDismissDx = 0;
        },
        onHorizontalDragUpdate: (DragUpdateDetails d) {
          if (d.delta.dx > 0) {
            _horizontalDismissDx += d.delta.dx;
          }
        },
        onHorizontalDragCancel: () {
          _horizontalDismissDx = 0;
        },
        onHorizontalDragEnd: (DragEndDetails details) {
          final double? v = details.primaryVelocity;
          final bool fastSwipe = v != null && v > 280;
          final bool longSwipe = _horizontalDismissDx > 64;
          _horizontalDismissDx = 0;
          if (fastSwipe || longSwipe) {
            unawaited(_onClosePressed(context));
          }
        },
        child: Scaffold(
        backgroundColor: Colors.transparent,
        // true면 키보드와 사이에 테마 배경(검정/회색)이 보이는 경우가 있어,
        // 패턴 배경이 키보드 뒤까지 이어지도록 리사이즈 끔 + 스크롤 패딩으로 대응
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(KetchupIosAssets.bgPattern),
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              alignment: Alignment.topLeft,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Row(
                    children: <Widget>[
                      _roundImageButton(KetchupIosAssets.btnHdPrev, () => _onClosePressed(context)),
                      const Spacer(),
                      _roundImageButton(
                        _isView ? KetchupIosAssets.writeBtnHdInsta : KetchupIosAssets.btnHdWrite,
                        () => _isView ? _onInstaPressed() : _save(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      controller: _writeScrollController,
                      padding: EdgeInsets.fromLTRB(
                        25,
                        20,
                        25,
                        24 + keyboardInset + keyboardExtraPad,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          RepaintBoundary(
                            key: _cardCaptureKey,
                            child: _whiteCard(context, cardW, photoSize),
                          ),
                          if (_editable) ...<Widget>[
                            const SizedBox(height: 0),
                            _dateRow(context, cardW, photoSize),
                          ],
                          if (_isView) ...<Widget>[
                            const SizedBox(height: 20),
                            _viewBottomActions(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _whiteCard(BuildContext context, double cardW, double photoSize) {
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
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(
                      color: _photoEmptyBg,
                      child: _buildPhotoFill(photoSize),
                    ),
                    if (_editable)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // 업로드는 유지하되 클릭(잉크) 액션은 제거
                        onTap: _imagePath == null ? _pickImage : null,
                        child: _imagePath == null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(48, 48, 48, 40),
                                  child: Image.asset(
                                    KetchupIosAssets.writeImgUpload,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            : const SizedBox.expand(),
                      ),
                    if (_isView)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openPhotoPreview(context),
                          child: const SizedBox.expand(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            enabled: _editable,
            minLines: 1,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            inputFormatters: const <TextInputFormatter>[_MaxLinesInputFormatter(6)],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: ketchupContentWeight(context),
              color: _editable && _iosPlaceholderActive ? _textHint : _textActive,
            ),
            // Theme의 primary(red) 영향을 받지 않도록 기본 텍스트 컬러로 고정합니다.
            cursorColor: _textActive,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () {
              if (_mode == WriteEditMode.create && _iosPlaceholderActive) {
                _textController.clear();
                setState(() => _iosPlaceholderActive = false);
              }
            },
          ),
          if (_editable) ...<Widget>[
            const SizedBox(height: 12),
            Container(height: 1, width: photoSize, color: _divider),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoFill(double photoSize) {
    // iOS WriteView.xib: create(쓰기) 화면에서는 기본 이미지가 아닌 빈 이미지뷰 배경 + 업로드 아이콘을 보여줍니다.
    // (기본 이미지/def 이미지들은 저장 시점에 확정됩니다.)
    if (_mode == WriteEditMode.create && _imagePath == null) {
      return SizedBox(width: photoSize, height: photoSize);
    }

    if (_imagePath != null) {
      final File f = File(_imagePath!);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.cover, width: photoSize, height: photoSize);
      }
    }
    return Image.asset(
      KetchupIosAssets.imgDefault(_defaultImage),
      fit: BoxFit.cover,
      width: photoSize,
      height: photoSize,
    );
  }

  /// 흰 카드 안 이미지뷰와 가로 폭을 맞춤: 라벨 왼쪽, 날짜 오른쪽.
  Widget _dateRow(BuildContext context, double cardW, double photoSize) {
    final TextStyle labelStyle = TextStyle(
      fontSize: 17,
      height: 1.1,
      color: Colors.black,
      fontWeight: ketchupContentWeight(context),
    );
    final TextStyle dateStyle = TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontWeight: ketchupContentWeight(context),
    );
    return Container(
      width: cardW,
      height: 50,
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: photoSize,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '날짜',
                  maxLines: 1,
                  style: labelStyle,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _pickDate(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Colors.black,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _formatDate(_selectedDate),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: dateStyle,
                          ),
                        ),
                        const SizedBox(width: 2),
                        // 아래향 세모(▼) — 탭 시 캘린더로 날짜 변경
                        Icon(
                          Icons.arrow_drop_down,
                          size: 22,
                          color: Colors.black.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            onPressed: _confirmDelete,
            child: Text(
              '삭제하기',
              style: TextStyle(fontSize: 22, fontWeight: ketchupContentWeight(context), color: Colors.black),
            ),
          ),
          const SizedBox(width: 15),
          TextButton(
            onPressed: () {
              setState(() {
                _mode = WriteEditMode.edit;
                _textController.text = widget.args.entry?.text ?? '';
                _iosPlaceholderActive = false;
                _initialText = _textController.text;
                _initialDate = _selectedDate;
                _initialDefaultImage = _defaultImage;
                _initialImagePath = _imagePath;
                _imageDirty = false;
              });
            },
            child: Text(
              '수정하기',
              style: TextStyle(fontSize: 22, fontWeight: ketchupContentWeight(context), color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundImageButton(String asset, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _finishCloseAfterConfirmIfOk() async {
    final bool hadUnsavedEdits = _isDirty;
    final NavigatorState navigator = Navigator.of(context);
    final bool ok = await _confirmCloseIfDirty();
    if (!context.mounted) {
      return;
    }
    if (ok) {
      // 저장하지 않고 나가기(취소 확인)했을 때만 초안 삭제 — 그냥 닫기만 한 경우(변경 없음)는 유지
      if (_mode == WriteEditMode.create && hadUnsavedEdits) {
        await WriteDraftStorage.clear();
      }
      if (!mounted) {
        return;
      }
      navigator.pop();
    }
  }

  Future<void> _onClosePressed(BuildContext context) async {
    await _finishCloseAfterConfirmIfOk();
  }

  Future<void> _onInstaPressed() async {
    final bool? go = await showKetchupIosConfirmDialog(
      context,
      message: '인스타그램 스토리에\n 공유할까요?',
      leftText: '아니요',
      rightText: '예',
    );
    if (go != true || !mounted) {
      return;
    }
    await _shareCardToInstagramStory();
  }

  /// iOS `Write+func.instreamGo` 와 동일하게 스토리 스티커로 전달. Android 는 공유 시트.
  Future<void> _shareCardToInstagramStory() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      final BuildContext? capCtx = _cardCaptureKey.currentContext;
      final RenderObject? ro = capCtx?.findRenderObject();
      final RenderRepaintBoundary? boundary =
          ro is RenderRepaintBoundary ? ro : null;
      if (boundary == null) {
        _snack('화면을 캡처할 수 없습니다.');
        return;
      }
      final double dpr = MediaQuery.devicePixelRatioOf(context).clamp(2.0, 3.0);
      final ui.Image image = await boundary.toImage(pixelRatio: dpr);
      final ByteData? bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) {
        _snack('이미지를 만들 수 없습니다.');
        return;
      }
      final Uint8List png = bytes.buffer.asUint8List();
      final bool ok = await InstagramStoryShare.shareDiaryCardAsStory(png);
      if (!mounted) {
        return;
      }
      if (Platform.isIOS && !ok) {
        _snack('인스타그램이 설치되어 있지 않거나 공유할 수 없습니다.');
      } else if (Platform.isAndroid && !ok) {
        _snack('공유를 열 수 없습니다.');
      }
    } on MissingFacebookAppIdException catch (e) {
      if (mounted) {
        _snack(e.message);
      }
    } catch (e) {
      if (mounted) {
        _snack('공유 실패: $e');
      }
    }
  }

  void _openPhotoPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final double w = MediaQuery.sizeOf(context).width * 0.92;
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: SizedBox(
            width: w,
            height: w,
            child: InteractiveViewer(
              child: Center(child: _buildPhotoFill(w)),
            ),
          ),
        );
      },
    );
  }

  ThemeData _whiteDatePickerTheme(BuildContext context) {
    final ThemeData base = Theme.of(context);
    const Color white = Colors.white;
    final ColorScheme cs = base.colorScheme.copyWith(
      surface: white,
      surfaceContainerHighest: white,
      onSurface: Colors.black87,
      primary: const Color(0xFF303030),
      onPrimary: Colors.white,
    );
    return base.copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: _calendarPinkBorder, width: 2.5),
        ),
      ),
      colorScheme: cs,
      datePickerTheme: DatePickerThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: Colors.black87,
        headerBackgroundColor: white,
        dayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.disabled)) {
            return Colors.black38;
          }
          if (s.contains(WidgetState.selected)) {
            return const Color(0xFF303030);
          }
          return Colors.black87;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return const Color(0xFF303030);
          }
          return Colors.black87;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.black12;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.transparent;
        }),
        dayShape: WidgetStateProperty.resolveWith<OutlinedBorder?>((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return const CircleBorder(
              side: BorderSide(color: _calendarPinkBorder, width: 2),
            );
          }
          return const CircleBorder();
        }),
        dayOverlayColor: WidgetStateProperty.all(Colors.black12),
        yearForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return const Color(0xFF303030);
          }
          if (s.contains(WidgetState.disabled)) {
            return Colors.black38;
          }
          return Colors.black87;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.transparent;
        }),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.black87),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFF303030)),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: _whiteDatePickerTheme(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
    _schedulePersistComposeDraft();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (picked == null) {
      return;
    }
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory imgDir = Directory(p.join(dir.path, 'ketchup_images'));
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    final String ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final String dest = p.join(imgDir.path, 'img_${DateTime.now().millisecondsSinceEpoch}$ext');
    // iOS 갤러리 임시 경로는 앱 재시작 후 사라질 수 있어 바이트로 문서 폴더에 저장
    final List<int> bytes = await picked.readAsBytes();
    await File(dest).writeAsBytes(bytes);
    setState(() {
      _imagePath = dest;
      _imageDirty = true;
    });
    // 이미지 직후 디스크에 초안을 확정 저장 (프로세스 종료 직전에 Future가 안 돌 수 있음)
    await _flushComposeDraftNow();
    _schedulePersistComposeDraft();
  }

  Future<void> _save() async {
    if (_mode == WriteEditMode.edit) {
      if (!_isDirty) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      final String t = _textForSave();
      if (t.isEmpty) {
        _snack('내용을 입력하세요.');
        return;
      }
      final int? id = widget.args.entry?.id;
      if (id == null) {
        return;
      }
      await ref.read(diaryEntriesProvider.notifier).update(
            id,
            text: t,
            date: _selectedDate,
            defaultImage: _defaultImage,
            imagePath: _imagePath,
          );
      if (mounted) {
        Navigator.of(context).pop(_calendarDayForPop());
      }
      return;
    }

    if (_mode == WriteEditMode.create) {
      String text = _textForSave();
      if (text.isEmpty) {
        _snack('내용을 입력하세요.');
        return;
      }
      // 기본 이미지는 항상 고정입니다.
      final int def = _defaultImage;
      await ref.read(diaryEntriesProvider.notifier).create(
            text: text,
            date: _selectedDate,
            defaultImage: def,
            imagePath: _imagePath,
          );
      await WriteDraftStorage.clear();
      if (mounted) {
        Navigator.of(context).pop(_calendarDayForPop());
      }
    }
  }

  /// 목록에서 저장된 일기가 속한 달로 `PageView`를 맞추기 위해 반환합니다.
  DateTime _calendarDayForPop() {
    final DateTime d = _selectedDate;
    return DateTime(d.year, d.month, d.day);
  }

  Future<void> _confirmDelete() async {
    final bool? ok = await showKetchupIosConfirmDialog(
      context,
      message: '작성된 내용을 삭제할까요?',
      leftText: '아니요',
      rightText: '예',
    );
    if (ok != true) {
      return;
    }
    final int? id = widget.args.entry?.id;
    if (id == null) {
      return;
    }
    await ref.read(diaryEntriesProvider.notifier).delete(id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmCloseIfDirty() async {
    if (_isView) {
      return true;
    }
    // 닫기 팝업은 "텍스트를 작성 중인 경우"에만 노출
    final String current = _textForSave();
    final String initial = _initialText.trim();
    final bool hasTypingText = current.isNotEmpty && current != initial;
    if (!hasTypingText) {
      return true;
    }
    final bool? close = await showKetchupIosConfirmDialog(
      context,
      message: '작성된 내용을  취소할까요?',
      leftText: '아니요',
      rightText: '예',
    );
    return close ?? false;
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}

/// 줄 수를 [maxLines] 로 제한 (6줄 이상 입력·붙여넣기 방지).
class _MaxLinesInputFormatter extends TextInputFormatter {
  const _MaxLinesInputFormatter(this.maxLines);
  final int maxLines;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.split('\n').length > maxLines) {
      return oldValue;
    }
    return newValue;
  }
}
