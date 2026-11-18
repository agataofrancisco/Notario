import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppContentFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AppContentFrame({
    super.key,
    required this.child,
    this.maxWidth = 760,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool centered;
  final EdgeInsetsGeometry padding;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.centered = false,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: centered
          ? Column(
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (trailing != null) ...[
                  const SizedBox(height: 12),
                  trailing!,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.headlineSmall),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const AppSectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (action != null) action!,
          ],
        ),
      );
}

class AppFeedbackState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  const AppFeedbackState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              if (isError)
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                )
              else
                FilledButton.tonal(
                    onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
