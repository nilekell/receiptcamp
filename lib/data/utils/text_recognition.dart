import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  static Future<List<String>> extractKeywordsFromPath(String imagePath) async {
    try {
      final scannedTextList = await scanImageForText(imagePath);
      final receiptKeyWords = await extractKeywords(scannedTextList);

      return receiptKeyWords;
    } on Exception catch (e) {
      print('Error in extractKeywordsFromImage: $e');
      return [];
    }
  }

  @visibleForTesting
  static Future<List<String>> scanImageForText(String imagePath) async {
    // Uses Google ML Kit Vision
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      String scannedText = recognizedText.text;
      List<String> scannedTextList = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            scannedText = element.text.toLowerCase();
            scannedTextList.add(scannedText);
          }
        }
      }

      return scannedTextList;
    } on Exception catch (e) {
      print('Error in scanImageForText: $e');
      return [];
    }
  }

  @visibleForTesting
  static Future<List<String>> extractKeywords(
      List<String> scannedOCRText) async {
    try {
      String scannedOCRTextList = scannedOCRText.join(' ');
      // Define the regular expression pattern for word characters.
      final pattern = RegExp(r'\w+');
      // Use the pattern to match all the words in the text.
      final matches = pattern.allMatches(scannedOCRTextList);
      // Convert the matches to a list of strings.
      final words = matches.map((match) => match.group(0)!).toList();

      final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final String detectedLanguage =
          await languageIdentifier.identifyLanguage(scannedOCRText.toString());

      // Use the _commonReceiptWords list as stop words.
      final commonReceiptWords = await loadCommonReceiptWords(detectedLanguage);
      // Filter out any stop words and return the remaining words.
      final keywords = words
          .where((word) => !commonReceiptWords.contains(word.toLowerCase()))
          .toSet() // Convert list to set to remove duplicates
          .toList(); // Convert set back to list

      languageIdentifier.close();
      return keywords;
    } on Exception catch (e) {
      print('Error in extractKeywords: $e');
      return [];
    }
  }

  @visibleForTesting
  // getting common skip words on receipt for latin languages only
  static Future<List<String>> loadCommonReceiptWords(
      String detectedLanguage) async {
    try {
      String fileName;

      switch (detectedLanguage) {
        case 'en':
          fileName = 'assets/common_receipt_words_english.txt';
          break;
        case 'es':
          fileName = 'assets/common_receipt_words_spanish.txt';
          break;
        case 'fr':
          fileName = 'assets/common_receipt_words_french.txt';
          break;
        case 'pt':
          fileName = 'assets/common_receipt_words_portuguese.txt';
          break;
        case 'de':
          fileName = 'assets/common_receipt_words_german.txt';
          break;
        case 'it':
          fileName = 'assets/common_receipt_words_italian.txt';
          break;
        case 'nl':
          fileName = 'assets/common_receipt_words_dutch.txt';
          break;
        case 'ro':
          fileName = 'assets/common_receipt_words_romanian.txt';
          break;
        default:
          fileName = 'assets/common_receipt_words_english.txt';
          break;
      }

      String content = await rootBundle.loadString(fileName);
      final commonReceiptWords =
          content.split('\n').map((word) => word.trim()).toList();
      return commonReceiptWords;
    } on Exception catch (e) {
      print('Error in loadCommonReceiptWords: $e');
      return <String>[];
    }
  }

  static Future<bool> imageHasText(String imagePath) async {
    try {
      final scannedTextList =
          await TextRecognitionService.scanImageForText(imagePath);
      // most if not all receipts will have greater than 10 text elements (space separated words)
      return scannedTextList.length > 10;
    } on Exception catch (e) {
      print('Error in ReceiptService.imageHasText: $e');
      return false;
    }
  }

  static Future<String> extractPriceFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final textToAnalyse = recognizedText.text;
    final String currencySign = await getCurrencySymbol(textToAnalyse);
    RegExp discardRegExp = await getDiscardRegExp(textToAnalyse);
    RegExp moneyExp = RegExp(r"(\d{1,3}(?:,\d{3})*\.\d{2})");
    RegExp urlRegExp = RegExp('^(?!mailto:)(?:(?:http|https|ftp)://)(?:\\S+(?::\\S*)?@)?(?:(?:(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[0-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,})))|localhost)(?::\\d{2,5})?(?:(/|\\?|#)[^\\s]*)?\$');
    RegExp discardSentencePattern = RegExp(r'(?:\b[A-Za-z]+\b[\s\r\n]*){4,}', caseSensitive: false);
    RegExp emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', caseSensitive: false);
    RegExp phoneNumberPattern = RegExp(r"(?:\+\d{1,3}[\s-]?)?(?:\(\d{1,3}\)[\s-]?)?\d{1,4}[\s-]?\d{1,4}[\s-]?\d{1,4}(?!\.\d)");
    RegExp datePattern = RegExp(
      r"(\d{2}|\d{4})[-\/\s:](0[1-9]|1[0-2])[-\/\s:](0[1-9]|[12][0-9]|3[01])|" // YYYY-MM-DD or variations
      r"(0[1-9]|1[0-2])[-\/\s:](0[1-9]|[12][0-9]|3[01])[-\/\s:](\d{2}|\d{4})|" // MM-DD-YYYY or variations
      r"(0[1-9]|[12][0-9]|3[01])[-\/\s:](0[1-9]|1[0-2])[-\/\s:](\d{2}|\d{4})|" // DD-MM-YYYY or variations
      r"(0[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])\.\d{2}|" // MM.DD.YY
      r"(0?[1-9]|1[0-2])\.(0?[1-9]|[12][0-9]|3[01])\.\d{2}|" // M.D.YY
      r"(0[1-9]|1[0-2])\.(0?[1-9]|[12][0-9]|3[01])\.\d{2}|" // MM.D.YY
      r"(0?[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])\.\d{2}|" // M.DD.YY
      r"(0[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])\.\d{4}|" // MM.DD.YYYY
      r"(0?[1-9]|1[0-2])\.(0?[1-9]|[12][0-9]|3[01])\.\d{4}|" // M.D.YYYY
      r"(0[1-9]|1[0-2])\.(0?[1-9]|[12][0-9]|3[01])\.\d{4}|" // MM.D.YYYY
      r"(0?[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])\.\d{4}", // M.DD.YYYY
    caseSensitive: false,
    );
    RegExp percentagePattern = RegExp(r"(?:\d*\.?\d{1,2}%|%\d*\.?\d{1,2})"); // Examples: "1.9%", ".99%", "100%", "%1.5", "%50"
    RegExp timePattern = RegExp(r"(2[0-3]|[01]?[0-9]):([0-5]?[0-9]):([0-5]?[0-9])", caseSensitive: false); // Examples: "23:59:59", "3:5:01", "14:09:09", "00:00:00"



    // Get the lines of text from the recognized text
    List<String> lines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        if (discardSentencePattern.hasMatch(line.text) ||
            discardRegExp.hasMatch(line.text) ||
            urlRegExp.hasMatch(line.text) ||
            emailPattern.hasMatch(line.text) ||
            phoneNumberPattern.hasMatch(line.text) ||
            datePattern.hasMatch(line.text) ||
            timePattern.hasMatch(line.text) || 
            percentagePattern.hasMatch(line.text)) {
          continue;
        }

        lines.add(line.text);
      }
    }

    // Variables for financial info extraction
    num scanTotal = 0;
    num finalTotal = 0;


    //1. GET TOTAL (largest number)
    for (int i = 0; i < lines.length; i++) {
      if (moneyExp.hasMatch(lines[i])) {
        String matchedString = moneyExp.stringMatch(lines[i]).toString();
        String sanitizedString = matchedString.replaceAll(',', '');
        double lineCost = double.parse(sanitizedString);
        // print(matchedString);
        // print(sanitizedString);
        // print(lineCost);
        if (lineCost > scanTotal) {
          scanTotal = lineCost;
        }
      }
    }

    // Determine finalTotal
    finalTotal = scanTotal;

    // Convert finalTotal to double and format the final price string
    double finalValue = finalTotal.toDouble();
    String finalPrice = '$currencySign${finalValue.toStringAsFixed(2)}';
    return finalPrice;
  }

  // getting words to discard in receipt when scanning for price
  // only for latin languages
  static Future<RegExp> getDiscardRegExp(String textToAnalyze) async {
    final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
    final String detectedLanguage =
        await languageIdentifier.identifyLanguage(textToAnalyze);

    String discardRegExpPattern =
        r'subtotal|savings|saving|promotions|promotion|service|opt serv|points|point|voucher|tax|discount|vat|tip|service charge|coupon|membership|deposit|fee|delivery|shipping|promo|refund|adjustment|gift card|add-on|extras|upgrade|surcharge|packaging|handling|convenience fee|loyalty|rewards|mileage|win|earn|chance|company|limited|ltd|group|sas|inc|corporation|corp|registered office|domiciled|street|st|avenue|ave|boulevard|blvd|road|rd|lane|ln|company number|rcs|registered capital|imo|commercial trade';

    switch (detectedLanguage) {
      case 'en': // English
        break;
      case 'fr': // French
        discardRegExpPattern =
            r'sous-total|économies|économie|promotions|promotion|service|opt serv|points|point|bon|taxe|rabais|tva|pourboire|frais de service|coupon|adhésion|dépôt|frais|livraison|expédition|promo|remboursement|ajustement|carte cadeau|supplément|extra|mise à niveau|supplément|emballage|manutention|frais de commodité|fidélité|récompenses|kilométrage|gagner|gagne|chance|société|limitée|ltd|groupe|sas|inc|société anonyme|corp|siège social|domicilié|rue|st|avenue|ave|boulevard|blvd|route|rd|voie|ln|numéro de société|rcs|capital social|imo|commerce';
        break;
      case 'de': // German
        discardRegExpPattern =
            r'Teilsumme|Ersparnisse|Ersparnis|Aktionen|Aktion|Bedienung|Opt Dienst|Punkte|Punkt|Gutschein|Steuer|Rabatt|MwSt|Trinkgeld|Servicegebühr|Gutschein|Mitgliedschaft|Anzahlung|Gebühr|Lieferung|Versand|Promo|Rückerstattung|Anpassung|Geschenkkarte|Zusatz|Extras|Upgrade|Aufschlag|Verpackung|Handhabung|Komfortgebühr|Treue|Prämien|Kilometer|gewinnen|verdienen|Chance|Unternehmen|begrenzt|Ltd|Gruppe|SAS|Inc|Gesellschaft mit beschränkter Haftung|corp|eingetragener Firmensitz|domiciled|Straße|st|Avenue|ave|Boulevard|blvd|Weg|rd|Gasse|ln|Firmennummer|rcs|eingetragenes Kapital|imo|Handelsregister';
        break;
      case 'es': // Spanish
        discardRegExpPattern =
            r'subtotal|ahorros|ahorro|promociones|promoción|servicio|serv opc|puntos|punto|vale|impuesto|descuento|iva|propina|cargo de servicio|cupón|membresía|depósito|tarifa|entrega|envío|promo|reembolso|ajuste|tarjeta regalo|complemento|extras|mejora|recargo|embalaje|manipulación|cargo por comodidad|lealtad|recompensas|kilometraje|ganar|ganancia|oportunidad|compañía|limitada|ltd|grupo|sas|inc|corporación|corp|oficina registrada|domiciliado|calle|st|avenida|ave|bulevar|blvd|camino|rd|carril|ln|número de compañía|rcs|capital registrado|imo|comercio';
        break;
      case 'pt': // Portuguese
        discardRegExpPattern =
            r'subtotal|economias|economia|promoções|promoção|serviço|serv opt|pontos|ponto|voucher|imposto|desconto|iva|gorjeta|taxa de serviço|cupom|membro|depósito|taxa|entrega|expedição|promo|reembolso|ajuste|cartão presente|adicional|extras|atualização|sobretaxa|embalagem|manuseio|taxa de conveniência|lealdade|recompensas|milhagem|ganhar|ganho|chance|companhia|limitada|ltd|grupo|sas|inc|corporação|corp|escritório registrado|domiciliado|rua|st|avenida|ave|boulevard|blvd|estrada|rd|lane|ln|número da companhia|rcs|capital registrado|imo|comércio';
        break;
      case 'it': // Italian
        discardRegExpPattern =
            r'subtotale|risparmi|risparmio|promozioni|promozione|servizio|opt serv|punti|punto|voucher|tassa|sconto|iva|mancia|carico di servizio|coupon|membri|deposito|tariffa|consegna|spedizione|promo|rimborso|aggiustamento|carta regalo|addon|extra|upgrade|sovrapprezzo|imballaggio|gestione|tassa di comodità|lealtà|premi|chilometraggio|vincere|guadagnare|opportunità|azienda|limitata|ltd|gruppo|sas|inc|società|corp|ufficio registrato|domiciliato|strada|st|viale|ave|boulevard|blvd|via|rd|lane|ln|numero azienda|rcs|capitale registrato|imo|commercio';
        break;
      default: // Default to English
        break;
    }

    RegExp discardRegExp = RegExp(
      discardRegExpPattern,
      caseSensitive: false,
    );

    languageIdentifier.close();

    return discardRegExp;
  }

  static Future<String> getCurrencySymbol(String textToAnalyse) async {
    Set<String> currencySymbols = {'\$', '€', '¥', '£', '₹'};
    String currencySign = '£'; // Default currency symbol
    int maxCount = 0;

    for (String symbol in currencySymbols) {
      int currentCount = symbol.allMatches(textToAnalyse).length;
      if (currentCount > maxCount) {
        maxCount = currentCount;
        currencySign = symbol;
      }
    }

    return currencySign;
  }

  static Future<double> extractCostFromPriceString(String priceString) async {
    // Define a pattern to remove non-numeric characters (assuming currency symbols and commas)
    final pattern = RegExp(r'[^\d.]');

    // Remove non-numeric characters from the price string
    String numericPriceString = priceString.replaceAll(pattern, '');

    // Try to parse the numeric string to a double
    double price = double.tryParse(numericPriceString) ?? 0.0;

    return price;
  }
}
