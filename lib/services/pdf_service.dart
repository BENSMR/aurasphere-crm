// lib/services/pdf_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<File> generateInvoice({
    required String invoiceNumber,
    required String clientName,
    required double amount,
    required String currency,
    required String language,
    DateTime? dueDate,
  }) async {
    final pdf = pw.Document();

    // Multilingual labels
    final labels = _getLabels(language);
    
    final currencySymbol = _getCurrencySymbol(currency);
    final formattedAmount = '$currencySymbol${amount.toStringAsFixed(2)}';

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('AURASPHERE CRM', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(labels['invoice']!, style: const pw.TextStyle(fontSize: 18)),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Invoice details
            pw.Row(
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(labels['from']!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Aurasphere CRM'),
                    pw.Text('hello@aura-sphere.app'),
                  ],
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(labels['to']!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(clientName),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            
            // Invoice number & date
            pw.Row(
              children: [
                pw.Text('${labels['number']}: $invoiceNumber'),
                pw.Spacer(),
                pw.Text('${labels['date']}: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Amount section
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              color: PdfColors.grey200,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(labels['totalAmount']!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(formattedAmount, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Due date
            if (dueDate != null)
              pw.Text('${labels['dueDate']}: ${dueDate.toLocal().toString().split(' ')[0]}'),
            
            pw.Spacer(),
            
            // Footer
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              child: pw.Center(
                child: pw.Text(
                  labels['footer']!,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Save to file
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/invoice_$invoiceNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Map<String, String> _getLabels(String language) {
    switch (language) {
      case 'fr':
        return {
          'invoice': 'FACTURE',
          'from': 'De',
          'to': 'À',
          'number': 'Numéro',
          'date': 'Date',
          'totalAmount': 'Montant total',
          'dueDate': "Date d'échéance",
          'footer': 'Facture générée par Aurasphere CRM - Logiciel de gestion pour freelances',
        };
      case 'it':
        return {
          'invoice': 'FATTURA',
          'from': 'Da',
          'to': 'A',
          'number': 'Numero',
          'date': 'Data',
          'totalAmount': 'Importo totale',
          'dueDate': 'Data di scadenza',
          'footer': 'Fattura generata da Aurasphere CRM - Software di gestione per freelance',
        };
      case 'de':
        return {
          'invoice': 'RECHNUNG',
          'from': 'Von',
          'to': 'An',
          'number': 'Nummer',
          'date': 'Datum',
          'totalAmount': 'Gesamtbetrag',
          'dueDate': 'Fälligkeitsdatum',
          'footer': 'Rechnung erstellt von Aurasphere CRM - Freelancer-Management-Software',
        };
      case 'es':
        return {
          'invoice': 'FACTURA',
          'from': 'De',
          'to': 'Para',
          'number': 'Número',
          'date': 'Fecha',
          'totalAmount': 'Monto total',
          'dueDate': 'Fecha de vencimiento',
          'footer': 'Factura generada por Aurasphere CRM - Software de gestión para freelancers',
        };
      case 'mt':
        return {
          'invoice': 'FATTURA',
          'from': 'Minn',
          'to': 'Lil',
          'number': 'Numru',
          'date': 'Data',
          'totalAmount': 'Ammont totali',
          'dueDate': 'Data ta\' skadenza',
          'footer': 'Fattura ġġenerata minn Aurasphere CRM - Softwer ta\' ġestjoni għal freelancers',
        };
      case 'ar':
      case 'ar_MA':
      case 'ar_EG':
        return {
          'invoice': 'فاتورة',
          'from': 'من',
          'to': 'إلى',
          'number': 'رقم',
          'date': 'تاريخ',
          'totalAmount': 'المبلغ الإجمالي',
          'dueDate': 'تاريخ الاستحقاق',
          'footer': 'فاتورة تم إنشاؤها بواسطة Aurasphere CRM - برنامج إدارة للعملاء المستقلين',
        };
      default:
        return {
          'invoice': 'INVOICE',
          'from': 'From',
          'to': 'To',
          'number': 'Number',
          'date': 'Date',
          'totalAmount': 'Total Amount',
          'dueDate': 'Due Date',
          'footer': 'Invoice generated by Aurasphere CRM - Freelancer management software',
        };
    }
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD': return '\$';
      case 'AED': return 'د.إ ';
      case 'TND': return 'د.ت ';
      case 'MAD': return 'د.م.م ';
      default: return '€';
    }
  }
}
