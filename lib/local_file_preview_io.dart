import 'dart:io';

import 'package:flutter/material.dart';

/// 这是“支持 dart:io 平台”的版本。
///
/// 在 Android / iOS / macOS / Windows / Linux 这类支持 `File` 的平台上，
/// 我们可以直接通过 `Image.file` 显示本地图片。
Widget buildLocalFilePreview(String imagePath, {double height = 220}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.file(
      File(imagePath),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.black12,
          child: Text('图片加载失败：$error'),
        );
      },
    ),
  );
}
