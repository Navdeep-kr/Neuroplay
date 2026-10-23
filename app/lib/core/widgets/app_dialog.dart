import 'package:flutter/material.dart';
import 'package:neuroplay/core/theme/app_radii.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/widgets/app_button.dart';

/// Reusable modal dialog with clear typography, actions, and accessibility labels.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.content,
    super.key,
    this.primaryActionLabel = 'Confirm',
    this.onPrimaryAction,
    this.secondaryActionLabel = 'Cancel',
    this.onSecondaryAction,
    this.isDestructive = false,
  });

  final String title;
  final Widget content;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;

  /// Helper to display a standardized confirmation dialog.
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          title: title,
          content: Text(message),
          primaryActionLabel: confirmLabel,
          isDestructive: isDestructive,
          onPrimaryAction: () => Navigator.of(context).pop(true),
          secondaryActionLabel: cancelLabel,
          onSecondaryAction: () => Navigator.of(context).pop(false),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: AppSpacing.pXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall,
              ),
              AppSpacing.gapH16,
              DefaultTextStyle(
                style: theme.textTheme.bodyMedium!,
                child: content,
              ),
              AppSpacing.gapH24,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (secondaryActionLabel != null) ...[
                    AppButton(
                      label: secondaryActionLabel!,
                      variant: AppButtonVariant.secondary,
                      onPressed: onSecondaryAction ??
                          () => Navigator.of(context).pop(),
                    ),
                    AppSpacing.gapW12,
                  ],
                  if (onPrimaryAction != null)
                    AppButton(
                      label: primaryActionLabel,
                      variant: isDestructive
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      onPressed: onPrimaryAction,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
