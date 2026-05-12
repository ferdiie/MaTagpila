// lib/screens/reports_screen.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

// Platform-conditional imports
import '../utils/pdf_save_helper.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/models/price_item_model.dart';
import '../features/transactions/models/transaction_model.dart';
import '../features/shared/services/firestore_services.dart';

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange _txRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  final Map<String, bool> _loading = {
    'price_list': false,
    'transactions': false,
    'by_category': false,
  };

  final _dateFmt = DateFormat('MMM d, y');
  final _priceFmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  // ── PDF Brand Colors ──────────────────────────
  static final _orange = PdfColor.fromHex('#FF6B00');
  static final _orangeLight = PdfColor.fromHex('#FFF3E8');
  static final _textDark = PdfColor.fromHex('#1A1A1A');
  static final _textGrey = PdfColor.fromHex('#666666');
  static final _divider = PdfColor.fromHex('#F0F0F0');
  static const _white = PdfColors.white;
  static final _green = PdfColor.fromHex('#2E7D32');

  void _setLoading(String key, bool val) => setState(() => _loading[key] = val);

  // ─────────────────────────────────────────────
  //  1. FULL PRICE LIST
  // ─────────────────────────────────────────────
  Future<void> _generatePriceList() async {
    _setLoading('price_list', true);
    try {
      final storeId = ref.read(effectiveStoreIdProvider);
      final items =
          await ref.read(pricesServiceProvider).getPricesForStore(storeId);
      if (!mounted) return;

      final pdf = pw.Document();
      final now = DateTime.now();
      final chunks = _chunk(items, 25);

      for (int p = 0; p < chunks.length; p++) {
        final chunk = chunks[p];
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (p == 0) ...[
                  _pdfHeader(
                    title: 'Full Price List',
                    subtitle:
                        'Generated ${DateFormat('MMMM d, y – h:mm a').format(now)}',
                  ),
                  pw.SizedBox(height: 20),
                ],
                pw.Table(
                  border: pw.TableBorder(
                    horizontalInside:
                        pw.BorderSide(color: _divider, width: 0.5),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: _orange),
                      children: [
                        _tableHead('Product Name'),
                        _tableHead('Category'),
                        _tableHead('Unit'),
                        _tableHead('Price', align: pw.TextAlign.right),
                      ],
                    ),
                    ...chunk.asMap().entries.map((e) {
                      final isEven = e.key % 2 == 0;
                      final item = e.value;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            color: isEven ? _white : _orangeLight),
                        children: [
                          _tableCell(item.name),
                          _tableCell(
                              item.category.isNotEmpty ? item.category : '—',
                              color: _textGrey),
                          _tableCell(item.unit),
                          _tableCell(
                            _priceFmt.format(item.price),
                            align: pw.TextAlign.right,
                            bold: true,
                            color: _orange,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.Spacer(),
                _pdfFooter(
                    'Ma.Tagpila Price List  •  ${items.length} products  •  Page ${p + 1} of ${chunks.length}'),
              ],
            ),
          ),
        );
      }

      await _saveAndOpen(pdf, 'PriceList_${_fileDate(now)}.pdf');
    } catch (e) {
      _showError('Failed to generate Price List: $e');
    } finally {
      _setLoading('price_list', false);
    }
  }

  // ─────────────────────────────────────────────
  //  2. TRANSACTION REPORT
  //  Uses: timestamp, totalAmount, cashGiven,
  //        change, items (List<dynamic>)
  // ─────────────────────────────────────────────
  Future<void> _generateTransactionReport() async {
    _setLoading('transactions', true);
    try {
      final storeId = ref.read(effectiveStoreIdProvider);
      final txList =
          await ref.read(transactionsServiceProvider).getTransactionsByRange(
                sellerId: storeId,
                from: _txRange.start,
                to: _txRange.end,
              );
      if (!mounted) return;

      final pdf = pw.Document();

      // ── Summary numbers ──
      final totalRevenue =
          txList.fold<double>(0, (sum, tx) => sum + tx.totalAmount);
      final totalItems =
          txList.fold<int>(0, (sum, tx) => sum + (tx.items.length));

      final chunks = _chunk(txList, 18);

      for (int p = 0; p < (chunks.isEmpty ? 1 : chunks.length); p++) {
        final chunk = p < chunks.length ? chunks[p] : <TransactionModel>[];
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Header (first page only) ──
                if (p == 0) ...[
                  _pdfHeader(
                    title: 'Transaction Report',
                    subtitle:
                        '${_dateFmt.format(_txRange.start)} – ${_dateFmt.format(_txRange.end)}',
                  ),
                  pw.SizedBox(height: 10),
                  // Summary chips row
                  pw.Row(children: [
                    _summaryChip('Transactions', '${txList.length}'),
                    pw.SizedBox(width: 8),
                    _summaryChip('Items Sold', '$totalItems'),
                    pw.SizedBox(width: 8),
                    _summaryChip(
                        'Total Revenue', _priceFmt.format(totalRevenue),
                        valueColor: _green),
                  ]),
                  pw.SizedBox(height: 16),
                ],

                // ── Empty state ──
                if (chunk.isEmpty)
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(40),
                      child: pw.Text(
                        'No transactions found in this date range.',
                        style: pw.TextStyle(color: _textGrey, fontSize: 12),
                      ),
                    ),
                  )
                else ...[
                  // ── Transactions table ──
                  pw.Table(
                    border: pw.TableBorder(
                      horizontalInside:
                          pw.BorderSide(color: _divider, width: 0.5),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.2), // Date
                      1: const pw.FlexColumnWidth(0.8), // Items
                      2: const pw.FlexColumnWidth(2), // Total
                      3: const pw.FlexColumnWidth(2), // Cash Given
                      4: const pw.FlexColumnWidth(1.8), // Change
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: _orange),
                        children: [
                          _tableHead('Date & Time'),
                          _tableHead('Items', align: pw.TextAlign.center),
                          _tableHead('Total', align: pw.TextAlign.right),
                          _tableHead('Cash Given', align: pw.TextAlign.right),
                          _tableHead('Change', align: pw.TextAlign.right),
                        ],
                      ),
                      ...chunk.asMap().entries.map((e) {
                        final isEven = e.key % 2 == 0;
                        final tx = e.value;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                              color: isEven ? _white : _orangeLight),
                          children: [
                            // Date & time
                            _tableCell(
                              DateFormat('MMM d, y\nh:mm a')
                                  .format(tx.timestamp),
                              color: _textGrey,
                            ),
                            // Item count
                            _tableCell(
                              '${tx.items.length}',
                              align: pw.TextAlign.center,
                            ),
                            // Total amount
                            _tableCell(
                              _priceFmt.format(tx.totalAmount),
                              align: pw.TextAlign.right,
                              bold: true,
                              color: _orange,
                            ),
                            // Cash given
                            _tableCell(
                              _priceFmt.format(tx.cashGiven),
                              align: pw.TextAlign.right,
                            ),
                            // Change
                            _tableCell(
                              _priceFmt.format(tx.change),
                              align: pw.TextAlign.right,
                              color: _green,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),

                  // ── Per-transaction item breakdown ──
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'ITEM BREAKDOWN',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _textGrey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...chunk.map((tx) {
                    final txItems = List<Map<String, dynamic>>.from(
                      tx.items.map((i) =>
                          i is Map<String, dynamic> ? i : <String, dynamic>{}),
                    );
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#FAFAFA'),
                        border: pw.Border.all(color: _divider, width: 0.5),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Transaction header
                          pw.Row(children: [
                            pw.Text(
                              DateFormat('MMM d, y – h:mm a')
                                  .format(tx.timestamp),
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: _orange,
                              ),
                            ),
                            pw.Spacer(),
                            pw.Text(
                              'Total: ${_priceFmt.format(tx.totalAmount)}',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                          ]),
                          pw.SizedBox(height: 4),
                          // Items list
                          if (txItems.isEmpty)
                            pw.Text('No item details available.',
                                style:
                                    pw.TextStyle(fontSize: 7, color: _textGrey))
                          else
                            ...txItems.map((item) {
                              final name = (item['name'] ??
                                      item['productName'] ??
                                      'Unknown')
                                  .toString();
                              final qty = item['quantity'] ?? item['qty'] ?? 1;
                              final price = (item['price'] ??
                                  item['unitPrice'] ??
                                  0.0) as num;
                              final subtotal = (item['subtotal'] ??
                                  item['total'] ??
                                  (price * (qty as num))) as num;
                              return pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 2),
                                child: pw.Row(children: [
                                  pw.Text('• $name',
                                      style: pw.TextStyle(
                                          fontSize: 7, color: _textDark)),
                                  pw.Spacer(),
                                  pw.Text(
                                    'x$qty  ${_priceFmt.format(subtotal)}',
                                    style: pw.TextStyle(
                                        fontSize: 7, color: _textGrey),
                                  ),
                                ]),
                              );
                            }),
                        ],
                      ),
                    );
                  }),
                ],

                pw.Spacer(),
                _pdfFooter(
                    'Ma.Tagpila Transactions  •  Page ${p + 1} of ${chunks.isEmpty ? 1 : chunks.length}'),
              ],
            ),
          ),
        );
      }

      await _saveAndOpen(
        pdf,
        'Transactions_${_fileDate(_txRange.start)}_to_${_fileDate(_txRange.end)}.pdf',
      );
    } catch (e) {
      _showError('Failed to generate Transaction Report: $e');
    } finally {
      _setLoading('transactions', false);
    }
  }

  // ─────────────────────────────────────────────
  //  3. PRODUCTS BY CATEGORY
  // ─────────────────────────────────────────────
  Future<void> _generateByCategory() async {
    _setLoading('by_category', true);
    try {
      final storeId = ref.read(effectiveStoreIdProvider);
      final items =
          await ref.read(pricesServiceProvider).getPricesForStore(storeId);
      if (!mounted) return;

      final Map<String, List<PriceItem>> grouped = {};
      for (final item in items) {
        final cat = item.category.isNotEmpty ? item.category : 'Uncategorized';
        grouped.putIfAbsent(cat, () => []).add(item);
      }
      final sortedKeys = grouped.keys.toList()..sort();

      final pdf = pw.Document();
      final now = DateTime.now();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (ctx) => _pdfFooter(
              'Ma.Tagpila Category Report  •  ${items.length} products  •  Page ${ctx.pageNumber} of ${ctx.pagesCount}'),
          build: (ctx) => [
            _pdfHeader(
              title: 'Products by Category',
              subtitle:
                  'Generated ${DateFormat('MMMM d, y – h:mm a').format(now)}',
            ),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              _summaryChip('Total Products', '${items.length}'),
              pw.SizedBox(width: 12),
              _summaryChip('Categories', '${sortedKeys.length}'),
            ]),
            pw.SizedBox(height: 20),
            ...sortedKeys.map((cat) {
              final catItems = grouped[cat]!
                ..sort((a, b) => a.name.compareTo(b.name));
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: _orange,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Row(children: [
                      pw.Text(
                        cat.toUpperCase(),
                        style: pw.TextStyle(
                          color: _white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        '${catItems.length} item${catItems.length == 1 ? '' : 's'}',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#FFD4A8'),
                          fontSize: 9,
                        ),
                      ),
                    ]),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Table(
                    border: pw.TableBorder(
                      horizontalInside:
                          pw.BorderSide(color: _divider, width: 0.5),
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: _orangeLight),
                        children: [
                          _tableHead('Product Name', color: _textDark),
                          _tableHead('Unit', color: _textDark),
                          _tableHead('Price',
                              align: pw.TextAlign.right, color: _textDark),
                        ],
                      ),
                      ...catItems.asMap().entries.map((e) {
                        final isEven = e.key % 2 == 0;
                        final item = e.value;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                              color: isEven
                                  ? _white
                                  : PdfColor.fromHex('#FAFAFA')),
                          children: [
                            _tableCell(item.name),
                            _tableCell(item.unit, color: _textGrey),
                            _tableCell(
                              _priceFmt.format(item.price),
                              align: pw.TextAlign.right,
                              bold: true,
                              color: _orange,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      );

      await _saveAndOpen(pdf, 'ByCategory_${_fileDate(now)}.pdf');
    } catch (e) {
      _showError('Failed to generate Category Report: $e');
    } finally {
      _setLoading('by_category', false);
    }
  }

  // ─────────────────────────────────────────────
  //  PDF HELPERS
  // ─────────────────────────────────────────────
  pw.Widget _pdfHeader({
    required String title,
    required String subtitle,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_orange, PdfColor.fromHex('#FF8C38')],
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Ma.Tagpila',
            style: pw.TextStyle(
              color: PdfColor.fromHex('#FFD4A8'),
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _white,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#FFE8D0'),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryChip(String label, String value, {PdfColor? valueColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _orangeLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        border: pw.Border.all(color: _orange, width: 0.5),
      ),
      child: pw.Row(children: [
        pw.Text('$label: ', style: pw.TextStyle(fontSize: 8, color: _textGrey)),
        pw.Text(value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? _orange,
            )),
      ]),
    );
  }

  pw.Widget _tableHead(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color ?? _white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color ?? _textDark,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.Widget _pdfFooter(String text) {
    return pw.Column(children: [
      pw.Divider(color: _divider, thickness: 0.5),
      pw.SizedBox(height: 4),
      pw.Text(
        text,
        style: pw.TextStyle(color: _textGrey, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    ]);
  }

  Future<void> _saveAndOpen(pw.Document pdf, String filename) async {
    final bytes = Uint8List.fromList(await pdf.save());
    final path = await PdfSaveHelper.save(bytes, filename);
    if (!mounted) return;
    _showDownloadSuccess(path, filename);
  }

  String _fileDate(DateTime dt) => DateFormat('yyyyMMdd').format(dt);

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      result.add(
          list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    if (result.isEmpty) result.add([]);
    return result;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showDownloadSuccess(String? path, String filename) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DownloadSuccessSheet(
        filename: filename,
        onOpen: (path == null || kIsWeb)
            ? null
            : () {
                Navigator.pop(context);
                PdfSaveHelper.open(path);
              },
        onShare: path == null
            ? null
            : () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(path)], subject: filename);
              },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  DATE RANGE PICKER
  // ─────────────────────────────────────────────
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _txRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _txRange = picked);
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.orange),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Reports', style: AppTextStyles.headingLg),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF8C38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate & Download',
                          style: AppTextStyles.headingLg
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Export reports as PDF for printing or sharing.',
                          style: AppTextStyles.bodySm
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Report 1 ──────────────────────────
            const _SectionLabel(text: 'Inventory'),
            const SizedBox(height: 10),
            _ReportCard(
              icon: Icons.format_list_bulleted_rounded,
              iconBg: const Color(0xFFEEF4FF),
              iconColor: const Color(0xFF4A7EFF),
              title: 'Full Price List',
              description:
                  'All products with current prices, unit, and category. Great for printing and posting in-store.',
              badge: 'All Products',
              badgeColor: const Color(0xFF4A7EFF),
              isLoading: _loading['price_list']!,
              onGenerate: _generatePriceList,
            ),

            const SizedBox(height: 28),

            // ── Report 2 ──────────────────────────
            const _SectionLabel(text: 'Transactions'),
            const SizedBox(height: 10),

            // Date range selector
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        color: AppColors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date Range',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: Colors.grey, fontSize: 11)),
                          Text(
                            '${_dateFmt.format(_txRange.start)}  →  ${_dateFmt.format(_txRange.end)}',
                            style: AppTextStyles.headingSm,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orangeSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Change',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _ReportCard(
              icon: Icons.receipt_long_rounded,
              iconBg: const Color(0xFFF0FFF4),
              iconColor: const Color(0xFF2E7D32),
              title: 'Transaction Report',
              description:
                  'All transactions in the selected date range — totals, cash given, change, and full item breakdown per transaction.',
              badge:
                  '${_txRange.end.difference(_txRange.start).inDays + 1}-day range',
              badgeColor: const Color(0xFF2E7D32),
              isLoading: _loading['transactions']!,
              onGenerate: _generateTransactionReport,
            ),

            const SizedBox(height: 28),

            // ── Report 3 ──────────────────────────
            const _SectionLabel(text: 'Inventory by Category'),
            const SizedBox(height: 10),
            _ReportCard(
              icon: Icons.category_rounded,
              iconBg: const Color(0xFFFFF8E1),
              iconColor: const Color(0xFFF57C00),
              title: 'Products by Category',
              description:
                  'All products organized by category. Useful for a structured inventory overview.',
              badge: 'Grouped View',
              badgeColor: const Color(0xFFF57C00),
              isLoading: _loading['by_category']!,
              onGenerate: _generateByCategory,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REPORT CARD
// ─────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;
  final bool isLoading;
  final VoidCallback onGenerate;

  const _ReportCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headingLg),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: AppTextStyles.bodySm.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.bodySm
                .copyWith(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(
                isLoading ? 'Generating…' : 'Generate PDF',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.orange.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DOWNLOAD SUCCESS SHEET
// ─────────────────────────────────────────────
class _DownloadSuccessSheet extends StatelessWidget {
  final String filename;
  final VoidCallback? onOpen; // nullable — hidden on web
  final VoidCallback? onShare; // nullable — hidden on web

  const _DownloadSuccessSheet({
    required this.filename,
    this.onOpen,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF0FFF4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF2E7D32), size: 36),
          ),
          const SizedBox(height: 14),
          Text('Report Ready!', style: AppTextStyles.headingLg),
          const SizedBox(height: 6),
          Text(filename,
              style: AppTextStyles.bodySm.copyWith(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // Only show buttons if callbacks are available (hidden on web)
          if (onShare != null || onOpen != null)
            Row(
              children: [
                if (onShare != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.orange,
                          side: const BorderSide(
                              color: AppColors.orange, width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  if (onOpen != null) const SizedBox(width: 12),
                ],
                if (onOpen != null)
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open PDF',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          // Web-only message when no buttons shown
          if (onShare == null && onOpen == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_done_rounded,
                      color: Color(0xFF2E7D32), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Downloaded to your device',
                    style: AppTextStyles.bodySm
                        .copyWith(color: const Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.bodySm.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
      ),
    );
  }
}
