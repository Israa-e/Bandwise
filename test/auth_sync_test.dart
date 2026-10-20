import 'dart:async';
import 'dart:convert';

import 'package:bandwise/app.dart';
import 'package:bandwise/core/router/app_router.dart';
import 'package:bandwise/core/router/app_routes.dart';
import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/utils/clock.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/auth/domain/auth_service.dart';
import 'package:bandwise/features/auth/domain/auth_validation.dart';
import 'package:bandwise/features/auth/presentation/account_flow.dart';
import 'package:bandwise/features/auth/presentation/auth_providers.dart';
import 'package:bandwise/features/home/presentation/home_screen.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/onboarding/presentation/welcome_screen.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:bandwise/features/progress/presentation/progress_controller.dart';
import 'package:bandwise/features/sync/domain/sync_repository.dart';
import 'package:bandwise/features/sync/presentation/sync_service.dart';
import 'package:bandwise/features/writing/data/writing_content.dart';
import 'package:bandwise/features/writing/domain/writing.dart';
import 'package:bandwise/features/writing/domain/writing_submission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';

final _today = DateTime(2026, 10, 15);
DateTime _day(int offset) => DateTime(2026, 10, 15 + offset);

const _email = 'sam@example.com';
const _password = 'Passw0rd!';

const _plan = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  isGuest: true,
  targetBand: TargetBand.band7,
  dailyMinutes: 20,
  placementSkipped: true,
  level: EnglishLevel.intermediate,
);

WritingSubmission _essay(String id, DateTime at) => WritingSubmission(
  id: id,
  taskId: cyclingTask.id,
  mode: WritingMode.learning,
  text: 'An essay written as $id.',
  timeUsed: const Duration(minutes: 10),
  submittedAt: at,
  result: const DemoResult(),
);

/// Progress made as a guest on this device: one essay yesterday.
final _guestProgress = const ProgressState().withWritingSubmission(
  date: _day(-1),
  minutes: 12,
  xp: XpRules.perNewEssay,
  submissionId: 'ws-guest',
);
final _guestEssay = _essay('ws-guest', DateTime(2026, 10, 14, 18));

/// Progress already in the account, from another device.
final _accountProgress = const ProgressState().withWritingSubmission(
  date: _day(-5),
  minutes: 30,
  xp: XpRules.perNewEssay,
  submissionId: 'ws-account',
);
final _accountEssay = _essay('ws-account', DateTime(2026, 10, 10, 18));
const _accountPlan = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  targetBand: TargetBand.band8plus,
  dailyMinutes: 45,
  placementSkipped: true,
);

late FakeAuthService _auth;
late FakeSyncRepository _remote;
late ProviderContainer _container;
late DateTime _now;

void _seed({
  OnboardingState? onboarding = _plan,
  ProgressState? progress,
  List<WritingSubmission> essays = const [],
}) {
  SharedPreferences.setMockInitialValues({
    'onboarding.v1': ?(onboarding == null
        ? null
        : jsonEncode(onboarding.toJson())),
    'progress.v1': ?(progress == null ? null : jsonEncode(progress.toJson())),
    if (essays.isNotEmpty)
      'writing.submissions.v1': jsonEncode([
        for (final e in essays) e.toJson(),
      ]),
  });
  PackageInfo.setMockInitialValues(
    appName: 'Bandwise',
    packageName: 'app.bandwise',
    version: '0.1.0',
    buildNumber: '1',
    buildSignature: '',
  );
}

/// An existing account on the server with progress and an essay.
void _seedAccount({bool withProgress = true}) {
  _auth.addAccount(_email, password: _password, name: 'Sam Carter');
  if (!withProgress) return;
  final id = _auth.idOf(_email);
  final at = DateTime.utc(2026, 10, 10, 8);
  _remote.documents[id] = {
    SyncDocumentKey.onboarding: SyncDocument(
      key: SyncDocumentKey.onboarding,
      data: _accountPlan.toJson(),
      updatedAt: at,
    ),
    SyncDocumentKey.progress: SyncDocument(
      key: SyncDocumentKey.progress,
      data: _accountProgress.toJson(),
      updatedAt: at,
    ),
  };
  _remote.essays[id] = {_accountEssay.id: _accountEssay};
}

