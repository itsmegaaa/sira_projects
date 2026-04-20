// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sira_projects/data/models/mandiri_model.dart'; // IMPORT MODEL

class OrderCard extends StatelessWidget {
  final OrderModel item; // MENGGUNAKAN ORDERMODEL
  final bool isDark;
  final bool isSelesai;
  final bool isTelat;
  final bool isMenunggu;
  final int sisaHari;
  final Color warnaStatus;
  final String teksStatus;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final DismissDirection dismissDirection;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;
  final void Function(DismissDirection)? onDismissed;

  const OrderCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.isSelesai,
    required this.isTelat,
    required this.isMenunggu,
    required this.sisaHari,
    required this.warnaStatus,
    required this.teksStatus,
    required this.onTap,
    this.onLongPress,
    required this.dismissDirection,
    this.confirmDismiss,
    this.onDismissed,
  });

  String formatTgl(DateTime? dt) =>
      dt != null ? DateFormat('dd MMM yyyy').format(dt) : '-';

  @override
  Widget build(BuildContext context) {
    Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF2D3142);

    return Dismissible(
      key: Key(item.id),
      direction: dismissDirection,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.red.withOpacity(0.2) : const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.red.shade900 : Colors.red.shade100,
          ),
        ),
        child: Icon(
          Icons.delete_outline,
          color: isDark ? Colors.red.shade300 : Colors.red,
          size: 28,
        ),
      ),
      confirmDismiss: confirmDismiss,
      onDismissed: onDismissed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(color: Colors.grey.shade800)
              : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.debitur.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: warnaStatus.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          teksStatus,
                          style: TextStyle(
                            color: warnaStatus,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.noSurat} • ${item.jenis}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.kcu} - PIC: ${item.picBank}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.picInternal.isEmpty
                                ? 'Belum ada'
                                : item.picInternal,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      isSelesai
                          ? Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Selesai',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: warnaStatus,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatTgl(item.deadline),
                                  style: TextStyle(
                                    color: warnaStatus,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                if (!isMenunggu) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isTelat
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${DateTime.now().difference(item.tglOrder ?? DateTime.now()).inDays}h',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: isTelat
                                            ? Colors.red
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
