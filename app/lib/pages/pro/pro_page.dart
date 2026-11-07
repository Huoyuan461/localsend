import 'package:flutter/material.dart';
import 'package:zhichuan_app/gen/strings.g.dart';
import 'package:zhichuan_app/model/state/purchase_state.dart';
import 'package:zhichuan_app/pages/pro/pro_page_vm.dart';
import 'package:zhichuan_app/provider/purchase_provider.dart';
import 'package:zhichuan_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// Pro upsell page: feature list + buy button + restore entry.
/// Core transfers stay free; Pro only unlocks the extras listed here.
class ProPage extends StatelessWidget {
  const ProPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (ref) => proPageVmProvider,
      init: (context) => context.redux(purchaseProvider).dispatchAsync(FetchPricesAndPurchasesAction()), // ignore: discarded_futures
      builder: (context, vm) {
        final isPro = vm.purchased.contains(PurchaseItem.pro);
        // Store price once the product exists in App Store Connect / Google Play; ¥38 until then.
        final price = vm.prices[PurchaseItem.pro] ?? '¥38';
        final freeUntilLabel =
            '${kProFreeUntil.year}-${kProFreeUntil.month.toString().padLeft(2, '0')}-${kProFreeUntil.day.toString().padLeft(2, '0')}';
        return Scaffold(
          appBar: AppBar(
            title: Text(t.proPage.title),
          ),
          body: Stack(
            children: [
              ResponsiveListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Icon(
                      Icons.workspace_premium,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      t.proPage.info,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _FeatureRow(icon: Icons.history, label: t.proPage.featureHistory),
                  _FeatureRow(icon: Icons.star, label: t.proPage.featureFavorites),
                  _FeatureRow(icon: Icons.palette, label: t.proPage.featureThemes),
                  _FeatureRow(icon: Icons.folder, label: t.proPage.featureDirectory),
                  _FeatureRow(icon: Icons.support_agent, label: t.proPage.featureSupport),
                  const SizedBox(height: 30),
                  if (isPro)
                    Center(
                      child: Text(
                        t.proPage.alreadyPro,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    )
                  else if (vm.platformSupportPayment) ...[
                    Center(
                      child: FilledButton.icon(
                        onPressed: vm.pending ? null : () => vm.purchase(PurchaseItem.pro),
                        icon: const Icon(Icons.workspace_premium),
                        label: Text(t.proPage.buy(price: price)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: vm.restore,
                        icon: const Icon(Icons.restore),
                        label: Text(t.donationPage.restore),
                      ),
                    ),
                  ],
                  if (vm.freePeriodActive && !isPro)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text(
                          t.proPage.freeUntil(date: freeUntilLabel),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                ],
              ),
              if (vm.pending)
                Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

/// Pro upsell banner shown at the top of the settings tab for non-Pro users.
class ProBanner extends StatelessWidget {
  const ProBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          await context.push(() => const ProPage());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.proPage.title, style: Theme.of(context).textTheme.titleMedium),
                    Text(t.proPage.bannerSubtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
