import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactTile extends StatefulWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.gridColumns,
    this.showLabel = true,
  });

  final Contact contact;
  final int gridColumns;
  final bool showLabel;

  @override
  createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => FlutterContacts.openExternalView(widget.contact.id),
      onDoubleTap: () {
        if (widget.contact.phones.length != 1) {
          FlutterContacts.openExternalEdit(widget.contact.id);
        } else {
          launchUrlString('tel: ${widget.contact.phones.first.number}');
        }
      },
      onLongPress: () async {
        FlutterContacts.openExternalEdit(widget.contact.id);
        setState(() {});
      },
      child: Builder(builder: (context) {
        var pic = widget.contact.photo ?? widget.contact.thumbnail;
        var namePart = widget.contact.displayName.pascalSplitString.getWords.map((x) => x.first(1)).take(3).join("").toUpperCase();
        if (widget.gridColumns > 1) {
          var children = [
            CircleAvatar(
              backgroundImage: (pic) != null ? MemoryImage(pic) : null,
              child: pic == null ? AutoSizeText(namePart) : null,
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 8),
              AutoSizeText(
                widget.contact.displayName,
                textAlign: TextAlign.center,
              ),
            ]
          ];
          return GridTile(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          );
        } else {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: pic != null ? MemoryImage(pic) : null,
              child: pic == null ? AutoSizeText(namePart) : null,
            ),
            title: Text(widget.contact.displayName),
          );
        }
      }),
    );
  }
}
