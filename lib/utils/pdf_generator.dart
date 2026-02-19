import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../providers/bhu_provider.dart';
import '../models/deposito.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

class PDFGenerator {
  static Future<Uint8List> generateResumenPDFBytes({
    required BHUProvider provider,
  }) async {
    print('DEBUG PDFGEN - Iniciando generación de PDF bytes');

    initializeDateFormatting('es_ES', null);

    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      locale: 'es_UY',
      symbol: '\$',
      decimalDigits: 2,
    );
    final uiFormat = NumberFormat.currency(
      locale: 'es_UY',
      symbol: '',
      decimalDigits: 4,
    );
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');

    final sortedDepositos = List<Deposito>.from(provider.depositos)
      ..sort(
        (a, b) =>
            _parseDate(b.depositDate).compareTo(_parseDate(a.depositDate)),
      );

    print('DEBUG PDFGEN - Depósitos ordenados: ${sortedDepositos.length}');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(pdf, provider, dateFormat, currencyFormat, uiFormat),
          pw.SizedBox(height: 20),
          _buildEstadisticas(provider, currencyFormat, uiFormat),
          pw.SizedBox(height: 20),
          _buildTodosDepositos(provider, currencyFormat, dateFormat, uiFormat),
        ],
      ),
    );

    print('DEBUG PDFGEN - Guardando PDF en memoria...');
    final bytes = await pdf.save();
    print('DEBUG PDFGEN - PDF tamaño en memoria: ${bytes.length} bytes');
    return bytes;
  }

  static Future<io.File> generateResumenPDF({
    required BHUProvider provider,
  }) async {
    if (kIsWeb) throw UnsupportedError('PDF generation using File is not supported on web');
    
    final bytes = await generateResumenPDFBytes(provider: provider);
    
    print('DEBUG PDFGEN - Guardando PDF en archivo...');
    final file = io.File(
      '${(await io.Directory.systemTemp.createTemp()).path}/bhu_resumen_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes);
    print('DEBUG PDFGEN - PDF guardado en: ${file.path}');
    return file;
  }

  static pw.Widget _buildHeader(
    pw.Document pdf,
    BHUProvider provider,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
    NumberFormat uiFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'BANCO HIPOTECARIO DEL URUGUAY',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'CONTROL DE DEPÓSITOS',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.normal,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Fecha de emisión: ${dateFormat.format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'UNIDAD INDEXADA (UI)',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '\$ ${uiFormat.format(provider.monedaData.ui)}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Última actualización: ${provider.monedaData.formattedLastUpdate}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildEstadisticas(
    BHUProvider provider,
    NumberFormat currencyFormat,
    NumberFormat uiFormat,
  ) {
    final profitPercentage = provider.totalAmount > 0
        ? (provider.profit / provider.totalAmount * 100)
        : 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'ESTADÍSTICAS GENERALES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell('Total Depositado:', true),
                _buildTableCell(
                  currencyFormat.format(provider.totalAmount),
                  false,
                  isBold: true,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Total en UI:', true),
                _buildTableCell(
                  '${uiFormat.format(provider.totalUiAmount)} UI',
                  false,
                  isBold: true,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Total de Ahorro:', true),
                _buildTableCell(
                  currencyFormat.format(provider.totalCurrentValue),
                  false,
                  isBold: true,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Ganancia total:', true),
                _buildTableCell(
                  '${currencyFormat.format(provider.profit)} (${profitPercentage >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(1)}%)',
                  false,
                  isBold: true,
                  textColor: provider.profit >= 0
                      ? PdfColors.green700
                      : PdfColors.red700,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                _buildTableCell('Depósitos realizados:', true),
                _buildTableCell('${provider.depositos.length}', false),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Promedio por depósito:', true),
                _buildTableCell(
                  provider.depositos.isNotEmpty
                      ? currencyFormat.format(
                          provider.totalAmount / provider.depositos.length,
                        )
                      : '\$ 0,00',
                  false,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Depósito mayor:', true),
                _buildTableCell(
                  provider.depositos.isNotEmpty
                      ? currencyFormat.format(
                          provider.depositos
                              .map((d) => d.amount)
                              .reduce((a, b) => a > b ? a : b),
                        )
                      : '\$ 0,00',
                  false,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Depósito menor:', true),
                _buildTableCell(
                  provider.depositos.isNotEmpty
                      ? currencyFormat.format(
                          provider.depositos
                              .map((d) => d.amount)
                              .reduce((a, b) => a < b ? a : b),
                        )
                      : '\$ 0,00',
                  false,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    bool isHeader, {
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isBold
              ? pw.FontWeight.bold
              : (isHeader ? pw.FontWeight.normal : pw.FontWeight.normal),
          color: textColor ?? PdfColors.black,
          fontSize: 10,
        ),
      ),
    );
  }

  static pw.Widget _buildTodosDepositos(
    BHUProvider provider,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    NumberFormat uiFormat,
  ) {
    final sortedDepositos = List<Deposito>.from(provider.depositos)
      ..sort(
        (a, b) =>
            _parseDate(b.depositDate).compareTo(_parseDate(a.depositDate)),
      );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'TODOS LOS DEPÓSITOS (${sortedDepositos.length})',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        if (sortedDepositos.isEmpty)
          pw.Text(
            'No hay depósitos registrados',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.4),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.3),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(0.7),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  _buildHeaderCell('ID'),
                  _buildHeaderCell('Fecha'),
                  _buildHeaderCell('Cliente'),
                  _buildHeaderCell('Monto'),
                  _buildHeaderCell('UI'),
                  _buildHeaderCell('Ganancia'),
                ],
              ),
              ...sortedDepositos.map((deposito) {
                final profit = (deposito.uiAmount * provider.monedaData.ui) -
                    deposito.amount;
                final profitText = profit >= 0
                    ? '+${currencyFormat.format(profit)}'
                    : currencyFormat.format(profit);
                final profitColor =
                    profit >= 0 ? PdfColors.green700 : PdfColors.red700;

                return pw.TableRow(
                  children: [
                    _buildCell('${deposito.id}'),
                    _buildCell(
                      dateFormat.format(_parseDate(deposito.depositDate)),
                    ),
                    _buildCell('-'),
                    _buildCell(currencyFormat.format(deposito.amount)),
                    _buildCell(uiFormat.format(deposito.uiAmount)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        profitText,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: profitColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
      ],
    );
  }

  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  static pw.Widget _buildCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }
}
