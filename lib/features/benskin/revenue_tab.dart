import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RevenueTab extends StatefulWidget {
  const RevenueTab({super.key});

  @override
  State<RevenueTab> createState() => _RevenueTabState();
}

class _RevenueTabState extends State<RevenueTab> {
  int _selectedDay = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Mon Portefeuille',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 20)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 28),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _balanceCard(),
          const SizedBox(height: 14),
          _dailyGoalCard(6, 10),
          const SizedBox(height: 14),
          _performanceCard(),
          const SizedBox(height: 20),
          const Text('Courses du jour',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 10),
          _courseTile('Poulet DG Royal', '14:45', 'Bastos', 'Akwa', 1250),
          _courseTile('Ndolé Crevettes', '12:30', 'Bonapriso', 'Bali', 2100),
          _courseTile('Eru & Waterfufu', '11:15', 'Deido', 'Bonamoussadi', 950),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 72,
            child: ElevatedButton.icon(
              onPressed: () => _showTransferSheet(context),
              icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
              label: const Text(
                'Transférer vers MoMo/OM',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SOLDE DISPONIBLE',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          const Text(
            '45 800 FCFA',
            style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: 36,
                color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.ctaGreen,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Compte Vérifié',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyGoalCard(int done, int goal) {
    final pct = done / goal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                Text('${(pct * 100).round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OBJECTIF DU JOUR',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text('$done / $goal courses',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  done >= goal
                      ? 'Objectif atteint ! 🎉'
                      : 'Encore ${goal - done} pour viser le bonus',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _performanceCard() {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const values = [0.4, 0.6, 0.5, 0.7, 0.9, 0.8, 1.0];
    const amounts = [12500, 18200, 15400, 21000, 27800, 24500, 30100];
    const todayIndex = 4;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance 7 derniers jours',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('124 500 FCFA',
              style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isSelected = i == _selectedDay;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_fmt(amounts[i])} F',
                                style: const TextStyle(
                                  fontFamily: 'SpaceMono',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 18),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 90 * values[i],
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold
                                  : i == todayIndex
                                      ? AppColors.ctaGreen
                                      : AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(days[i],
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _courseTile(
      String name, String time, String from, String to, int gain) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(time,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(from,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.arrow_right_alt,
                                size: 16, color: AppColors.primary),
                          ),
                          Flexible(
                            child: Text(to,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$gain FCFA',
            style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _providerChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: selected ? 2 : 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showTransferSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String provider = 'MTN';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transférer vers MoMo/OM',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _providerChip(
                        label: 'MTN MoMo',
                        color: const Color(0xFFFFCC00),
                        selected: provider == 'MTN',
                        onTap: () => setState(() => provider = 'MTN'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _providerChip(
                        label: 'Orange Money',
                        color: const Color(0xFFF57C20),
                        selected: provider == 'OM',
                        onTap: () => setState(() => provider = 'OM'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _providerChip(
                        label: 'Falla MoMo',
                        color: const Color(0xFF1B4332),
                        selected: provider == 'FALLA',
                        onTap: () => setState(() => provider = 'FALLA'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.ctaGreen,
                          content: Text(
                              'Transfert de ${amountCtrl.text} FCFA vers $provider initié'),
                        ),
                      );
                    },
                    child: const Text('Confirmer le transfert',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
