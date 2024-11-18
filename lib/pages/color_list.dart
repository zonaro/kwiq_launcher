import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:xbox_ui/xbox_ui.dart';

class ColorSearchDelegate extends SearchDelegate<Color> {
  Color _selectedColor = Colors.transparent;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, _selectedColor);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = NamedColors.values.search(searchTerms: query.split(";"), searchOn: (c) => [c.name, c.hexadecimal, c.alphaHexadecimal]).toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final color = suggestions[index];
        return XboxTile.flatColor(
          title: color.name,
          fixedFocus: true,
          backgroundColor: color,
          onTap: () {
            query = color.name;
            _selectedColor = color;
            showResults(context);
          },
          size: Size(context.width * .2, context.width * .2),
        );
      },
    );
  }
}
