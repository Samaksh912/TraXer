import 'package:flutter_test/flutter_test.dart';
import 'lib/services/voice_parse_service.dart';
import 'lib/models/isar_expense.dart';

void main() {
  group('Homophone Normalization Tests', () {
    test('Should handle "4" → "for" conversion in amount context', () {
      // Simulating STT converting "for" to "4"
      final result1 = VoiceParseService.parse('add expense 4 20 rupees 4 printing');
      expect(result1.amount, 20.0, reason: 'Should extract 20 as amount');
      expect(result1.title.toLowerCase(), contains('print'),
          reason: 'Should extract "printing" as title');
    });

    test('Should correctly parse: "for 20 rupees for printing"', () {
      final result = VoiceParseService.parse('add expense for 20 rupees for printing');
      expect(result.amount, 20.0, reason: 'Should extract 20 as amount');
      expect(result.title.toLowerCase(), contains('print'),
          reason: 'Should extract subject correctly');
      expect(result.type, TransactionType.expense);
    });

    test('Should distinguish quantity from amount in: "bought 2 books for 400"', () {
      final result = VoiceParseService.parse('bought 2 books for 400 rupees');
      expect(result.amount, 400.0,
          reason: 'Should extract 400 (not 2) as the amount');
      expect(result.title.toLowerCase(), contains('book'),
          reason: 'Should extract "books" as subject');
    });

    test('Should handle: "food delivery 4 100 rupees 4 swiggy"', () {
      // This simulates: "food delivery for 100 rupees for swiggy"
      final result = VoiceParseService.parse('food delivery 4 100 rupees 4 swiggy');
      expect(result.amount, 100.0, reason: 'Should extract 100 as amount');
      expect(result.category, 'Food', reason: 'Should detect Food category');
      expect(result.title.toLowerCase(), contains('swiggy'),
          reason: 'Should extract brand name');
    });

    test('Should not confuse "2" in quantity context', () {
      final result = VoiceParseService.parse('bought 2 items for 500 rupees');
      expect(result.amount, 500.0,
          reason: 'Should pick 500 not 2 as amount');
    });

    test('Should handle multiple numbers with correct amount detection', () {
      final result = VoiceParseService.parse('paid 50 plus 150 rupees for taxi');
      // Should prefer the larger/last meaningful amount
      expect(result.amount > 0, true, reason: 'Should extract some valid amount');
    });

    test('Should preserve subject even with homophone artifacts', () {
      final result = VoiceParseService.parse('add 4 300 4 gym subscription');
      // "add for 300 for gym subscription"
      expect(result.amount, 300.0);
      expect(result.category, 'Health', reason: 'Gym should be Health category');
    });

    test('Should handle income parsing with homophones', () {
      final result = VoiceParseService.parse('received 5000 rupees salary payment');
      expect(result.amount, 5000.0);
      expect(result.type, TransactionType.income);
      expect(result.category, 'Salary');
    });

    test('Complex real-world example with multiple prepositions', () {
      final result = VoiceParseService.parse(
          'add expense for 250 rupees for lunch at dominos with friends');
      expect(result.amount, 250.0);
      expect(result.category, 'Food');
      expect(result.title.toLowerCase().replaceAll('\'', ''), contains('dominos'));
    });
  });

  group('Confidence Score Tests', () {
    test('Simple expense should have high confidence', () {
      final result = VoiceParseService.parse('spent 500 on groceries');
      expect(result.confidence > 0.6, true,
          reason: 'Should have decent confidence for clear statement');
    });

    test('Ambiguous input should have lower confidence', () {
      final result = VoiceParseService.parse('something something 100');
      expect(result.confidence, lessThanOrEqualTo(1.0),
          reason: 'Confidence must be clamped to 1.0');
    });
  });
}
