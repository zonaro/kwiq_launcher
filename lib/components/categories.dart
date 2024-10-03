import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';

class CategoriesPage extends StatefulWidget {
  final AppInfo app;

  const CategoriesPage({super.key, required this.app});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Categories'),
      ),
      body: ResponsiveRow.withColumns(
        children: [
          for (var cat in categories)
            CheckboxListTile(
              title: Text(cat.toTitleCase),
              enabled: !widget.app.category.name.flatEqual(cat),
              value: getCategoriesOf(widget.app).contains(cat),
              onChanged: (bool? value) {
                if (value!) {
                  setState(() {
                    addCategory(widget.app, cat);
                  });
                } else {
                  setState(() {
                    removeCategory(widget.app, cat);
                  });
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          var category = await context.prompt(title: 'New Category');
          if (category.isNotBlank) {
            setState(() {
              addCategory(widget.app, category!);
            });
          }
        },
        label: const Text('Add Category'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
