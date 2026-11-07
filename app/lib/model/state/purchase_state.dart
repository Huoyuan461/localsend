import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';

part 'purchase_state.mapper.dart';

enum PurchaseItem {
  donate5(
    androidId: 'zhichuan_android_donate_5',
    iosId: 'zhichuan_ios_donate_5',
  ),
  donate10(
    androidId: 'zhichuan_android_donate_10',
    iosId: 'zhichuan_ios_donate_10',
  ),
  donate20(
    androidId: 'zhichuan_android_donate_20',
    iosId: 'zhichuan_ios_donate_20',
  ),
  donate50(
    androidId: 'zhichuan_android_donate_50',
    iosId: 'zhichuan_ios_donate_50',
  ),
  pro(
    androidId: 'zhichuan_android_pro',
    iosId: 'zhichuan_ios_pro',
  )
  ;

  const PurchaseItem({
    required this.androidId,
    required this.iosId,
  });

  final String androidId;
  final String iosId;

  String get platformProductId => defaultTargetPlatform == TargetPlatform.android ? androidId : iosId;
}

/// Pro 上线免费期截止日：App 上线后前两周 Pro 免费开放，之后恢复 ¥38 买断。
/// 随 Pro 版本实际上线日期调整（1.0 于 2026-11-06 提交审核，Pro 随下一版上，免费期暂定到 2026-11-26）。
const kProFreeUntil = DateTime.utc(2026, 11, 26);

/// Whether the given purchase set counts as Pro.
/// Note: also true during the launch free period ([kProFreeUntil]).
bool isProPurchaseSet(Set<PurchaseItem> purchases) => purchases.contains(PurchaseItem.pro) || DateTime.now().isBefore(kProFreeUntil);

@MappableClass()
class PurchaseState with PurchaseStateMappable {
  final Map<PurchaseItem, String> prices;
  final Set<PurchaseItem> purchases;
  final bool pending;

  const PurchaseState({
    required this.prices,
    required this.purchases,
    required this.pending,
  });

  /// Whether Pro features are unlocked: bought Pro, or inside the launch free period.
  bool get isPro => isProPurchaseSet(purchases);
}
