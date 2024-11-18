import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';

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
        title: Text(loc.categories),
      ),
      body: ResponsiveRow.withColumns(
        children: [
          for (var cat in categories)
            CheckboxListTile(
              title: Text(cat.toTitleCase()),
              enabled: !widget.app.category.name.flatEqual(cat),
              value: kwiqConfig.getCategoriesOf(widget.app.packageName).contains(cat),
              onChanged: (bool? value) {
                if (value!) {
                  setState(() {
                    kwiqConfig.addCategory(widget.app.packageName, cat);
                  });
                } else {
                  setState(() {
                    kwiqConfig.removeCategory(widget.app.packageName, cat);
                  });
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          var category = await context.prompt(title: loc.newItem(loc.category));
          if (category.isNotBlank) {
            setState(() {
              kwiqConfig.addCategory(widget.app.packageName, category!);
            });
          }
        },
        label: Text('${loc.add} ${loc.category}'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
