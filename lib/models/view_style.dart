/// 信息流视图风格
enum ViewStyle {
  /// Apple News 风格：大图铺满，无边卡片，排版干净
  news('杂志', 'news'),

  /// 纯黑极简：深色背景，文字优先，无图
  minimal('极简', 'minimal'),

  /// 毛玻璃：封面模糊背景 + 半透明卡片
  glass('玻璃', 'glass');

  final String label;
  final String id;
  const ViewStyle(this.label, this.id);

  static ViewStyle fromId(String id) {
    return ViewStyle.values.firstWhere((v) => v.id == id, orElse: () => news);
  }
}
