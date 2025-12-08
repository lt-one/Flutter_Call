import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';

/// 自定义图标组件 - 一比一复刻Flet项目中的图标

/// 创建五角星Canvas
Widget createStarIcon({
  double size = 24,
  Color color = Colors.black,
  double strokeWidth = 2.5,
}) {
  return CustomPaint(
    size: Size(size, size),
    painter: _StarPainter(color: color, strokeWidth: strokeWidth),
  );
}

class _StarPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _StarPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width * 0.4;
    final innerRadius = size.width * 0.18;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = math.pi * i / 5 - math.pi / 2;
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 创建返回箭头Canvas
Widget createArrowIcon({
  double size = 22,
  Color color = Colors.black,
  double strokeWidth = 2.5,
}) {
  return CustomPaint(
    size: Size(size, size),
    painter: _ArrowPainter(color: color, strokeWidth: strokeWidth),
  );
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArrowPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerY = size.height / 2;
    final startX = size.width * 0.6;
    final endX = size.width * 0.3;
    final arrowHeight = size.width * 0.4;

    final path = Path()
      ..moveTo(startX, centerY - arrowHeight)
      ..lineTo(endX, centerY)
      ..lineTo(startX, centerY + arrowHeight);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 创建日历图标
Widget createCalendarIcon({
  double size = 25,
  Color color = const Color(0xFFE57D80),
  Color bgColor = const Color(0xFFFFDEE3),
}) {
  return CustomPaint(
    size: Size(size, size),
    painter: _CalendarPainter(color: color, bgColor: bgColor),
  );
}

class _CalendarPainter extends CustomPainter {
  final Color color;
  final Color bgColor;
  final double borderWidth = 1.5;
  final double contentWidth = 2.2;

  _CalendarPainter({required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 主体方框
    final boxTop = size.height * 0.25;
    final boxHeight = size.height * 0.75;
    final boxLeft = size.width * 0.1;
    final boxWidth = size.width * 0.8;

    // 填充背景
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // 边框
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
        const Radius.circular(4),
      ),
      borderPaint,
    );

    // 顶部两个耳朵
    final earHeight = size.height * 0.2;
    final earYStart = size.height * 0.15;
    final earPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = contentWidth
      ..strokeCap = StrokeCap.round;

    for (final xPos in [size.width * 0.3, size.width * 0.7]) {
      canvas.drawLine(
        Offset(xPos, earYStart),
        Offset(xPos, earYStart + earHeight),
        earPaint,
      );
    }

    // 中间横线（一长一短）
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = contentWidth
      ..strokeCap = StrokeCap.round;

    // 长横线
    final line1Y = boxTop + boxHeight * 0.35;
    canvas.drawLine(
      Offset(size.width * 0.25, line1Y),
      Offset(size.width * 0.75, line1Y),
      linePaint,
    );

    // 短横线
    final line2Y = boxTop + boxHeight * 0.65;
    canvas.drawLine(
      Offset(size.width * 0.25, line2Y),
      Offset(size.width * 0.55, line2Y),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 创建搜索图标（放大镜）
Widget createSearchIcon({
  double size = 16,
  Color color = const Color(0xFF939393),
  double strokeWidth = 2.0,
}) {
  return CustomPaint(
    size: Size(size, size),
    painter: _SearchPainter(color: color, strokeWidth: strokeWidth),
  );
}

class _SearchPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _SearchPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 圈
    final radius = size.width * 0.35;
    final centerX = size.width * 0.4;
    final centerY = size.height * 0.4;
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // 柄
    final handleLength = size.width * 0.25;
    final handleStartX = centerX + radius * 0.7;
    final handleStartY = centerY + radius * 0.7;
    final handleEndX = handleStartX + handleLength;
    final handleEndY = handleStartY + handleLength;

    canvas.drawLine(
      Offset(handleStartX, handleStartY),
      Offset(handleEndX, handleEndY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 创建电话图标（带箭头区分主叫/被叫）
Widget createPhoneIcon({
  double size = 16,
  Color color = Colors.black,
  bool isOutgoing = true,
}) {
  // SVG路径（来自Flet代码）
  final svgPath = 'M217.856 94.677333c-36.608 14.762667-60.928 38.485333-96.597333 83.2-88.618667 111.232-9.386667 332.8 194.730666 535.210667l10.581334 10.368c192 184.576 434.986667 264.533333 527.701333 184.064l3.029333-2.816-1.450666 1.194667a249.301333 249.301333 0 0 0 64.042666-77.994667c33.152-64 24.149333-130.858667-41.173333-182.954667-94.037333-75.008-157.184-77.568-219.434667-20.48l-6.997333 6.570667-18.005333 17.834667c-7.808-1.621333-19.882667-7.338667-34.730667-16.896-29.610667-19.114667-66.517333-50.901333-108.586667-92.586667-41.941333-41.642667-74.069333-78.208-93.312-107.605333l-3.882666-6.101334a120.448 120.448 0 0 1-12.245334-24.832l-0.938666-3.413333 18.133333-17.92 6.613333-6.954667c57.472-61.738667 54.912-124.373333-20.650666-217.642666-51.328-63.36-109.653333-83.328-166.826667-60.245334z m99.925333 113.493334l11.221334 14.08c37.546667 48.682667 37.888 64.853333 16.384 89.258666l-8.32 8.874667-21.12 20.821333c-45.482667 45.056-25.258667 102.314667 41.856 181.205334l14.08 16.085333 15.232 16.682667 8.106666 8.533333 16.981334 17.621333 18.176 18.261334 9.258666 9.130666 18.090667 17.450667 17.408 16.298667c5.717333 5.205333 11.306667 10.24 16.810667 15.104l16.213333 13.909333c79.616 66.56 137.216 86.570667 182.698667 41.685333l21.034666-20.992 5.546667-5.248c24.277333-22.186667 39.296-25.301333 80.725333 3.968l12.586667 9.258667 14.250667 11.093333c31.232 24.917333 34.261333 47.573333 18.602666 77.781334a165.845333 165.845333 0 0 1-26.88 36.608l-7.253333 7.338666-5.546667 5.12-5.333333 4.650667c-14.421333 14.293333-69.888 15.658667-141.184-7.722667-90.709333-29.781333-189.994667-92.074667-280.746667-182.101333-177.109333-175.658667-241.408-355.413333-188.16-422.272 26.453333-33.194667 43.648-49.92 61.653334-57.173333 19.285333-7.808 38.570667-1.194667 67.626666 34.688z';
  
  // 构建SVG字符串（使用黑色，然后通过ColorFilter着色）
  final svgString = '''
<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <path d="$svgPath" fill="#000000"/>
</svg>
''';

  return Stack(
    children: [
      // 话筒主体（SVG）
      SizedBox(
        width: size,
        height: size,
        child: SvgPicture.string(
          svgString,
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
      // 箭头层
      CustomPaint(
        size: Size(size, size),
        painter: _PhoneArrowPainter(color: color, isOutgoing: isOutgoing, size: size),
      ),
    ],
  );
}

class _PhoneArrowPainter extends CustomPainter {
  final Color color;
  final bool isOutgoing;
  final double size;

  _PhoneArrowPainter({
    required this.color,
    required this.isOutgoing,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (size / 24.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scale = size / 24.0;

    if (isOutgoing) {
      // 主叫（绿色）：箭头从话筒顶部水平指向右边
      final startX = 15 * scale;
      final startY = 6 * scale;
      final endX = 24 * scale;
      final endY = 6 * scale;

      final arrowPath = Path()
        ..moveTo(startX, startY)
        ..lineTo(endX, endY);

      canvas.drawPath(arrowPath, arrowPaint);

      // 箭头头（在右端）
      final arrowHeadPath = Path()
        ..moveTo(20 * scale, 3 * scale)
        ..lineTo(endX, endY)
        ..lineTo(20 * scale, 9 * scale);

      canvas.drawPath(arrowHeadPath, arrowPaint);
    } else {
      // 被叫（蓝色）：箭头在左上/顶侧，向内指（指向话筒）
      final startX = 20 * scale;
      final startY = 2 * scale;
      final endX = 13 * scale;
      final endY = 9 * scale;

      final arrowPath = Path()
        ..moveTo(startX, startY)
        ..lineTo(endX, endY);

      canvas.drawPath(arrowPath, arrowPaint);

      // 箭头头（在中心端）
      final arrowHeadPath = Path()
        ..moveTo(13.7 * scale, 4.1 * scale)
        ..lineTo(endX, endY)
        ..lineTo(17.9 * scale, 8.3 * scale);

      canvas.drawPath(arrowHeadPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 创建排序图标（上下箭头）
Widget createSortIcons({
  double size = 20,
  Color colorUp = const Color(0xFF353535),
  Color colorDown = const Color(0xFFA3A3A3),
}) {
  return CustomPaint(
    size: Size(size * 0.6, size),
    painter: _SortIconsPainter(colorUp: colorUp, colorDown: colorDown),
  );
}

class _SortIconsPainter extends CustomPainter {
  final Color colorUp;
  final Color colorDown;

  _SortIconsPainter({required this.colorUp, required this.colorDown});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final triangleWidth = width * 0.8;
    final triangleHeight = height * 0.28;
    final gap = height * 0.1;
    final centerX = width / 2;
    final centerY = height / 2;

    // 上箭头（尖朝上）
    final upPaint = Paint()
      ..color = colorUp
      ..style = PaintingStyle.fill;

    final upPath = Path()
      ..moveTo(centerX, centerY - gap / 2 - triangleHeight)
      ..lineTo(centerX - triangleWidth / 2, centerY - gap / 2)
      ..lineTo(centerX + triangleWidth / 2, centerY - gap / 2)
      ..close();

    canvas.drawPath(upPath, upPaint);

    // 下箭头（尖朝下）
    final downPaint = Paint()
      ..color = colorDown
      ..style = PaintingStyle.fill;

    final downPath = Path()
      ..moveTo(centerX, centerY + gap / 2 + triangleHeight)
      ..lineTo(centerX - triangleWidth / 2, centerY + gap / 2)
      ..lineTo(centerX + triangleWidth / 2, centerY + gap / 2)
      ..close();

    canvas.drawPath(downPath, downPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 创建下拉图标（等边三角形，指向下）
Widget createDropdownIcon({
  double size = 12,
  Color color = const Color(0xFF999999),
}) {
  return CustomPaint(
    size: Size(size, size),
    painter: _DropdownPainter(color: color),
  );
}

class _DropdownPainter extends CustomPainter {
  final Color color;

  _DropdownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 等边三角形高度 = sqrt(3)/2 * 边长 ≈ 0.866 * 边长
    final triangleHeight = size.width * 0.866;
    final centerX = size.width / 2;
    final yOffset = (size.width - triangleHeight) / 2;

    final path = Path()
      ..moveTo(centerX, yOffset + triangleHeight) // 下顶点（尖）
      ..lineTo(0, yOffset) // 左上
      ..lineTo(size.width, yOffset) // 右上
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 创建指纹纹路装饰图案
Widget createFingerprintPattern({
  double width = 350,
  double height = 100,
}) {
  return CustomPaint(
    size: Size(width, height),
    painter: _FingerprintPatternPainter(),
  );
}

class _FingerprintPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final numLines = 22;
    final originY = size.height + 10;
    final maxK = 52000.0;
    final minK = 1500.0;
    final pointsCount = 60;
    final endX = size.width + 80;

    for (int i = 0; i < numLines; i++) {
      final progress = i / (numLines - 1);
      final k = minK + (maxK - minK) * math.pow(1 - progress, 1.3);
      final opacity = 0.03 + 0.03 * progress;
      final stroke = 0.6 + 0.1 * (1 - progress);

      final xAtTop = k / originY;
      final startX = math.max(0.0, xAtTop);

      final path = Path();
      bool firstPoint = true;

      for (int j = 0; j <= pointsCount; j++) {
        final currX = startX + (endX - startX) * (j / pointsCount);

        if (currX > 0) {
          final curveY = k / currX;
          final screenY = originY - curveY;

          if (screenY >= -50 && screenY <= size.height + 50) {
            if (firstPoint) {
              path.moveTo(currX, screenY);
              firstPoint = false;
            } else {
              path.lineTo(currX, screenY);
            }
          }
        }
      }

      if (!firstPoint) {
        final paint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 创建三个点按钮图标
Widget createThreeDotsIcon({
  double size = 30,
  Color color = Colors.black,
}) {
  return SizedBox(
    width: size,
    height: size,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 3),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );
}

/// 创建历史记录按钮图标
Widget createHistoryIcon({
  double size = 30,
  Color color = Colors.black,
}) {
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.8),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ],
    ),
  );
}
