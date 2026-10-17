import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/writing.dart';
import '../../domain/writing_submission.dart';
import '../writing_providers.dart';

/// Loads a submission and its task for the feedback screens, with loading,
/// error and not-found states.
class SubmissionLoader extends ConsumerWidget {
  const SubmissionLoader({
    super.key,
    required this.submissionId,
    required this.builder,
  });

  final String submissionId;
  final Widget Function(
    BuildContext context,
    WritingTask task,
    WritingSubmission submission,
    List<WritingSubmission> all,
  )
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(writingTasksProvider);
    final submissions = ref.watch(writingSubmissionsProvider);
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.writingHub);
    if ([tasks, submissions].any((a) => a.hasError && !a.isLoading)) {
      return Scaffold(
        appBar: SessionTopBar(onClose: back),
        body: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: "Couldn't load your essay",
          message: 'Check your connection and try again.',
          action: AppButton.primary(
            label: 'Retry',
            expand: false,
            onPressed: () => ref
              ..invalidate(writingTasksProvider)
              ..invalidate(writingSubmissionsProvider),
          ),
        ),
      );
    }
    if (!tasks.hasValue || !submissions.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final all = submissions.requireValue;
    final submission = all.where((s) => s.id == submissionId).firstOrNull;
    final task = tasks.requireValue
        .where((t) => t.id == submission?.taskId)
        .firstOrNull;
    if (submission == null || task == null) {
      return Scaffold(
        appBar: SessionTopBar(onClose: back),
        body: EmptyStateView(
          icon: Icons.search_off_rounded,
          title: 'Essay not found',
          message: 'Your essays are listed in the Writing hub.',
          action: AppButton.outline(
            label: 'Go to Writing',
            expand: false,
            onPressed: () => context.go(AppRoutes.writingHub),
          ),
        ),
      );
    }
    return builder(context, task, submission, all);
  }
}
