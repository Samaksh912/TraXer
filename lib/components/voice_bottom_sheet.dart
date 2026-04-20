import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/isar_expense.dart';
import '../models/voice_parse_result.dart';
import '../services/voice_parse_service.dart';
import 'expensedialog.dart';

/// Shows the animated mic overlay, captures speech, parses & auto-saves.
Future<void> showVoiceBottomSheet(
  BuildContext context, {
  required Future<void> Function(IsarExpense) onSave,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VoiceBottomSheet(onSave: onSave),
  );
}

// ---------------------------------------------------------------------------

enum _MicState { initializing, listening, processing, error }

class VoiceBottomSheet extends StatefulWidget {
  final Future<void> Function(IsarExpense) onSave;

  const VoiceBottomSheet({super.key, required this.onSave});

  @override
  State<VoiceBottomSheet> createState() => _VoiceBottomSheetState();
}

class _VoiceBottomSheetState extends State<VoiceBottomSheet>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();

  _MicState _micState = _MicState.initializing;
  String _transcript = '';
  String _statusText = 'Initializing…';

  /// Guard: prevents processing the same transcript twice if status
  /// callbacks fire multiple times before we close the sheet.
  bool _hasProcessed = false;

  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initAndListen();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Initialise then immediately start listening
  // ---------------------------------------------------------------------------

  Future<void> _initAndListen() async {
    // 1. Microphone permission
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      _setError('Microphone permission denied');
      return;
    }

    // 2. Initialise speech engine
    final available = await _speech.initialize(
      onError: (err) {
        // Only show error if we haven't already processed
        if (!_hasProcessed && mounted) _setError('Recognition error: ${err.errorMsg}');
      },
      // Status callback is informational only — we never process here
      // because 'done' fires BEFORE the final result arrives.
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' && _micState == _MicState.listening) {
          // Engine stopped on its own (e.g. silence timeout) — process whatever we have
          _onEngineStop();
        }
      },
    );

    if (!mounted) return;
    if (!available) {
      _setError('Speech recognition is not available on this device');
      return;
    }

    // 3. Small delay so the audio subsystem is fully ready before we start
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    _startListening();
  }

  // ---------------------------------------------------------------------------
  // Start listening
  // ---------------------------------------------------------------------------

  void _startListening() {
    if (_hasProcessed) return;
    setState(() {
      _micState = _MicState.listening;
      _transcript = '';
      _statusText = 'Listening…';
    });
    _pulseController.repeat(reverse: true);

    _speech.listen(
      onResult: (result) {
        if (!mounted || _hasProcessed) return;
        setState(() {
          _transcript = result.recognizedWords;
        });

        // Only process on the FINAL confirmed result, not partials
        if (result.finalResult && _transcript.trim().isNotEmpty) {
          _processTranscript();
        }
      },
      // Long enough for natural speech with pauses
      listenFor: const Duration(seconds: 60),
      // 4 seconds of silence before auto-stopping
      pauseFor: const Duration(seconds: 4),
      // No locale forcing — use device default for maximum reliability
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        // Dictation mode keeps mic open across natural pauses
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  // Called when the engine auto-stops (silence timeout) without a final result
  void _onEngineStop() {
    if (_hasProcessed) return;
    if (_transcript.trim().isEmpty) {
      _setError('Nothing heard — tap the mic and try again');
    } else {
      _processTranscript();
    }
  }

  // User taps the mic to stop manually
  void _stopListening() {
    if (_hasProcessed) return;
    _speech.stop();
    if (_transcript.trim().isEmpty) {
      _setError('Nothing heard — tap the mic and try again');
    } else {
      _processTranscript();
    }
  }

  Future<void> _processTranscript() async {
    if (_hasProcessed) return; // double-fire guard
    _hasProcessed = true;

    if (!mounted) return;
    setState(() {
      _micState = _MicState.processing;
      _statusText = 'Adding…';
    });
    _pulseController.stop();

    // Local NLP — instant, no network
    final result = VoiceParseService.parse(_transcript);

    if (!mounted) return;

    if (result.amount <= 0) {
      // Could not extract amount — open full edit dialog for manual entry
      context.pop();
      _showEditDialog(result);
      return;
    }

    // Auto-save immediately
    try {
      await widget.onSave(result.toIsarExpense());
    } catch (_) {
      if (mounted) _setError('Failed to save — please try again');
      return;
    }

    if (!mounted) return;

    // Close the voice sheet
    context.pop();

    // Show a brief success snackbar
    final isExpense = result.type == TransactionType.expense;
    final accentColor = isExpense ? const Color(0xFFFB1D55) : const Color(0xFF1DFBA5);
    final typeLabel = isExpense ? 'Expense' : 'Income';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF192540),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$typeLabel added!',
                    style: const TextStyle(
                      color: Color(0xFFDEE5FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${result.title} · ₹${result.amount.toStringAsFixed(0)} · ${result.category}',
                    style: const TextStyle(
                      color: Color(0xFFA3AAC4),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(VoiceParseResult result) {
    showDialog(
      context: context,
      builder: (_) => AddExpenseDialog(
        onAddExpense: widget.onSave,
        draft: result.toIsarExpense(),
      ),
    );
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _hasProcessed = false; // allow retry
      _micState = _MicState.error;
      _statusText = msg;
    });
    _pulseController.stop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isInitializing = _micState == _MicState.initializing;
    final isListening = _micState == _MicState.listening;
    final isProcessing = _micState == _MicState.processing;
    final isError = _micState == _MicState.error;

    final micColor = isError
        ? const Color(0xFFFB1D55)
        : isListening
            ? const Color(0xFF1DFBA5)
            : isProcessing
                ? const Color(0xFF5B8EFF)
                : const Color(0xFF5B8EFF);

    // Clamp to screen height so it never overflows on small devices
    final sheetHeight = (MediaQuery.of(context).size.height * 0.58).clamp(380.0, 480.0);

    return SizedBox(
      height: sheetHeight,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1524),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF40485D),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Label
          const Text(
            'VOICE INPUT',
            style: TextStyle(
              color: Color(0xFFA3AAC4),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),

          // Mic button — fixed 180×180 so layout never shifts
          GestureDetector(
            onTap: isListening
                ? _stopListening
                : (isInitializing || isProcessing) ? null : _startListening,
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Expanding wave ring — always in tree, opacity drives visibility
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      final t = _waveController.value;
                      final ringOpacity = isListening ? (1 - t) * 0.45 : 0.0;
                      final ringSize = 120.0 + 60 * t;
                      return Center(
                        child: Container(
                          width: ringSize,
                          height: ringSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: micColor.withValues(alpha: ringOpacity),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Pulse scale — Transform has zero layout impact
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isListening ? _pulseAnim.value : 1.0,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: micColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: micColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: isProcessing || isInitializing
                          ? Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(micColor),
                                ),
                              ),
                            )
                          : Icon(
                              isListening ? Icons.stop_rounded : Icons.mic_rounded,
                              color: micColor,
                              size: 40,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status text
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isError ? const Color(0xFFFB1D55) : const Color(0xFFA3AAC4),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Live transcript — fixed height so sheet doesn't bounce
          SizedBox(
            height: 72,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _transcript.isEmpty ? 0.0 : 1.0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF192540).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF40485D).withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  _transcript.isEmpty ? '' : '"$_transcript"',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDEE5FF),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hint
          Text(
            isListening
                ? 'Tap the mic to stop'
                : 'e.g. "Bought 2 books for 400" or "Got 500 from dad"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFA3AAC4).withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
        ),
      ),
    );
  }
}
