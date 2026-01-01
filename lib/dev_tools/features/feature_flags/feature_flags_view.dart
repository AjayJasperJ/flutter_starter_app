import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import 'feature_flag_controller.dart';

class FeatureFlagsView extends StatelessWidget {
  const FeatureFlagsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FeatureFlagController();

    return ListView(
      padding: EdgeInsets.all(Dimen.w16),
      children: [
        Text(
          'EXPERIMENTAL TOGGLES',
          style: TextStyle(
            color: Colors.white38,
            fontSize: Dimen.s11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: Dimen.h16),
        ValueListenableBuilder<Map<String, bool>>(
          valueListenable: controller.flags,
          builder: (context, flags, _) {
            if (flags.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: flags.entries.map((entry) {
                return _FeatureSwitch(
                  name: entry.key,
                  value: entry.value,
                  onChanged: (val) => controller.setFlag(entry.key, val),
                );
              }).toList(),
            );
          },
        ),
        SizedBox(height: Dimen.h24),
        Container(
          padding: EdgeInsets.all(Dimen.w16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(Dimen.r12),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blueAccent,
                size: Dimen.h20,
              ),
              SizedBox(width: Dimen.w12),
              Expanded(
                child: Text(
                  'Changing flags may require an app restart for some services to pick up changes.',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: Dimen.s12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureSwitch extends StatelessWidget {
  final String name;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FeatureSwitch({
    required this.name,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimen.h8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Dimen.r12),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Dimen.w16,
          vertical: Dimen.h12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Dimen.s14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: Dimen.h4),
                  Text(
                    'Persists in devtools_feature_flags',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: Dimen.s11,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.blueAccent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
