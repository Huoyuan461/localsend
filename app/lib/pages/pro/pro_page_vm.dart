import 'package:refena_flutter/refena_flutter.dart';
import 'package:zhichuan_app/model/state/purchase_state.dart';
import 'package:zhichuan_app/provider/purchase_provider.dart';
import 'package:zhichuan_app/util/native/platform_check.dart';

class ProPageVm {
  final bool platformSupportPayment;
  final Map<PurchaseItem, String> prices;
  final Set<PurchaseItem> purchased;
  final bool pending;
  final bool freePeriodActive;
  final void Function(PurchaseItem item) purchase;
  final void Function() restore;

  ProPageVm({
    required this.platformSupportPayment,
    required this.prices,
    required this.purchased,
    required this.pending,
    required this.freePeriodActive,
    required this.purchase,
    required this.restore,
  });
}

final proPageVmProvider = ViewProvider<ProPageVm>((ref) {
  final state = ref.watch(purchaseProvider);
  return ProPageVm(
    platformSupportPayment: checkPlatformSupportPayment(),
    prices: state.prices,
    purchased: state.purchases,
    pending: state.pending,
    freePeriodActive: DateTime.now().isBefore(kProFreeUntil),
    purchase: (item) => ref.redux(purchaseProvider).dispatchAsync(PurchaseAction(item)),
    restore: () => ref.redux(purchaseProvider).dispatchAsync(PurchaseRestoreAction()),
  );
});
