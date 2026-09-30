import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIP Balance & Wallet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Aura VoIP Credit',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.callGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: AppColors.callGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '\$${wallet.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Available for outgoing SIP trunks & international routing',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showRechargeModal(context, wallet),
                    icon: const Icon(CupertinoIcons.creditcard, color: Colors.white, size: 20),
                    label: const Text('Add Funds / Top-Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'QUICK TOP-UP PACKAGES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickTopUpButton(context, wallet, 10, isDark),
                const SizedBox(width: 10),
                _buildQuickTopUpButton(context, wallet, 25, isDark),
                const SizedBox(width: 10),
                _buildQuickTopUpButton(context, wallet, 50, isDark),
                const SizedBox(width: 10),
                _buildQuickTopUpButton(context, wallet, 100, isDark),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'TRANSACTION HISTORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wallet.transactions.length,
              separatorBuilder: (context, index) => Divider(
                height: 0.5,
                indent: 52,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
              itemBuilder: (context, index) {
                final txn = wallet.transactions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.callGreen.withOpacity(0.15),
                    child: const Icon(CupertinoIcons.arrow_down_left, color: AppColors.callGreen, size: 20),
                  ),
                  title: Text(
                    txn.method,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    txn.id,
                    style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+\$${txn.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.callGreen,
                        ),
                      ),
                      Text(
                        txn.status,
                        style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTopUpButton(BuildContext context, WalletProvider wallet, double amount, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Haptics.light();
          _processPayment(context, wallet, amount, 'Credit Card');
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0x22FFFFFF) : const Color(0x15000000),
            ),
          ),
          child: Column(
            children: [
              Text(
                '\$${amount.toInt()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Top-up',
                style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRechargeModal(BuildContext context, WalletProvider wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Payment Gateway',
              textAlign: TextAlign.center,
              style: AppTypography.title2,
            ),
            const SizedBox(height: 6),
            const Text(
              'Securely top up your SIP minutes with credit card or in-app purchase',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 24),
            _buildPaymentOption(
              icon: CupertinoIcons.creditcard_fill,
              title: 'Credit / Debit Card (Stripe)',
              subtitle: 'Visa, MasterCard, Amex',
              onTap: () {
                Navigator.pop(ctx);
                _processPayment(context, wallet, 25.0, 'Stripe Card');
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              icon: CupertinoIcons.device_phone_portrait,
              title: 'Google Play / App Store In-App Purchase',
              subtitle: '1-tap biometric billing',
              onTap: () {
                Navigator.pop(ctx);
                _processPayment(context, wallet, 25.0, 'Google Play IAP');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  void _processPayment(BuildContext context, WalletProvider wallet, double amount, String method) async {
    Haptics.medium();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CupertinoActivityIndicator(radius: 16),
      ),
    );

    final success = await wallet.rechargeBalance(amount, method);

    if (context.mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added \$$amount to your SIP account!'),
            backgroundColor: AppColors.callGreen,
          ),
        );
      }
    }
  }
}
