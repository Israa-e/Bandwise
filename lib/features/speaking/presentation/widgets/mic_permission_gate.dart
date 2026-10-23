import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/speaking_devices.dart';

/// Shows [child] once the microphone may be used. Before the system prompt
/// it explains why it's needed; when access was refused it says how to
/// allow it, with "Open settings" when only the settings can.
class MicPermissionGate extends StatefulWidget {
  const MicPermissionGate({
    super.key,
    required this.recorder,
    required this.child,
  });

  final SpeakingRecorder recorder;
  final Widget child;

  @override
  State<MicPermissionGate> createState() => _MicPermissionGateState();
}

enum _GateState { checking, explain, denied, blocked, granted }

class _MicPermissionGateState extends State<MicPermissionGate>
    with WidgetsBindingObserver {
  var _state = _GateState.checking;
  var _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check(initial: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the settings: check again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _state == _GateState.blocked &&
        !_asking) {
      _check();
    }
  }

  Future<void> _check({bool initial = false}) async {
    final p = await widget.recorder.permission();
    if (!mounted) return;
    setState(
      () => _state = switch (p) {
        MicPermission.granted => _GateState.granted,
        MicPermission.permanentlyDenied => _GateState.blocked,
        MicPermission.canAsk =>
          initial || _state == _GateState.explain
              ? _GateState.explain
              : _GateState.denied,
      },
    );
  }

  Future<void> _ask() async {
    setState(() => _asking = true);
    final p = await widget.recorder.requestPermission();
    if (!mounted) return;
    setState(() {
      _asking = false;
      _state = switch (p) {
        MicPermission.granted => _GateState.granted,
        MicPermission.permanentlyDenied => _GateState.blocked,
        MicPermission.canAsk => _GateState.denied,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _GateState.granted => widget.child,
      _GateState.checking => const Center(child: CircularProgressIndicator()),
      _GateState.explain => _Message(
        key: const ValueKey('micExplain'),
        icon: Icons.mic_none_rounded,
        title: 'Allow the microphone',
        message:
            'Speaking practice records your answers so you can listen back '
            'to them. Recordings stay on this device: they are not uploaded '
            'or synced.',
        note: 'Your phone will ask you next.',
        actionLabel: 'Continue',
        busy: _asking,
        onAction: _ask,
      ),
      _GateState.denied => _Message(
        key: const ValueKey('micDenied'),
        icon: Icons.mic_off_outlined,
        title: 'Microphone access is off',
        message:
            "Speaking practice can't record without the microphone. You can "
            'allow it and try again.',
        actionLabel: 'Allow the microphone',
        busy: _asking,
        onAction: _ask,
      ),
      _GateState.blocked => _Message(
        key: const ValueKey('micBlocked'),
        icon: Icons.mic_off_outlined,
        title: 'Microphone access is off',
        message:
            "Speaking practice can't record without the microphone. Turn it "
            "on for Bandwise in your phone's settings, then come back.",
        actionLabel: 'Open settings',
        busy: false,
        onAction: widget.recorder.openSettings,
      ),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.busy,
    required this.onAction,
    this.note,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? note;
  final String actionLabel;
  final bool busy;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    return EmptyStateView(
      icon: icon,
      title: title,
      message: message,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note != null) ...[
            Text(
              note,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.smd),
          ],
          AppButton.primary(
            key: const ValueKey('micAction'),
            label: actionLabel,
            expand: false,
            isLoading: busy,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
