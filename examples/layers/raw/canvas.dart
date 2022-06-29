// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use the ui.Canvas interface to draw various shapes
// with gradients and transforms.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  final Float64List deviceTransform = Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  final ui.SceneBuilder sceneBuilder = ui.SceneBuilder()
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();
  return sceneBuilder.build();
}

Future<void> savePicture(ui.Picture picture, ui.Rect paintBounds, String path) async {
  final File file = File(path);
  if (await file.exists()) {
    return;
  }

  final ui.Image image = await picture.toImage(paintBounds.width.toInt(), paintBounds.height.toInt());
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List pngBytes = byteData!.buffer.asUint8List();

  await file.writeAsBytes(pngBytes);
}

int frame = 0;
void beginFrame(Duration timeStamp) {
  final ui.Rect paintBounds = ui.Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio);
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder, paintBounds);
  final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
    fontStyle: ui.FontStyle.normal,
    fontWeight: ui.FontWeight.normal,
    fontSize: 15.0,
  ));

  frame++;
  builder.addText('Hello world! $frame');

  final ui.Paragraph paragraph = builder.build();
  paragraph.layout(const ui.ParagraphConstraints(width: 100.0));
  canvas.drawParagraph(paragraph, ui.Offset.zero);

  final ui.Picture picture = recorder.endRecording();
  savePicture(
    picture,
    paintBounds,
    r'C:\Users\sharm\Downloads\hello_world_text.png',
  );

  final ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);

  ui.window.scheduleFrame();
}

void main() {
  ui.PlatformDispatcher.instance
    ..onBeginFrame = beginFrame
    ..scheduleFrame();
}
