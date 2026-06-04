import 'package:flutter/material.dart';

/// 这是“非 IO 平台”的占位版本。
///
/// 比如 Web 平台没有 `dart:io` 的 `File` 能力，
/// 所以这里不真正加载本地文件，只返回一个提示组件。
Widget buildLocalFilePreview(String imagePath, {double height = 220}) {
  return Container(
    width: double.infinity,
    height: height,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      '当前平台不支持直接预览本地文件图片。',
    ),
  );
}
