import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/models.dart';
import '../web/browser.dart';
import '../widgets/copy.dart';
import '../widgets/section_label.dart';
import 'plans.dart';

/// Built-in and custom reading plans with progress.
class ReadingPlansScreen extends StatelessWidget {
  const ReadingPlansScreen({super.key});

  Future<void> _builder(BuildContext context, {CustomPlanDef? editing}) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => CustomPlanBuilderScreen(editing: editing),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlanStore>();
    final library = context.read<BibleLibrary>();
    final builtIns = ReadingPlanCatalog.builtIns(library);
    final custom = [
      for (final d in store.customDefs) ReadingPlanCatalog.inflate(d, library),
    ];
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Plans'),
        actions: [
          IconButton(
            tooltip: 'Create a custom plan',
            onPressed: () => _builder(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SectionLabel('Plans'),
              for (final p in builtIns) _PlanRow(plan: p),
              const SectionLabel('My plans'),
              for (final p in custom)
                _PlanRow(
                  plan: p,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (v) {
                      if (v == 'edit') {
                        _builder(context, editing: store.customDef(p.id));
                      } else {
                        store.deleteCustomPlan(p.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create a custom plan'),
                onTap: () => _builder(context),
              ),
              if (custom.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Build a plan from any books, at your own pace.',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan, this.trailing});
  final ReadingPlan plan;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlanStore>();
    final scheme = Theme.of(context).colorScheme;
    final done = store.completed(plan.id).length;
    Widget badge(String text, Color color) => Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PlanDetailScreen(planId: plan.id),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              plan.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (plan.isCustom)
            badge('Custom', scheme.onSurface.withValues(alpha: 0.6)),
          if (store.isActive(plan.id)) badge('Active', scheme.primary),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.description),
          if (done > 0) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: done / (plan.totalDays < 1 ? 1 : plan.totalDays),
            ),
            const SizedBox(height: 4),
            Text(
              '$done of ${plan.totalDays} days',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
    );
  }
}

/// A plan's days: start or stop it, tick days off (with a celebration at the
/// end), and tap a day to open its reading.
class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final String planId;

  Future<void> _celebrate(BuildContext context, ReadingPlan plan) {
    final message =
        'I finished the “${plan.name}” reading plan in Bible Seek — ${plan.totalDays} days in God’s Word. 🙏';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.emoji_events, size: 54, color: Colors.amber),
        title: const Text('Plan complete!'),
        content: Text(
          '${plan.totalDays} days of Scripture, finished.\nWell done.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => canShareNatively
                ? shareText(message)
                : copyWithFeedback(context, message),
            icon: const Icon(Icons.ios_share),
            label: const Text('Share'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlanStore>();
    final plan = store
        .allPlans(context.read<BibleLibrary>())
        .where((p) => p.id == planId)
        .firstOrNull;
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This plan no longer exists.')),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final done = store.completed(plan.id).length;
    final active = store.isActive(plan.id);
    final next = store.nextDay(plan);
    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.builder(
            itemCount: plan.totalDays + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.description,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: done / (plan.totalDays < 1 ? 1 : plan.totalDays),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$done of ${plan.totalDays} days complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      active
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: scheme.error,
                              ),
                              onPressed: () => store.toggleActive(plan.id),
                              child: const Text('Stop plan'),
                            )
                          : FilledButton(
                              onPressed: () => store.toggleActive(plan.id),
                              child: const Text('Start plan'),
                            ),
                      const SectionLabel(
                        'Days',
                        padding: EdgeInsets.only(top: 20, bottom: 4),
                      ),
                    ],
                  ),
                );
              }
              final day = i - 1;
              final readings = plan.readingsFor(day);
              final isDone = store.isDone(plan.id, day);
              return ListTile(
                selected: day == next,
                leading: IconButton(
                  tooltip: isDone ? 'Mark as not read' : 'Mark as read',
                  icon: Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isDone
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.45),
                  ),
                  onPressed: () {
                    final wasComplete = store.isComplete(plan);
                    store.toggleDay(plan.id, day);
                    if (!wasComplete && store.isComplete(plan)) {
                      _celebrate(context, plan);
                    }
                  },
                ),
                title: Text(
                  'Day ${day + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                subtitle: Text(
                  readings.isEmpty
                      ? 'Rest day'
                      : readings.map((r) => r.label).join(', '),
                  style: TextStyle(
                    fontSize: 15,
                    color: readings.isEmpty
                        ? scheme.onSurface.withValues(alpha: 0.5)
                        : scheme.onSurface,
                  ),
                ),
                trailing: readings.isEmpty
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: readings.isEmpty
                    ? null
                    : () => context.read<AppModel>().open(
                        ReaderTarget(
                          bookCode: readings.first.bookCode,
                          chapter: readings.first.startChapter,
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Build or edit a custom plan: name it, pick books (with Old/New Testament
/// shortcuts), and choose a duration.
class CustomPlanBuilderScreen extends StatefulWidget {
  const CustomPlanBuilderScreen({super.key, this.editing});
  final CustomPlanDef? editing;

  @override
  State<CustomPlanBuilderScreen> createState() =>
      _CustomPlanBuilderScreenState();
}

class _CustomPlanBuilderScreenState extends State<CustomPlanBuilderScreen> {
  late final _name = TextEditingController(
    text: widget.editing?.name == 'Custom plan' ? '' : widget.editing?.name,
  );
  late final _desc = TextEditingController(
    text: widget.editing?.description == 'Custom plan'
        ? ''
        : widget.editing?.description,
  );
  late final Set<String> _selected = {...?widget.editing?.books};
  late int _days = widget.editing?.totalDays ?? 30;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _save() {
    final store = context.read<PlanStore>();
    final books = [
      for (final b in context.read<BibleLibrary>().books)
        if (_selected.contains(b.id)) b.id,
    ];
    if (widget.editing case final e?) {
      store.updateCustomPlan(
        e.id,
        name: _name.text,
        description: _desc.text,
        books: books,
        totalDays: _days,
      );
    } else {
      store.saveCustomPlan(
        name: _name.text,
        description: _desc.text,
        books: books,
        totalDays: _days,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.read<BibleLibrary>();
    final scheme = Theme.of(context).colorScheme;
    final ot = library.books.where((b) => b.order < 40).toList();
    final nt = library.books.where((b) => b.order >= 40).toList();
    final total = library.books
        .where((b) => _selected.contains(b.id))
        .fold<int>(0, (n, b) => n + b.chapters);
    final presets = [
      if (total > 0)
        for (var pace = 1; pace <= (total < 30 ? total : 30); pace++)
          if (total % pace == 0) (days: total ~/ pace, label: '$pace ch/day'),
    ];
    Widget bookTile(BibleBook b) => CheckboxListTile(
      dense: true,
      value: _selected.contains(b.id),
      onChanged: (v) =>
          setState(() => v! ? _selected.add(b.id) : _selected.remove(b.id)),
      title: Text(b.commonName),
      secondary: Text(
        '${b.chapters}',
        style: TextStyle(
          fontSize: 12,
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing == null ? 'New Plan' : 'Edit Plan'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const SectionLabel('Name'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(hintText: 'Plan name'),
                    ),
                    TextField(
                      controller: _desc,
                      decoration: const InputDecoration(
                        hintText: 'Description (optional)',
                      ),
                    ),
                  ],
                ),
              ),
              const SectionLabel('Duration'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (total > 0)
                      Text(
                        '$total chapters · ~${(total / _days).toStringAsFixed(1)} chapters/day',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Duration: $_days day${_days == 1 ? '' : 's'}',
                          ),
                        ),
                        IconButton(
                          onPressed: _days > 1
                              ? () => setState(() => _days--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          onPressed: _days < 730
                              ? () => setState(() => _days++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    if (presets.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in presets)
                            ChoiceChip(
                              label: Text('${p.label} · ${p.days}d'),
                              selected: _days == p.days,
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _days = p.days),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              SectionLabel('Books — ${_selected.length} selected'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _selected.addAll(ot.map((b) => b.id))),
                      child: const Text('Add OT'),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _selected.addAll(nt.map((b) => b.id))),
                      child: const Text('Add NT'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      onPressed: () => setState(_selected.clear),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const SectionLabel('Old Testament'),
              for (final b in ot) bookTile(b),
              const SectionLabel('New Testament'),
              for (final b in nt) bookTile(b),
            ],
          ),
        ),
      ),
    );
  }
}
