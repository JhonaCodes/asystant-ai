import 'package:flutter/material.dart';

import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/profile/ui/widget/fact_row.dart';
import 'package:host_app/src/modules/profile/ui/widget/profile_presentation.dart';
import 'package:host_app/src/modules/profile/viewmodel/profile_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// What the assistant has recorded about the person.
class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.profile,
    required this.viewModel,
  });

  final PersonProfile profile;

  final ProfileViewModel viewModel;

  Future<void> _deleteAll(BuildContext context) async {
    final confirmed = await ConfirmDialog.ask(
      context,
      title: ProfileStrings.deleteTitle,
      body: ProfileStrings.deleteBody,
      confirmLabel: ProfileStrings.deleteAll,
    );
    if (confirmed) {
      await viewModel.deleteProfile();
    }
  }

  @override
  Widget build(BuildContext context) => BotanicaPage(
    title: ProfileStrings.title,
    actions: [
      if (profile.hasData)
        IconButton(
          tooltip: ProfileStrings.deleteAll,
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: () => _deleteAll(context),
        ),
    ],
    children: [
      if (!profile.hasData)
        const EmptyState(
          icon: Icons.person_outline,
          message: ProfileStrings.empty,
        )
      else ...[
        const SectionHeader(ProfileStrings.personal),
        BotanicaCard(
          child: Column(
            children: [
              if (profile.displayName.isNotEmpty)
                FactRow(label: ProfileStrings.name, value: profile.displayName),
              if (viewModel.age case final age?)
                FactRow(
                  label: ProfileStrings.age,
                  value: ProfileStrings.years(age),
                ),
              FactRow(label: ProfileStrings.sex, value: profile.sex.label),
              if (profile.weightKg case final weight?)
                FactRow(
                  label: ProfileStrings.weight,
                  value: ProfileStrings.kilograms(weight),
                ),
              if (profile.heightCm case final height?)
                FactRow(
                  label: ProfileStrings.height,
                  value: ProfileStrings.centimeters(height),
                ),
            ],
          ),
        ),
        const SectionHeader(ProfileStrings.pregnancyAndLactation),
        BotanicaCard(
          child: Column(
            children: [
              FactRow(
                label: ProfileStrings.pregnant,
                value: profile.isPregnant.answer,
              ),
              FactRow(
                label: ProfileStrings.lactating,
                value: profile.isLactating.answer,
              ),
            ],
          ),
        ),
        const SectionHeader(ProfileStrings.conditions),
        _EntryList([for (final item in profile.conditions) item.summary]),
        const SectionHeader(ProfileStrings.medications),
        _EntryList([for (final item in profile.medications) item.summary]),
        const SectionHeader(ProfileStrings.allergies),
        _EntryList([for (final item in profile.allergies) item.summary]),
        if (!profile.habits.isEmpty) ...[
          const SectionHeader(ProfileStrings.habits),
          BotanicaCard(
            child: Column(
              children: [
                for (final (label, value) in profile.habits.facts)
                  FactRow(label: label, value: value),
              ],
            ),
          ),
        ],
        if (profile.familyHistory.isNotEmpty) ...[
          const SectionHeader(ProfileStrings.familyHistory),
          BotanicaCard(child: LabeledList(profile.familyHistory)),
        ],
      ],
    ],
  );
}

class _EntryList extends StatelessWidget {
  const _EntryList(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: BotanicaCard(
      child: items.isEmpty
          ? const Text(ProfileStrings.none)
          : LabeledList(items),
    ),
  );
}
