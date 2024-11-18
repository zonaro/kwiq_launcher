import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/constants.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';
import 'package:percent_indicator/percent_indicator.dart';

Widget fileTypeWidget(String type, String size, IconData icon) {
  Color color = type.asColor;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Container(
            height: Get.height * .2,
            width: Get.width * .4,
            decoration: BoxDecoration(
              color: color == orange ? orange.withOpacity(0.8) : color,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type,
                      style: TextStyle(
                        color: color == kwiqConfig.currentColor ? Colors.black : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(size,
                      style: TextStyle(
                        color: color == orange ? Colors.black.withOpacity(0.5) : Colors.grey,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: -50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                color: color,
              ),
            ),
          )
        ],
      ),
    ),
  );
}

Widget storagePercentWidget(int totalStorage, int usedStorage) => Container(
      height: Get.width * .2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$usedStorage GB / $totalStorage GB",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  )),
              const Text("Used Storage",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  )),
            ],
          ),
          CircularPercentIndicator(
            animateFromLastPercent: true,
            animation: true,
            animationDuration: 1200,
            radius: 31.0,
            lineWidth: 5.0,
            percent: usedStorage / totalStorage,
            progressColor: kwiqConfig.currentColor,
            backgroundColor: kwiqConfig.currentColor.withOpacity(0.2),
          )
        ],
      ),
    );

Widget subtitle(FileSystemEntity entity) {
  return FutureBuilder<FileStat>(
    future: entity.stat(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        if (entity is File) {
          int size = snapshot.data!.size;

          return Text(
            FileManager.formatBytes(size),
          );
        }
        return Text(
          "${snapshot.data!.modified}".substring(0, 10),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        );
      }
      return const Text("");
    },
  );
}
