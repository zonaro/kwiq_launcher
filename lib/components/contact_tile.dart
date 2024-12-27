import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactTile extends StatefulWidget {
  final Contact contact;

  final int gridColumns;
  final bool showLabel;
  const ContactTile({
    super.key,
    required this.contact,
    required this.gridColumns,
    this.showLabel = true,
  });

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
          launchUrlString('tel:${widget.contact.phones.first.number}');
        }
      },
      onLongPress: () async {
        FlutterContacts.openExternalEdit(widget.contact.id);
        setState(() {});
      },
      child: Builder(builder: (context) {
        var pic = widget.contact.photo ?? widget.contact.thumbnail;
        var namePart = widget.contact.displayName.pascalSplitString.getWords.map((x) => x.first(1)).take(3).join("").toUpperCase();
        var phone = (widget.contact.phones.firstWhereOrNull((x) => x.isPrimary)?.number ?? widget.contact.phones.firstOrDefault()?.number)?.removeLetters.removeAllWhitespace ?? widget.contact.emails.firstWhereOrNull((x) => x.isPrimary)?.address ?? widget.contact.emails.firstOrDefault()?.address;
        if (widget.gridColumns > 1) {
          var children = [
            CircleAvatar(
              backgroundImage: (pic) != null ? MemoryImage(pic) : null,
              child: pic == null ? AutoSizeText(namePart) : null,
            ),
            const Gap(10),
            if (widget.showLabel) ...[
              AutoSizeText(
                widget.contact.displayName,
                textAlign: TextAlign.center,
              ),
            ]
          ];
          return GridTile(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: children,
              ),
            ),
          );
        } else {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: pic != null ? MemoryImage(pic) : null,
              child: pic == null ? AutoSizeText(namePart) : null,
            ),
            title: Text(widget.contact.displayName),
            subtitle: phone?.asText(),
            trailing: Wrap(
              children: [
                if (hasWhatsapp && phone != null && phone.isPhoneNumber)
                  IconButton(
                    icon: Brand(
                      Brands.whatsapp,
                      size: 20,
                    ),
                    onPressed: () => launchUrlString('whatsapp://send?phone=$phone'),
                  ),
                if (phone != null && phone.isPhoneNumber)
                  IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: () async => await FlutterPhoneDirectCaller.callNumber(phone),
                  )
                else if (phone != null && phone.isEmail)
                  IconButton(
                    icon: const Icon(Icons.email),
                    onPressed: () => launchUrlString('mailto:$phone'),
                  )
              ],
            ),
          );
        }
      }),
    );
  }
}
