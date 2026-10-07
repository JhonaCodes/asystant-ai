import 'package:flutter/material.dart';

import 'package:asystant_ai/src/model/asystant_dashboard_content.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';

/// The library-owned control-center welcome for an empty conversation.
/// The host supplies only its modules, prompts and copy.
class AsystantDashboardWelcome extends StatefulWidget {
  const AsystantDashboardWelcome({
    super.key,
    required this.modules,
    required this.capabilities,
    required this.onPromptSelected,
    this.eyebrow = 'ASSISTANT · YOUR SYSTEMS',
    this.status = 'Available',
    this.title = 'What shall we do today?',
    this.subtitle =
        'Explore your systems, prepare changes, and decide before they run.',
    this.suggestionsTitle = 'Start here',
    this.previewLabel = 'Example conversation',
    this.previewQuestion = 'What needs attention today?',
    this.previewTitle = 'Your overview in one place',
    this.previewDescription = 'A summary by module with verifiable information and links to its source.',
    this.capabilitiesTitle = 'What the assistant can do',
    this.capabilitiesAction = 'View tools',
    this.prepareAction = 'Prepare action',
    this.trustNote = 'No change runs without your confirmation.',
    this.capabilitiesNote = 'Changes require confirmation.',
  });

  /// The first module represents all modules; the rest act as filters.
  final List<AsystantDashboardModule> modules;
  final List<AsystantDashboardCapability> capabilities;
  final ValueChanged<String> onPromptSelected;
  final String eyebrow;
  final String status;
  final String title;
  final String subtitle;
  final String suggestionsTitle;
  final String previewLabel;
  final String previewQuestion;
  final String previewTitle;
  final String previewDescription;
  final String capabilitiesTitle;
  final String capabilitiesAction;
  final String prepareAction;
  final String trustNote;
  final String capabilitiesNote;

  @override
  State<AsystantDashboardWelcome> createState() =>
      _AsystantDashboardWelcomeState();
}

class _AsystantDashboardWelcomeState extends State<AsystantDashboardWelcome> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final prompts = widget.modules.isEmpty
        ? const <String>[]
        : widget.modules[selected.clamp(0, widget.modules.length - 1)].prompts;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.eyebrow,
                  style: text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  '● ${widget.status}',
                  style: text.labelSmall?.copyWith(
                    color: AsystantTheme.contrastOn(colors.primaryContainer),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: text.headlineMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.subtitle,
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.modules.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _ModuleChip(
                label: widget.modules[index].label,
                selected: selected == index,
                onTap: () => setState(() => selected = index),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.suggestionsTitle,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Ejemplos',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: 190,
                child: _PanelTap(
                  onTap: () => widget.onPromptSelected(prompts[index]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.north_east_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      Text(
                        prompts[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const _AiTile(size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.previewLabel,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Datos ilustrativos',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                widget.previewQuestion,
                style: text.bodySmall?.copyWith(color: colors.onSurface),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _OverviewPanel(widget: widget),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.trustNote,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.widget});
  final AsystantDashboardWelcome widget;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _AiTile(size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.previewTitle,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.previewDescription,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final capability in widget.capabilities)
            InkWell(
              onTap: () => widget.onPromptSelected(capability.prompt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        capability.icon,
                        size: 18,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            capability.title,
                            style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            capability.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => showAsystantCapabilities(
                  context,
                  title: widget.capabilitiesTitle,
                  capabilities: widget.capabilities,
                  note: widget.capabilitiesNote,
                ),
                child: Text(widget.capabilitiesAction),
              ),
              FilledButton(
                onPressed: () =>
                    widget.onPromptSelected(widget.previewQuestion),
                child: Text(widget.prepareAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.onSurface : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? colors.onSurface : colors.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            selected ? label : '●  $label',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? colors.surface : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelTap extends StatelessWidget {
  const _PanelTap({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AiTile extends StatelessWidget {
  const _AiTile({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Text(
        'AI',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: AsystantTheme.contrastOn(colors.primaryContainer),
        ),
      ),
    );
  }
}

/// Opens the library's accessible, scrollable description of host capabilities.
Future<void> showAsystantCapabilities(
  BuildContext context, {
  required String title,
  required List<AsystantDashboardCapability> capabilities,
  required String note,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final item in capabilities)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            item.detail,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Text(note, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  ),
);
