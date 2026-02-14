import 'package:flutter/material.dart';

class TvContentRow extends StatelessWidget {
  final String title;
  final List<dynamic> items; // Can be a generic model list
  // Builder function to create a card from an item
  final Widget Function(BuildContext context, dynamic item, int index)
      itemBuilder;
  final double height;

  const TvContentRow({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.height = 220, // Default height for card + text
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 40, bottom: 10, top: 20),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return itemBuilder(context, items[index], index);
            },
          ),
        ),
      ],
    );
  }
}
