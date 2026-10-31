import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports its child's laid-out size whenever it changes.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderMeasureSize).onChange = onChange;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    // Report after layout so listeners can setState safely.
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(size));
  }
}