Future<void> _launch(
  WidgetTester tester, {
  Size size = const Size(390, 900),
  bool rtl = false,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // Disposed with the widget tree, which also cancels the sync timers.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(_today),
        clockProvider.overrideWithValue(() => _now),
        authServiceProvider.overrideWithValue(_auth),
        syncRepositoryProvider.overrideWithValue(_remote),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: ref.watch(routerProvider),
          builder: (context, child) => Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: AppScope(child: child!),
          ),
        ),
      ),
    ),
  );
  _container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  await tester.pump(const Duration(seconds: 2)); // splash
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, String location) async {
  _container.read(routerProvider).push(location);
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(AppBottomNav), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final list = find.byType(Scrollable).first;
    try {
      await tester.scrollUntilVisible(finder, 300, scrollable: list);
    } on StateError {
      await tester.scrollUntilVisible(finder, -300, scrollable: list);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final nav = find.byType(AppBottomNav);
  if (nav.evaluate().isNotEmpty &&
      tester.getRect(finder).bottom > tester.getTopLeft(nav).dy) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  final field = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(EditableText),
  );
  await _reveal(tester, field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Lets the debounce or retry timer fire and the sync finish.
Future<void> _elapse(WidgetTester tester, Duration duration) async {
  _now = _now.add(duration);
  await tester.pump(duration);
  await tester.pumpAndSettle();
}

/// Logs in from the login screen. With [expectDialog], stops at the
/// keep-or-replace dialog (the button's spinner keeps running behind it).
Future<void> _logIn(
  WidgetTester tester, {
  String email = _email,
  String password = _password,
  bool expectDialog = false,
}) async {
  await _push(tester, AppRoutes.login);
  await _type(tester, 'emailField', email);
  await _type(tester, 'passwordField', password);
  await _submitLogIn(tester, expectDialog: expectDialog);
}

Future<void> _submitLogIn(
  WidgetTester tester, {
  bool expectDialog = false,
}) async {
  final button = find.byKey(const ValueKey('logInButton'));
  await _reveal(tester, button);
  await tester.tap(button);
  if (!expectDialog) {
    await tester.pumpAndSettle();
    return;
  }
  final dialog = find.byKey(const ValueKey('keepOrReplaceDialog'));
  for (var i = 0; i < 50 && dialog.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(dialog, findsOneWidget);
}

/// Picks an option in the keep-or-replace dialog and continues.
Future<void> _choose(WidgetTester tester, String option) async {
  await tester.tap(find.byKey(ValueKey(option)));
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

AppButton _button(WidgetTester tester, String key) =>
    tester.widget<AppButton>(find.byKey(ValueKey(key)));

Future<Map<String, Object>> _prefs() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final k in prefs.getKeys()) k: prefs.get(k)!};
}

Future<ProgressState> _localProgress() async {
  final raw = (await SharedPreferences.getInstance()).getString('progress.v1');
  return ProgressState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
}

Future<List<String>> _localEssayIds() async {
  final raw = (await SharedPreferences.getInstance()).getString(
    'writing.submissions.v1',
  );
  if (raw == null) return [];
  return [for (final e in jsonDecode(raw) as List) (e as Map)['id'] as String];
}

/// The account's progress; empty if it has none yet.
ProgressState _remoteProgress() =>
    switch (_remote.document(_auth.idOf(_email), SyncDocumentKey.progress)) {
      final doc? => ProgressState.fromJson(doc.data),
      null => const ProgressState(),
    };

void main() {
  setUp(() {
    _auth = FakeAuthService();
    _remote = FakeSyncRepository();
    _now = DateTime(2026, 10, 15, 9);
  });

  group('validation', () {
    test('password strength and field checks', () {
      expect(passwordStrength('abc12'), PasswordStrength.tooShort);
      expect(passwordStrength('abcdefgh'), PasswordStrength.weak);
      expect(passwordStrength('abcdefg1'), PasswordStrength.fair);
      expect(passwordStrength('Abcdefg1!xyz'), PasswordStrength.strong);
      expect(validateEmail('sam@example'), isNotNull);
      expect(validateEmail(' sam@example.com '), isNull);
      expect(validateName('  '), isNotNull);
      expect(validateNewPassword('abcdefgh'), 'Use both letters and numbers.');
      expect(validateResetCode('12345'), isNotNull);
      expect(validateResetCode('123456'), isNull);
    });
  });

  group('sign up', () {
    testWidgets('fields are validated, with a strength meter', (tester) async {
      _seed();
      await _launch(tester);
      await _push(tester, AppRoutes.createAccount);
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);

      await _type(tester, 'emailField', 'sam@');
      await _type(tester, 'passwordField', 'abcdefgh');
      expect(find.text('Weak password'), findsOneWidget);
      await _type(tester, 'passwordField', 'abcdefg1');
      expect(find.text('Fair password'), findsOneWidget);
      await _type(tester, 'passwordField', 'Abcdefg1!xyz');
      expect(find.text('Strong password'), findsOneWidget);
      await _type(tester, 'passwordField', 'short1');

      await _tap(tester, find.byKey(const ValueKey('termsCheckbox')));
      await _tap(tester, find.byKey(const ValueKey('createAccountButton')));
      expect(find.text('Enter your name.'), findsOneWidget);
      expect(
        find.text(
          'Please enter a valid email address (e.g. name@example.com).',
        ),
        findsOneWidget,
      );
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(_auth.signUpCalls, 0);
    });

    testWidgets('the terms checkbox starts unchecked and gates the button', (
      tester,
    ) async {
      _seed();
      await _launch(tester);
      await _push(tester, AppRoutes.createAccount);
      await _type(tester, 'nameField', 'Sam Carter');
      await _type(tester, 'emailField', _email);
      await _type(tester, 'passwordField', _password);

      expect(
        tester
            .widget<Checkbox>(find.byKey(const ValueKey('termsCheckbox')))
            .value,
        isFalse,
      );
      expect(_button(tester, 'createAccountButton').onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('createAccountButton')));
      await tester.pumpAndSettle();
      expect(_auth.signUpCalls, 0);

      await _tap(
        tester,
        find.text('I agree to the Terms of Use and the Privacy Policy.'),
      );
      expect(_button(tester, 'createAccountButton').onPressed, isNotNull);
    });

    testWidgets("a guest's progress is uploaded to the new account", (
      tester,
    ) async {
      _seed(progress: _guestProgress, essays: [_guestEssay]);
      await _launch(tester);
      await _tab(tester, 'Profile');
      await _tap(tester, find.widgetWithText(AppButton, 'Create account'));
      await _type(tester, 'nameField', 'Sam Carter');
      await _type(tester, 'emailField', _email);
      await _type(tester, 'passwordField', _password);
      await _tap(tester, find.byKey(const ValueKey('termsCheckbox')));
      await _tap(tester, find.byKey(const ValueKey('createAccountButton')));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Hi, Sam'), findsOneWidget);
      final id = _auth.idOf(_email);
      expect(
        jsonEncode(_remoteProgress().toJson()),
        jsonEncode(_guestProgress.toJson()),
      );
      expect(_remote.essays[id]!.keys, ['ws-guest']);

      // No longer a guest; the change is uploaded after the debounce.
      await _elapse(tester, const Duration(seconds: 4));
      final plan = OnboardingState.fromJson(
        _remote.document(id, SyncDocumentKey.onboarding)!.data,
      );
      expect(plan.isGuest, isFalse);
      expect(plan.targetBand, TargetBand.band7);

      await _tab(tester, 'Profile');
      expect(find.text('Sam Carter'), findsWidgets);
      await _reveal(tester, find.byKey(const ValueKey('syncStatus')));
      expect(find.text('Synced just now'), findsOneWidget);
    });

    testWidgets('with email confirmation: check your inbox, then log in', (
      tester,
    ) async {
      _auth.requireConfirmation = true;
      _seed();
      await _launch(tester);
      await _push(tester, AppRoutes.createAccount);
      await _type(tester, 'nameField', 'Sam Carter');
      await _type(tester, 'emailField', _email);
      await _type(tester, 'passwordField', _password);
      await _tap(tester, find.byKey(const ValueKey('termsCheckbox')));
      await _tap(tester, find.byKey(const ValueKey('createAccountButton')));

      expect(
        find.text('Check your inbox to confirm your email'),
        findsOneWidget,
      );
      expect(_auth.currentUser, isNull);
      await _tap(tester, find.widgetWithText(AppButton, 'Log in'));
      // The email is filled in.
      expect(find.text(_email), findsOneWidget);
      await _type(tester, 'passwordField', _password);
      await _tap(tester, find.byKey(const ValueKey('logInButton')));
      expect(
        find.text(AuthErrorKind.emailNotConfirmed.message),
        findsOneWidget,
      );

      _auth.confirm(_email);
      await _tap(tester, find.byKey(const ValueKey('logInButton')));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a registered email gets the same "check your inbox"', (
      tester,
    ) async {
      _auth.addAccount(_email);
      _seed();
      await _launch(tester);
      await _push(tester, AppRoutes.createAccount);
      await _type(tester, 'nameField', 'Someone');
      await _type(tester, 'emailField', _email);
      await _type(tester, 'passwordField', 'Another1pass');
      await _tap(tester, find.byKey(const ValueKey('termsCheckbox')));
      await _tap(tester, find.byKey(const ValueKey('createAccountButton')));
      expect(
        find.text('Check your inbox to confirm your email'),
        findsOneWidget,
      );
    });
  });

  group('log in', () {
    testWidgets('errors: wrong password, network, rate limit', (tester) async {
      _seedAccount(withProgress: false);
      _seed();
      await _launch(tester);
      await _logIn(tester, password: 'wrong-pass1');
      expect(
        find.text('Email or password is incorrect. Please try again.'),
        findsOneWidget,
      );

      _auth.failNext = AuthErrorKind.network;
      await _tap(tester, find.byKey(const ValueKey('logInButton')));
      expect(
        find.text("Can't reach Bandwise. Check your connection and try again."),
        findsOneWidget,
      );

      _auth.failNext = AuthErrorKind.rateLimited;
      await _tap(tester, find.byKey(const ValueKey('logInButton')));
      expect(
        find.text('Too many attempts, try again in a few minutes.'),
        findsOneWidget,
      );
      expect(_auth.currentUser, isNull);
    });

    testWidgets('loading and error are separate states', (tester) async {
      _seedAccount(withProgress: false);
      _seed();
      await _launch(tester);
      await _logIn(tester, password: 'wrong-pass1');
      expect(find.byKey(const ValueKey('loginError')), findsOneWidget);

      _auth.gate = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('logInButton')));
      await tester.pump();
      expect(_button(tester, 'logInButton').isLoading, isTrue);
      expect(find.byKey(const ValueKey('loginError')), findsNothing);
      _auth.gate!.complete();
      _auth.gate = null;
      await tester.pumpAndSettle();
      expect(_button(tester, 'logInButton').isLoading, isFalse);
      expect(find.byKey(const ValueKey('loginError')), findsOneWidget);
    });

    testWidgets('fields are checked before sending', (tester) async {
      _seed();
      await _launch(tester);
      await _push(tester, AppRoutes.login);
      await _tap(tester, find.byKey(const ValueKey('logInButton')));
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });
  });

  group('password reset', () {
    testWidgets('code flow; the copy never reveals whether an account exists', (
      tester,
    ) async {
      _seedAccount(withProgress: false);
      _seed();
      await _launch(tester);
      await _push(tester, AppRoutes.login);
      await _tap(tester, find.text('Forgot password?'));
      expect(find.text('Reset your password'), findsOneWidget);

      // An unknown email gets exactly the same answer.
      await _type(tester, 'resetEmailField', 'nobody@example.com');
      await _tap(tester, find.byKey(const ValueKey('sendCodeButton')));
      final unknown = _allText(tester);
      expect(
        unknown,
        contains(
          'If an account exists for nobody@example.com, we’ve sent a 6-digit '
          'code. It can take a few minutes and may land in spam.',
        ),
      );
      await _tap(tester, find.text('Use a different email'));
      await _type(tester, 'resetEmailField', _email);
      await _tap(tester, find.byKey(const ValueKey('sendCodeButton')));
      expect(
        _allText(tester),
        contains(
          'If an account exists for $_email, we’ve sent a 6-digit code. It '
          'can take a few minutes and may land in spam.',
        ),
      );
      expect(_auth.resetRequests, ['nobody@example.com', _email]);

      // Wrong code.
      await _type(tester, 'codeField', '000000');
      await _type(tester, 'newPasswordField', 'NewPassw0rd');
      await _tap(tester, find.byKey(const ValueKey('resetButton')));
      expect(find.text(AuthErrorKind.invalidCode.message), findsOneWidget);

      await _type(tester, 'codeField', '123456');
      await _tap(tester, find.byKey(const ValueKey('resetButton')));
      expect(find.text('Password updated'), findsOneWidget);
      expect(_auth.passwordOf(_email), 'NewPassw0rd');
      await _tap(tester, find.byKey(const ValueKey('resetContinue')));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_auth.currentUser?.email, _email);
    });

    testWidgets('a rate limit is explained', (tester) async {
      _seed();
      await _launch(tester);
      await _push(tester, AppRoutes.forgotPassword);
      _auth.failNext = AuthErrorKind.rateLimited;
      await _type(tester, 'resetEmailField', _email);
      await _tap(tester, find.byKey(const ValueKey('sendCodeButton')));
      expect(
        find.text('Too many attempts, try again in a few minutes.'),
        findsOneWidget,
      );
    });
  });

  group('logging in with guest progress', () {
    testWidgets("keep the account's progress (the default)", (tester) async {
      _seedAccount();
      _seed(progress: _guestProgress, essays: [_guestEssay]);
      await _launch(tester);
      await _logIn(tester, expectDialog: true);
      expect(
        tester
            .widget<SelectionCard>(find.byKey(const ValueKey('keepAccount')))
            .state,
        SelectionCardState.selected,
      );
      await _choose(tester, 'keepAccount');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        jsonEncode((await _localProgress()).toJson()),
        jsonEncode(_accountProgress.toJson()),
      );
      expect(await _localEssayIds(), ['ws-account']);
      final plan = await _container.read(onboardingControllerProvider.future);
      expect(plan.targetBand, TargetBand.band8plus);
      expect(plan.isGuest, isFalse);
      // The account's copy is untouched.
      expect(
        jsonEncode(_remoteProgress().toJson()),
        jsonEncode(_accountProgress.toJson()),
      );
    });

    testWidgets("replace it with this device's progress", (tester) async {
      _seedAccount();
      _seed(progress: _guestProgress, essays: [_guestEssay]);
      await _launch(tester);
      await _logIn(tester, expectDialog: true);
      await _choose(tester, 'replaceAccount');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        jsonEncode(_remoteProgress().toJson()),
        jsonEncode(_guestProgress.toJson()),
      );
      expect(_remote.essays[_auth.idOf(_email)]!.keys, ['ws-guest']);
      expect(
        jsonEncode((await _localProgress()).toJson()),
        jsonEncode(_guestProgress.toJson()),
      );
    });

    testWidgets('no question without guest progress: the account loads', (
      tester,
    ) async {
      _seedAccount();
      // A fresh install: logging in from Welcome.
      _seed(onboarding: null);
      await _launch(tester);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await _logIn(tester);
      expect(find.byKey(const ValueKey('keepOrReplaceDialog')), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        jsonEncode((await _localProgress()).toJson()),
        jsonEncode(_accountProgress.toJson()),
      );
    });
  });

  group('sync', () {
    testWidgets('offline changes sync after reconnecting', (tester) async {
      _seedAccount(withProgress: false);
      _seed();
      await _launch(tester);
      await _logIn(tester);
      SyncState sync() => _container.read(syncServiceProvider);
      expect(sync().phase, SyncPhase.idle);

      _remote.online = false;
      await _container
          .read(progressControllerProvider.notifier)
          .completeWriting(
            date: _today,
            minutes: 15,
            xp: 20,
            submissionId: 'ws-offline',
          );
      await _elapse(tester, const Duration(seconds: 4));
      expect(sync().phase, SyncPhase.offline);
      expect(_remoteProgress().minutesOn(_today), 0);
      await _tab(tester, 'Profile');
      expect(find.text('Offline — will sync later'), findsOneWidget);

      _remote.online = true;
      await _elapse(tester, SyncService.retryDelay);
      expect(sync().phase, SyncPhase.idle);
      expect(_remoteProgress().minutesOn(_today), 15);
      expect(find.text('Synced just now'), findsOneWidget);
    });

    testWidgets('a server failure offers Retry', (tester) async {
      _seedAccount(withProgress: false);
      _seed();
      await _launch(tester);
      await _logIn(tester);
      _remote.serverError = true;
      await _container.read(syncServiceProvider.notifier).syncNow();
      await _tab(tester, 'Profile');
      expect(find.text('Sync failed'), findsOneWidget);
      _remote.serverError = false;
      await _tap(tester, find.byKey(const ValueKey('syncRetry')));
      expect(find.text('Synced just now'), findsOneWidget);
    });

    for (final remoteNewer in [true, false]) {
      testWidgets('last write wins (${remoteNewer ? 'server' : 'device'} '
          'copy newer)', (tester) async {
        _seedAccount(withProgress: false);
        _seed();
        await _launch(tester);
        await _logIn(tester);
        final id = _auth.idOf(_email);

        // A change on this device while offline...
        _remote.online = false;
        _now = DateTime(2026, 10, 15, 10);
        await _container
            .read(progressControllerProvider.notifier)
            .completeWriting(
              date: _today,
              minutes: 15,
              xp: 20,
              submissionId: 'ws-device',
            );
        await _elapse(tester, const Duration(seconds: 4));

        // ...and one from another device, earlier or later.
        final other = const ProgressState().withWritingSubmission(
          date: _day(-2),
          minutes: 40,
          xp: 20,
          submissionId: 'ws-other',
        );
        _remote.documents[id]![SyncDocumentKey.progress] = SyncDocument(
          key: SyncDocumentKey.progress,
          data: other.toJson(),
          updatedAt: remoteNewer
              ? DateTime(2026, 10, 15, 11).toUtc()
              : DateTime(2026, 10, 15, 9, 30).toUtc(),
        );

        _remote.online = true;
        _now = DateTime(2026, 10, 15, 12);
        await _container.read(syncServiceProvider.notifier).syncNow();
        await tester.pumpAndSettle();

        final local = await _localProgress();
        final remote = _remoteProgress();
        expect(jsonEncode(local.toJson()), jsonEncode(remote.toJson()));
        expect(local.minutesOn(_day(-2)), remoteNewer ? 40 : 0);
        expect(local.minutesOn(_today), remoteNewer ? 0 : 15);
        // The UI reads the winning copy.
        final shown = await _container.read(progressControllerProvider.future);
        expect(shown.minutesOn(_today), remoteNewer ? 0 : 15);
      });
    }

    testWidgets('essays from another device are merged in', (tester) async {
      _seedAccount(withProgress: false);
      _seed(progress: _guestProgress, essays: [_guestEssay]);
      await _launch(tester);
      await _logIn(tester);
      final id = _auth.idOf(_email);
      expect(_remote.essays[id]!.keys, ['ws-guest']);
      _remote.essays[id]![_accountEssay.id] = _accountEssay;
      await _container.read(syncServiceProvider.notifier).syncNow();
      await tester.pumpAndSettle();
      expect(await _localEssayIds(), ['ws-account', 'ws-guest']);
    });
  });

  group('sign out and delete account', () {
    testWidgets('sign out syncs, clears this device and returns to Welcome', (
      tester,
    ) async {
      _seedAccount(withProgress: false);
      _seed(progress: _guestProgress, essays: [_guestEssay]);
      await _launch(tester);
      await _logIn(tester);
      await _tab(tester, 'Profile');
      await _tap(tester, find.byKey(const ValueKey('signOut')));
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(_auth.currentUser, isNull);
      expect(_container.read(authUserProvider), isNull);
      expect(await _prefs(), isEmpty);
      // Still in the account.
      expect(_remoteProgress().totalXp, _guestProgress.totalXp);
    });

    testWidgets('offline sign-out warns before losing changes', (tester) async {
      _seedAccount(withProgress: false);
      _seed();
      await _launch(tester);
      await _logIn(tester);
      _remote.online = false;
      await _tab(tester, 'Profile');
      await _tap(tester, find.byKey(const ValueKey('signOut')));
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't sync"), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(_auth.currentUser, isNotNull);
      expect((await _prefs()).keys, contains('onboarding.v1'));
    });

    testWidgets('delete account calls the function and clears data', (
      tester,
    ) async {
      _seedAccount();
      _seed(onboarding: null);
      await _launch(tester);
      await _logIn(tester);
      await _tab(tester, 'Profile');
      expect(find.byKey(const ValueKey('deleteAllData')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('deleteAccount')));
      for (final item in deleteAccountItems) {
        expect(find.text(item), findsOneWidget);
      }
      await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
      await tester.pumpAndSettle();

      expect(_auth.deleteCalls, 1);
      expect(_auth.hasAccount(_email), isFalse);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(await _prefs(), isEmpty);
    });

    testWidgets('a failed delete keeps everything', (tester) async {
      _seedAccount();
      _seed(onboarding: null);
      await _launch(tester);
      await _logIn(tester);
      await _tab(tester, 'Profile');
      _auth.failNext = AuthErrorKind.network;
      await _tap(tester, find.byKey(const ValueKey('deleteAccount')));
      await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("Your account wasn't deleted."),
        findsOneWidget,
      );
      expect(_auth.hasAccount(_email), isTrue);
      expect((await _prefs()).keys, contains('progress.v1'));
    });
  });

  group('without Supabase keys', () {
    testWidgets('the app runs guest-only', (tester) async {
      _seed(progress: _guestProgress);
      tester.view.physicalSize = const Size(390, 900) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // No overrides: the build's (empty) keys are used.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [todayProvider.overrideWithValue(_today)],
          child: const BandwiseApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Guest'), findsOneWidget);
      expect(find.byKey(const ValueKey('syncStatus')), findsNothing);

      await _tap(tester, find.text('I already have an account'));
      expect(find.byKey(const ValueKey('accountsUnavailable')), findsOneWidget);
      expect(
        find.text("Accounts aren't configured in this build."),
        findsOneWidget,
      );
      expect(_button(tester, 'logInButton').onPressed, isNull);
      await _tap(tester, find.text('Sign up').first);
      expect(find.byKey(const ValueKey('accountsUnavailable')), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('createAccountButton')));
      expect(_button(tester, 'createAccountButton').onPressed, isNull);
    });
  });

  group('layout', () {
    for (final rtl in [false, true]) {
      final dir = rtl ? 'RTL' : 'LTR';
      testWidgets('auth screens, dialogs and the signed-in Profile at 320px: '
          'no overflow ($dir)', (tester) async {
        _seedAccount();
        _seed(progress: _guestProgress, essays: [_guestEssay]);
        await _launch(tester, size: const Size(320, 640), rtl: rtl);
        Future<void> scroll() async {
          for (var i = 0; i < 10; i++) {
            expect(tester.takeException(), isNull);
            final lists = find.byType(Scrollable);
            if (lists.evaluate().isEmpty) return;
            await tester.drag(lists.first, const Offset(0, -300));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        }

        await _push(tester, AppRoutes.createAccount);
        await _tap(tester, find.byKey(const ValueKey('termsCheckbox')));
        await _tap(tester, find.byKey(const ValueKey('createAccountButton')));
        await scroll();
        _container.read(routerProvider).pop();
        await tester.pumpAndSettle();

        await _push(tester, AppRoutes.forgotPassword);
        await _type(tester, 'resetEmailField', _email);
        await _tap(tester, find.byKey(const ValueKey('sendCodeButton')));
        await scroll();
        _container.read(routerProvider).pop();
        await tester.pumpAndSettle();

        await _logIn(tester, password: 'wrong-pass1');
        await scroll();
        await _type(tester, 'passwordField', _password);
        await _submitLogIn(tester, expectDialog: true);
        expect(tester.takeException(), isNull);
        await _choose(tester, 'keepAccount');

        await _tab(tester, 'Profile');
        await scroll();
        await _tap(tester, find.byKey(const ValueKey('deleteAccount')));
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
      });
    }

    testWidgets('check your inbox at 320px', (tester) async {
      _auth.requireConfirmation = true;
      _seed();
      await _launch(tester, size: const Size(320, 640), rtl: true);
      await _push(tester, AppRoutes.createAccount);
      await _type(tester, 'nameField', 'Sam Carter');
      await _type(tester, 'emailField', _email);
      await _type(tester, 'passwordField', _password);
      await _tap(tester, find.byKey(const ValueKey('termsCheckbox')));
      await _tap(tester, find.byKey(const ValueKey('createAccountButton')));
      expect(find.byKey(const ValueKey('checkInbox')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

List<String> _allText(WidgetTester tester) => [
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    t.text.toPlainText(),
];
