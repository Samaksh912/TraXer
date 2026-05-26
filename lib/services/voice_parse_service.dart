import '../models/isar_expense.dart';
import '../models/voice_parse_result.dart';

/// Pure-Dart, on-device NLP parser — zero latency, no network calls.
///
/// Full pre-processing pipeline (applied in order):
///   0a. Accent normalization      (rupay→rupees, expence→expense, phor→for, …)
///   0b. Hinglish / code-mix       (kharcha→expense, ke liye→for, …)
///   0c. Spoken number → digit     (forty four→44, two hundred→200, ek hazaar→1000)
///   0d. Adjacent digit merging    (4 4 rupees→44 rupees)
///   0e. Context-aware homophones  (4→for only when NOT in numeric context)
///
/// Core parse pipeline (after pre-processing):
///   1. Detect explicit type        (spent/earned/salary, …)
///   2. Extract amount              (currency-qualified → "of N" → bare number)
///   3. Strip command/meta words
///   4. Detect transaction type     (explicit → keyword scan)
///   5. Extract subject/topic       (for-phrase → verb-object → at/on → tokens)
///   6. Brand/service lookup        (longest-match + fuzzy fallback)
///   7. Social-context check        (friends, mom, party, …)
///   8. Generic keyword category
///   9. Derive title + category
class VoiceParseService {
  VoiceParseService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-PROCESSING STEP 0a — Accent / STT-error normalization
  // ═══════════════════════════════════════════════════════════════════════════

  /// Common STT misrecognitions caused by accents (Indian-English heavy),
  /// regional pronunciation, or model hallucinations.
  ///
  /// Keys are lowercase substrings to replace (word-boundary delimited where
  /// possible). Listed rough order: currency → verbs → connectives → misc.
  static const Map<String, String> _accentMap = {
    // ── Currency pronunciations ───────────────────────────────────────────
    'rupay':    'rupees',
    'rupaya':   'rupees',
    'rupiya':   'rupees',
    'rupaiye':  'rupees',
    'rupiye':   'rupees',
    'roopee':   'rupees',
    'roopees':  'rupees',
    'rupe':     'rupees',  // clipped pronunciation

    // ── "for" mishearings ─────────────────────────────────────────────────
    'phor':     'for',
    'phore':    'for',
    'ffor':     'for',
    'forr':     'for',

    // ── Verb/action mishearings ───────────────────────────────────────────
    'payed':    'paid',
    'paied':    'paid',
    'buyed':    'bought',
    'spendt':   'spent',
    'spended':  'spent',
    'recieved': 'received',
    'recevied': 'received',

    // ── Common noun mishearings ───────────────────────────────────────────
    'expence':  'expense',
    'expanse':  'expense',
    'exspense': 'expense',
    'expences': 'expenses',
    'petral':   'petrol',
    'petriol':  'petrol',
    'gyum':     'gym',
    'jym':      'gym',
    'medcine':  'medicine',
    'medicin':  'medicine',
    'grociery': 'grocery',
    'grocary':  'grocery',
    'restaurent': 'restaurant',
    'resturant':  'restaurant',
    'electricty': 'electricity',
    'electrcity': 'electricity',
    'maintanence': 'maintenance',
    'mantainance': 'maintenance',
    'subsription': 'subscription',
    'subscripion': 'subscription',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-PROCESSING STEP 0b — Hinglish / code-mix normalization
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hinglish words and phrases → English equivalents.
  /// Handles the extremely common Indian pattern of mixing Hindi grammar
  /// with English vocabulary, e.g. "uber ka paisa diya" → "uber expense paid".
  static const Map<String, String> _hinglishMap = {
    // Meta / intent words
    'kharcha':     'expense',
    'kharch':      'expense',
    'kharchaa':    'expense',
    'amdani':      'income',
    'kamayi':      'income',

    // Connectives & prepositions
    'ke liye':     'for',
    'k liye':      'for',
    'keliye':      'for',
    'ke waste':    'for',
    'se':          'from',
    'ko':          'to',
    'mein':        'in',
    'pe':          'on',
    'par':         'on',
    'aur':         'and',
    'ya':          'or',
    'ka':          'of',
    'ki':          'of',
    'ke':          'of',
    'ne':          '',      // subject marker, strip it
    'mera':        'my',
    'meri':        'my',
    'mere':        'my',

    // Verbs
    'diya':        'paid',
    'diye':        'paid',
    'liya':        'received',
    'liye':        'received',
    'kiya':        'done',
    'mila':        'received',
    'mili':        'received',
    'hua':         '',       // auxiliary, strip
    'huyi':        '',
    'gaya':        '',

    // Social words
    'yaar':        'friend',
    'dost':        'friend',
    'bhai':        'brother',
    'behen':       'sister',
    'beti':        'daughter',
    'beta':        'son',
    'maa':         'mom',
    'papa':        'dad',
    'baba':        'dad',
    'nana':        'grandpa',
    'nani':        'grandma',
    'dada':        'grandpa',
    'dadi':        'grandma',

    // Common expense nouns (Hindi → English categories)
    'khana':       'food',
    'khaana':      'food',
    'dawaai':      'medicine',
    'dawai':       'medicine',
    'petrol bhar': 'petrol',
    'bill bhara':  'bill paid',
    'kiraya':      'rent',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-PROCESSING STEP 0c — Spoken number → digit conversion
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maps individual number words to their integer values.
  static const Map<String, int> _numWordOnes = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
    'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
    'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
    'eighteen': 18, 'nineteen': 19,
  };

  static const Map<String, int> _numWordTens = {
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
  };

  /// Hindi number words → digit values (for Hinglish amounts).
  static const Map<String, int> _hindiNumWords = {
    'ek': 1, 'do': 2, 'teen': 3, 'char': 4, 'paanch': 5,
    'chhe': 6, 'saat': 7, 'aath': 8, 'nau': 9, 'das': 10,
    'gyarah': 11, 'barah': 12, 'terah': 13, 'chaudah': 14,
    'pandrah': 15, 'solah': 16, 'satrah': 17, 'atharah': 18,
    'unnees': 19, 'bees': 20, 'tees': 30, 'chalis': 40,
    'pachaas': 50, 'saath': 70, 'assi': 80, 'nabbe': 90,
    'ek sau': 100, 'do sau': 200, 'teen sau': 300,
  };

  static const Map<String, int> _magnitudeWords = {
    'hundred':  100,
    'thousand': 1000,
    'lakh':     100000,
    'lac':      100000,
    'lacs':     100000,
    'lakhs':    100000,
    'crore':    10000000,
    'crores':   10000000,
    'hazaar':   1000,   // Hindi
    'hajar':    1000,
    'hazar':    1000,
  };

  /// Regex matching sequences of spoken number words (e.g. "forty four", "two hundred fifty").
  static final _numWordSequenceRegex = RegExp(
    r'\b(?:' +
        [
          ..._numWordOnes.keys,
          ..._numWordTens.keys,
          ..._magnitudeWords.keys,
          ..._hindiNumWords.keys.where((k) => !k.contains(' ')), // single-token Hindi nums
          'and', 'a',
        ]
            .map(RegExp.escape)
            .join('|') +
        r')(?:\s+(?:and\s+)?(?:' +
        [
          ..._numWordOnes.keys,
          ..._numWordTens.keys,
          ..._magnitudeWords.keys,
          ..._hindiNumWords.keys.where((k) => !k.contains(' ')),
        ]
            .map(RegExp.escape)
            .join('|') +
        r'))*\b',
    caseSensitive: false,
  );

  /// Converts a sequence of number words into the corresponding numeric value.
  /// E.g. "two hundred fifty" → 250, "forty four" → 44, "one lakh" → 100000.
  static int? _parseNumberWords(String phrase) {
    final tokens = phrase
        .toLowerCase()
        .replaceAll(RegExp(r'\band\b'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && t != 'a')
        .toList();

    if (tokens.isEmpty) return null;

    int result = 0;
    int current = 0;

    for (final token in tokens) {
      if (_numWordOnes.containsKey(token)) {
        current += _numWordOnes[token]!;
      } else if (_numWordTens.containsKey(token)) {
        current += _numWordTens[token]!;
      } else if (_hindiNumWords.containsKey(token)) {
        current += _hindiNumWords[token]!;
      } else if (token == 'hundred') {
        // "two hundred" → current(2) * 100 = 200
        current = current == 0 ? 100 : current * 100;
      } else if (_magnitudeWords.containsKey(token)) {
        final mag = _magnitudeWords[token]!;
        current = current == 0 ? mag : current * mag;
        result += current;
        current = 0;
      }
    }
    result += current;
    return result > 0 ? result : null;
  }

  /// Replace spoken-number sequences in [text] with digit strings.
  ///
  /// Examples:
  ///   "forty four rupees"     → "44 rupees"
  ///   "two hundred fifty"     → "250"
  ///   "one thousand five hundred" → "1500"
  ///   "five lakh rupees"      → "500000 rupees"
  static String _convertSpokenNumbers(String text) {
    return text.replaceAllMapped(_numWordSequenceRegex, (match) {
      final phrase = match.group(0)!;
      final value = _parseNumberWords(phrase);
      if (value == null) return phrase; // unparseable → leave as-is
      return value.toString();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-PROCESSING STEP 0d — Adjacent single-digit merging
  // ═══════════════════════════════════════════════════════════════════════════

  /// Merge adjacent isolated digits when they appear to form a compound number.
  ///
  /// Handles the STT artifact where "44" is spoken distinctly and recognized
  /// as "4 4" rather than "44".  We merge them when immediately followed by
  /// a currency word or another digit group (i.e. numeric context).
  ///
  /// "4 4 rupees"  → "44 rupees"    ✓
  /// "4 books"     → "4 books"      ✓  (not merged — non-numeric context)
  /// "4 4 4"       → "444"          ✓  (all digits, could be amount)
  static String _mergeAdjacentDigits(String text) {
    // Repeatedly merge pairs of isolated digits in numeric context until stable.
    String prev;
    var result = text;
    do {
      prev = result;
      // Merge two adjacent single/multi-digit groups separated by a space
      // when what follows is currency, another digit, or end-of-meaningful-text.
      result = result.replaceAllMapped(
        RegExp(
          r'\b(\d+)\s+(\d+)(?=\s*(?:rupees?|rs\.?|inr|₹|\d|$))',
          caseSensitive: false,
        ),
            (m) => '${m.group(1)}${m.group(2)}',
      );
    } while (result != prev);
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-PROCESSING STEP 0e — Context-aware homophone normalization
  // ═══════════════════════════════════════════════════════════════════════════

  /// Words/phrases that, if they follow the digit "4" or "2", indicate the
  /// digit is an AMOUNT (i.e. do NOT replace with "for"/"to").
  static const _numericContextWords = [
    'rupees?', 'rs\\.?', 'inr', '₹',
    'bottles?', 'books?', 'items?', 'pieces?', 'pcs?', 'units?',
    'kg', 'grams?', 'litres?', 'liters?', 'ml',
  ];


  static String _normalizeHomophones(String text) {
    var result = text;

    // ── "4" → "for" in preposition context ─────────────────────────────────
    // Only replace if NOT followed by a numeric-context word.
    // We also guard against "44", "400", etc. using word boundaries.
    result = result.replaceAllMapped(
      RegExp(
        r'(?<![0-9])\b4\b(?!\s*(?:' +
            _numericContextWords.join('|') +
            r'))',
        caseSensitive: false,
      ),
          (m) {
        // Extra guard: if the character before is a digit, keep as number.
        return 'for ';
      },
    );

    // ── "2" → "to" in preposition context ──────────────────────────────────
    result = result.replaceAllMapped(
      RegExp(
        r'(?<![0-9])\b2\b(?!\s*(?:' +
            _numericContextWords.join('|') +
            r'))',
        caseSensitive: false,
      ),
          (_) => 'to ',
    );

    // ── "b4" → "before" ─────────────────────────────────────────────────────
    result = result.replaceAll(RegExp(r'\bb4\b', caseSensitive: false), 'before');

    // ── "gr8" → "great" ─────────────────────────────────────────────────────
    result = result.replaceAll(RegExp(r'\bgr8\b', caseSensitive: false), 'great');

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-PROCESSING — Master pipeline
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply all pre-processing steps in order and return both the
  /// display-case–preserved version and a normalized lowercase version.
  static ({String normalized, String lower}) _preProcess(String raw) {
    var text = raw.trim();

    // 0a — accent normalization (word-boundary safe)
    for (final entry in _accentMap.entries) {
      text = text.replaceAll(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false),
        entry.value,
      );
    }

    // 0b — Hinglish / code-mix (longest-first to avoid partial matches)
    final hinglishSorted = _hinglishMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in hinglishSorted) {
      text = text.replaceAll(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false),
        entry.value,
      );
    }

    // 0c — spoken number → digit
    text = _convertSpokenNumbers(text);

    // 0d — adjacent digit merging (must run AFTER number-word conversion)
    text = _mergeAdjacentDigits(text);

    // 0e — context-aware homophones (must run AFTER merging so "44" is intact)
    text = _normalizeHomophones(text);

    // Collapse whitespace artifacts
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return (normalized: text, lower: text.toLowerCase());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1 — Explicit type detection
  // ═══════════════════════════════════════════════════════════════════════════

  static final _commandWordRegex = RegExp(
    r'\b(?:add|log|record|track|note|create|new|mark|enter|save|register)\b',
    caseSensitive: false,
  );
  static final _metaWordRegex = RegExp(
    r'\b(?:expense|income|transaction|entry|spending|payment|transfer)\b',
    caseSensitive: false,
  );

  static const Map<String, TransactionType> _explicitTypeWords = {
    'expense':   TransactionType.expense,
    'spending':  TransactionType.expense,
    'spent':     TransactionType.expense,
    'debit':     TransactionType.expense,
    'paid':      TransactionType.expense,
    'bought':    TransactionType.expense,
    'purchased': TransactionType.expense,
    'income':    TransactionType.income,
    'earning':   TransactionType.income,
    'earned':    TransactionType.income,
    'received':  TransactionType.income,
    'credited':  TransactionType.income,
    'salary':    TransactionType.income,
    'got':       TransactionType.income,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2 — Amount extraction regexes
  // ═══════════════════════════════════════════════════════════════════════════

  static final _currencyAmountRegex = RegExp(
    r'(?:₹\s?(\d+(?:\.\d+)?))'
    r'|(?:(\d+(?:\.\d+)?)\s*(?:rupees?|rs\.?|inr)\b)'
    r'|(?:(?:rupees?|rs\.?|inr)\s*(\d+(?:\.\d+)?))'
    r'|(?:(?:worth|costing?|costs?|price)\s+(?:rupees?|rs\.?|₹\s?)?\s*(\d+(?:\.\d+)?))',
    caseSensitive: false,
  );

  static final _ofAmountRegex = RegExp(
    r'\bof\s+(?:rupees?|rs\.?|₹\s?)?(\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  );

  static final _bareNumberRegex = RegExp(r'\b(\d+(?:\.\d+)?)\b');

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 6 — Brand / service map
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, _Brand> _brandMap = {
    // ── Ride-sharing & transport ──────────────────────────────────────────
    'uber':          _Brand('Travel', 'Uber'),
    'ola':           _Brand('Travel', 'Ola'),
    'rapido':        _Brand('Travel', 'Rapido'),
    'lyft':          _Brand('Travel', 'Lyft'),
    'irctc':         _Brand('Travel', 'IRCTC'),
    'makemytrip':    _Brand('Travel', 'MakeMyTrip'),
    'redbus':        _Brand('Travel', 'RedBus'),
    'indigo':        _Brand('Travel', 'IndiGo'),
    'spicejet':      _Brand('Travel', 'SpiceJet'),
    'air india':     _Brand('Travel', 'Air India'),
    'vistara':       _Brand('Travel', 'Vistara'),
    // ── Food ─────────────────────────────────────────────────────────────
    'swiggy':        _Brand('Food', 'Swiggy'),
    'zomato':        _Brand('Food', 'Zomato'),
    'dominos':       _Brand('Food', "Domino's"),
    "domino's":      _Brand('Food', "Domino's"),
    'mcdonalds':     _Brand('Food', "McDonald's"),
    "mcdonald's":    _Brand('Food', "McDonald's"),
    'mcdonald':      _Brand('Food', "McDonald's"),
    'kfc':           _Brand('Food', 'KFC'),
    'subway':        _Brand('Food', 'Subway'),
    'starbucks':     _Brand('Food', 'Starbucks'),
    'chaayos':       _Brand('Food', 'Chaayos'),
    'dunkin':        _Brand('Food', "Dunkin'"),
    'blinkit':       _Brand('Food', 'Blinkit'),
    'zepto':         _Brand('Food', 'Zepto'),
    'bigbasket':     _Brand('Food', 'BigBasket'),
    'big basket':    _Brand('Food', 'BigBasket'),
    'instamart':     _Brand('Food', 'Instamart'),
    'burger king':   _Brand('Food', 'Burger King'),
    'pizza hut':     _Brand('Food', 'Pizza Hut'),
    'haldiram':      _Brand('Food', 'Haldirams'),
    // ── Shopping ─────────────────────────────────────────────────────────
    'amazon':        _Brand('Shopping', 'Amazon'),
    'flipkart':      _Brand('Shopping', 'Flipkart'),
    'myntra':        _Brand('Shopping', 'Myntra'),
    'meesho':        _Brand('Shopping', 'Meesho'),
    'nykaa':         _Brand('Shopping', 'Nykaa'),
    'ajio':          _Brand('Shopping', 'Ajio'),
    'ikea':          _Brand('Shopping', 'IKEA'),
    'reliance':      _Brand('Shopping', 'Reliance'),
    'dmart':         _Brand('Shopping', 'D-Mart'),
    'd-mart':        _Brand('Shopping', 'D-Mart'),
    'snapdeal':      _Brand('Shopping', 'Snapdeal'),
    'croma':         _Brand('Shopping', 'Croma'),
    // ── Entertainment ────────────────────────────────────────────────────
    'netflix':       _Brand('Entertainment', 'Netflix'),
    'spotify':       _Brand('Entertainment', 'Spotify'),
    'hotstar':       _Brand('Entertainment', 'Hotstar'),
    'disney+':       _Brand('Entertainment', 'Disney+'),
    'disney plus':   _Brand('Entertainment', 'Disney+'),
    'prime video':   _Brand('Entertainment', 'Prime Video'),
    'amazon prime':  _Brand('Entertainment', 'Prime Video'),
    'youtube':       _Brand('Entertainment', 'YouTube Premium'),
    'bookmyshow':    _Brand('Entertainment', 'BookMyShow'),
    'pvr':           _Brand('Entertainment', 'PVR'),
    'inox':          _Brand('Entertainment', 'INOX'),
    'jiocinema':     _Brand('Entertainment', 'JioCinema'),
    'sony liv':      _Brand('Entertainment', 'SonyLIV'),
    'sonyliv':       _Brand('Entertainment', 'SonyLIV'),
    'zee5':          _Brand('Entertainment', 'ZEE5'),
    'mxplayer':      _Brand('Entertainment', 'MX Player'),
    'mx player':     _Brand('Entertainment', 'MX Player'),
    'apple music':   _Brand('Entertainment', 'Apple Music'),
    // ── Utilities & telecom ───────────────────────────────────────────────
    'airtel':        _Brand('Utilities', 'Airtel'),
    'jio':           _Brand('Utilities', 'Jio'),
    ' vi ':          _Brand('Utilities', 'Vi'),
    'bsnl':          _Brand('Utilities', 'BSNL'),
    'tata sky':      _Brand('Utilities', 'Tata Sky'),
    'tataplay':      _Brand('Utilities', 'Tata Play'),
    'act broadband': _Brand('Utilities', 'ACT Broadband'),
    'hathway':       _Brand('Utilities', 'Hathway'),
    // ── Health & fitness ──────────────────────────────────────────────────
    'cultfit':       _Brand('Health', 'Cult.fit'),
    'cult.fit':      _Brand('Health', 'Cult.fit'),
    'cult fit':      _Brand('Health', 'Cult.fit'),
    'healthifyme':   _Brand('Health', 'HealthifyMe'),
    '1mg':           _Brand('Health', '1mg'),
    'apollo':        _Brand('Health', 'Apollo Pharmacy'),
    'practo':        _Brand('Health', 'Practo'),
    'netmeds':       _Brand('Health', 'Netmeds'),
    'medplus':       _Brand('Health', 'MedPlus'),
    'pharm':         _Brand('Health', 'Pharmacy'),
    // ── Finance / wallet ──────────────────────────────────────────────────
    'phonepe':       _Brand('Others', 'PhonePe'),
    'phone pe':      _Brand('Others', 'PhonePe'),
    'paytm':         _Brand('Others', 'Paytm'),
    'gpay':          _Brand('Others', 'Google Pay'),
    'google pay':    _Brand('Others', 'Google Pay'),
    'cred':          _Brand('Others', 'CRED'),
    'slice':         _Brand('Others', 'Slice'),
    // ── Education ────────────────────────────────────────────────────────
    'udemy':         _Brand('Education', 'Udemy'),
    'coursera':      _Brand('Education', 'Coursera'),
    'unacademy':     _Brand('Education', 'Unacademy'),
    'byju':          _Brand('Education', "BYJU's"),
    'vedantu':       _Brand('Education', 'Vedantu'),
    'khan academy':  _Brand('Education', 'Khan Academy'),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 7 — Social / people nouns
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, String> _socialWordTitles = {
    'friend':       'Friends',
    'friends':      'Friends',
    'buddy':        'Friend',
    'buddies':      'Friends',
    'pal':          'Friend',
    'pals':         'Friends',
    'family':       'Family',
    'mom':          'Mom',
    'dad':          'Dad',
    'mother':       'Mom',
    'father':       'Dad',
    'brother':      'Brother',
    'sister':       'Sister',
    'sibling':      'Sibling',
    'cousin':       'Cousin',
    'uncle':        'Uncle',
    'aunt':         'Aunt',
    'grandma':      'Grandma',
    'grandpa':      'Grandpa',
    'daughter':     'Daughter',
    'son':          'Son',
    'girlfriend':   'Girlfriend',
    'boyfriend':    'Boyfriend',
    'partner':      'Partner',
    'spouse':       'Spouse',
    'wife':         'Wife',
    'husband':      'Husband',
    'colleague':    'Colleague',
    'colleagues':   'Colleagues',
    'coworker':     'Coworker',
    'coworkers':    'Coworkers',
    'boss':         'Boss',
    'party':        'Party',
    'hangout':      'Hangout',
    'outing':       'Outing',
    'date':         'Date',
    'treat':        'Treat',
    'celebration':  'Celebration',
    'wedding':      'Wedding',
    'birthday':     'Birthday',
    'anniversary':  'Anniversary',
    'get-together': 'Get-together',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 8 — Generic keyword → category
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, String> _expenseCategoryMap = {
    // Food
    'food': 'Food', 'lunch': 'Food', 'dinner': 'Food', 'breakfast': 'Food',
    'brunch': 'Food', 'snack': 'Food', 'coffee': 'Food', 'tea': 'Food',
    'chai': 'Food', 'restaurant': 'Food', 'meal': 'Food', 'sweets': 'Food',
    'pizza': 'Food', 'burger': 'Food', 'juice': 'Food', 'biscuit': 'Food',
    'groceries': 'Food', 'grocery': 'Food', 'vegetable': 'Food', 'fruit': 'Food',
    'noodles': 'Food', 'biryani': 'Food', 'rice': 'Food', 'bread': 'Food',
    'milk': 'Food', 'egg': 'Food', 'samosa': 'Food', 'chips': 'Food',
    'chocolate': 'Food', 'ice cream': 'Food', 'icecream': 'Food',
    'cake': 'Food', 'maggi': 'Food', 'paratha': 'Food', 'dosa': 'Food',
    'idli': 'Food', 'roti': 'Food', 'dal': 'Food', 'curry': 'Food',
    'drink': 'Food', 'beer': 'Food', 'wine': 'Food',
    // Travel
    'travel': 'Travel', 'petrol': 'Travel', 'diesel': 'Travel', 'cab': 'Travel',
    'auto': 'Travel', 'bus': 'Travel', 'train': 'Travel', 'flight': 'Travel',
    'fuel': 'Travel', 'ticket': 'Travel', 'toll': 'Travel', 'parking': 'Travel',
    'taxi': 'Travel', 'bike': 'Travel', 'scooter': 'Travel', 'metro': 'Travel',
    'rickshaw': 'Travel', 'ferry': 'Travel', 'ship': 'Travel',
    // Shopping
    'shopping': 'Shopping', 'clothes': 'Shopping', 'shirt': 'Shopping',
    'shoes': 'Shopping', 'book': 'Shopping', 'books': 'Shopping',
    'dress': 'Shopping', 'bag': 'Shopping', 'pen': 'Shopping',
    'stationery': 'Shopping', 'gadget': 'Shopping', 'phone': 'Shopping',
    'laptop': 'Shopping', 'earphone': 'Shopping', 'headphone': 'Shopping',
    'watch': 'Shopping', 'sunglasses': 'Shopping', 'jeans': 'Shopping',
    'kurta': 'Shopping', 'saree': 'Shopping', 'toy': 'Shopping',
    'printing': 'Shopping', 'print': 'Shopping', 'photocopy': 'Shopping',
    'xerox': 'Shopping', 'stationary': 'Shopping',
    // Housing
    'rent': 'Housing', 'house': 'Housing', 'apartment': 'Housing',
    'flat': 'Housing', 'hostel': 'Housing', 'pg': 'Housing',
    'maintenance': 'Housing', 'society': 'Housing',
    // Utilities
    'electricity': 'Utilities', 'gas': 'Utilities', 'internet': 'Utilities',
    'wifi': 'Utilities', 'mobile': 'Utilities', 'recharge': 'Utilities',
    'sim': 'Utilities', 'broadband': 'Utilities', 'bill': 'Utilities',
    'water bill': 'Utilities', 'ott': 'Utilities', 'dth': 'Utilities',
    // Health
    'medicine': 'Health', 'medicines': 'Health', 'doctor': 'Health',
    'hospital': 'Health', 'pharmacy': 'Health', 'gym': 'Health',
    'health': 'Health', 'clinic': 'Health', 'tablet': 'Health',
    'injection': 'Health', 'medical': 'Health', 'checkup': 'Health',
    'dental': 'Health', 'eye': 'Health', 'optical': 'Health',
    // Entertainment
    'movie': 'Entertainment', 'cinema': 'Entertainment', 'game': 'Entertainment',
    'subscription': 'Entertainment', 'concert': 'Entertainment',
    'event': 'Entertainment', 'show': 'Entertainment', 'theatre': 'Entertainment',
    'gaming': 'Entertainment', 'amusement': 'Entertainment',
    // Education
    'course': 'Education', 'class': 'Education', 'tuition': 'Education',
    'school': 'Education', 'college': 'Education', 'coaching': 'Education',
    'exam': 'Education', 'textbook': 'Education', 'workshop': 'Education',
    'fees': 'Education', 'fee': 'Education',
  };

  static const Map<String, String> _incomeCategoryMap = {
    'salary': 'Salary', 'freelance': 'Freelance', 'business': 'Business',
    'investment': 'Investments', 'gift': 'Gift', 'bonus': 'Bonus',
    'rent': 'Rental', 'refund': 'Refund', 'cashback': 'Refund',
    'reward': 'Refund', 'profit': 'Business', 'dividend': 'Investments',
    'stipend': 'Salary', 'allowance': 'Gift', 'pension': 'Salary',
    'commission': 'Business', 'interest': 'Investments',
    'consulting': 'Freelance', 'contract': 'Freelance',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // Stop words
  // ═══════════════════════════════════════════════════════════════════════════

  static const _stopWords = {
    'i', 'me', 'my', 'a', 'an', 'the', 'for', 'from', 'to', 'of', 'in',
    'on', 'at', 'by', 'with', 'this', 'that', 'it', 'its', 'some', 'just',
    'got', 'get', 'had', 'have', 'has', 'was', 'were', 'am', 'is', 'are',
    'bought', 'buy', 'spend', 'spent', 'paid', 'pay', 'received', 'receive',
    'earned', 'earn', 'gave', 'give', 'taken', 'take', 'lent', 'used',
    'rupees', 'rupee', 'rs', 'inr', 'worth', 'costing', 'cost', 'price',
    'and', 'or', 'but', 'so', 'if', 'then', 'than', 'also', 'add', 'log',
    'today', 'yesterday', 'now', 'again', 'record', 'track', 'note',
    'much', 'many', 'more', 'less', 'very', 'quite', 'about',
    'could', 'would', 'should', 'will', 'shall', 'may', 'might',
    'expense', 'income', 'entry', 'transaction', 'amount', 'save', 'register',
    'money', 'done',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN ENTRY POINT
  // ═══════════════════════════════════════════════════════════════════════════

  static VoiceParseResult parse(String transcript) {
    // ── Pre-processing ───────────────────────────────────────────────────────
    final (:normalized, :lower) = _preProcess(transcript);

    int score = 0;

    // ── Step 1: Explicit type (before stripping so "add expense" is visible) ──
    final TransactionType? explicitType = _detectExplicitType(lower);
    if (explicitType != null) score += 20;

    // ── Step 2: Amount extraction ─────────────────────────────────────────────
    double amount = 0;
    RegExpMatch? usedAmountMatch;

    final currencyMatch = _currencyAmountRegex.firstMatch(lower);
    if (currencyMatch != null) {
      final raw = currencyMatch.group(1) ??
          currencyMatch.group(2) ??
          currencyMatch.group(3) ??
          currencyMatch.group(4);
      amount = double.tryParse(raw ?? '') ?? 0;
      if (amount > 0) {
        usedAmountMatch = currencyMatch;
        score += 35;
      }
    }

    if (amount == 0) {
      final ofMatch = _ofAmountRegex.firstMatch(lower);
      if (ofMatch != null) {
        amount = double.tryParse(ofMatch.group(1) ?? '') ?? 0;
        if (amount > 0) {
          usedAmountMatch = ofMatch;
          score += 30;
        }
      }
    }

    if (amount == 0) {
      final allNums = _bareNumberRegex.allMatches(lower).toList();
      if (allNums.isNotEmpty) {
        double? candidate;
        for (final m in allNums.reversed) {
          final n = double.tryParse(m.group(1)!) ?? 0;
          if (n >= 5) { candidate = n; break; }
        }
        candidate ??= double.tryParse(allNums.last.group(1)!) ?? 0;
        if (candidate > 0) {
          amount = candidate;
          score += 15;
        }
      }
    }

    // ── Step 3: Clean text ────────────────────────────────────────────────────
    final cleanText    = _stripMeta(lower);
    final cleanNormal  = _stripMeta(normalized);

    // ── Step 4: Transaction type ──────────────────────────────────────────────
    final TransactionType type =
        explicitType ?? _detectTypeFromKeywords(cleanText);

    // ── Step 5: Subject extraction ────────────────────────────────────────────
    final String subject = _extractSubject(
      cleanText, cleanNormal, usedAmountMatch, amount, type,
    );

    // ── Step 6: Brand lookup (exact then fuzzy) ───────────────────────────────
    _Brand? brand = _lookupBrand(subject, cleanText);
    if (brand == null) {
      // Fuzzy fallback: useful when STT garbles a brand name slightly
      brand = _fuzzyBrandLookup(subject, cleanText);
      if (brand != null) score += 15; // lower confidence for fuzzy hit
    } else {
      score += 30;
    }

    // ── Step 7: Social lookup ─────────────────────────────────────────────────
    String? socialTitle;
    if (brand == null) {
      for (final entry in _socialWordTitles.entries) {
        if (cleanText.contains(entry.key) || subject.contains(entry.key)) {
          socialTitle = entry.value;
          score += 25;
          break;
        }
      }
    }

    // ── Step 8: Category ──────────────────────────────────────────────────────
    String category;
    if (brand != null) {
      category = brand.category;
    } else if (socialTitle != null) {
      category = 'Social';
    } else {
      category = _detectCategoryFromKeywords(cleanText, subject, type);
      if (category != 'Others') score += 25;
    }

    // ── Step 9: Title ─────────────────────────────────────────────────────────
    String title;
    if (brand != null) {
      title = brand.title;
    } else if (subject.isNotEmpty) {
      final subjectLower = subject.toLowerCase();
      title = _socialWordTitles.containsKey(subjectLower)
          ? _socialWordTitles[subjectLower]!
          : _capitalize(subject);
    } else if (socialTitle != null) {
      title = socialTitle;
    } else {
      title = _fallbackTitle(normalized);
    }
    if (title.isNotEmpty) score += 20;

    final confidence = (score / 100.0).clamp(0.0, 1.0);

    return VoiceParseResult(
      title: title,
      amount: amount,
      type: type,
      category: category,
      confidence: confidence,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static TransactionType? _detectExplicitType(String text) {
    for (final entry in _explicitTypeWords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String _stripMeta(String text) => text
      .replaceAll(_commandWordRegex, '')
      .replaceAll(_metaWordRegex, '')
      .replaceAll(RegExp(r'\bof\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  static TransactionType _detectTypeFromKeywords(String text) {
    const incomeKw = [
      'salary', 'income', 'credited', 'refund', 'cashback', 'bonus', 'reward',
      'freelance', 'profit', 'dividend', 'allowance', 'stipend', 'pension',
      'lent me', 'gave me', 'transferred me', 'paid me', 'sent me',
    ];
    for (final kw in incomeKw) {
      if (text.contains(kw)) return TransactionType.income;
    }
    return TransactionType.expense;
  }

  static String _detectCategoryFromKeywords(
      String text, String subject, TransactionType type) {
    final map = type == TransactionType.income
        ? _incomeCategoryMap
        : _expenseCategoryMap;
    for (final src in [text, subject.toLowerCase()]) {
      for (final entry in map.entries) {
        if (src.contains(entry.key)) return entry.value;
      }
    }
    return 'Others';
  }

  /// Exact brand lookup — longest matching key wins.
  static _Brand? _lookupBrand(String subject, String text) {
    _Brand? best;
    int bestLen = 0;
    for (final entry in _brandMap.entries) {
      final key = entry.key;
      if ((subject.toLowerCase().contains(key) || text.contains(key)) &&
          key.length > bestLen) {
        best = entry.value;
        bestLen = key.length;
      }
    }
    return best;
  }

  /// Fuzzy brand lookup using Levenshtein distance.
  ///
  /// Useful when STT garbles a brand name slightly (e.g. "zomatta" → Zomato).
  /// Only applied when exact lookup fails, and only for tokens ≥ 4 chars
  /// (short tokens create too many false positives).
  ///
  /// Threshold: distance ≤ 2 for brands with 6+ chars, ≤ 1 for shorter brands.
  static _Brand? _fuzzyBrandLookup(String subject, String text) {
    final tokens = '$subject $text'
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 4)
        .toSet();

    _Brand? best;
    int bestDist = 99;

    for (final token in tokens) {
      for (final entry in _brandMap.entries) {
        final key = entry.key.trim();
        if (key.contains(' ')) continue; // skip multi-word brands for fuzzy
        if ((key.length - token.length).abs() > 2) continue; // fast length pre-filter

        final threshold = key.length >= 6 ? 2 : 1;
        final dist = _levenshtein(token, key);
        if (dist <= threshold && dist < bestDist) {
          best = entry.value;
          bestDist = dist;
        }
      }
    }
    return best;
  }

  /// Classic Levenshtein edit distance (O(m×n), capped at short strings).
  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final dp = List.generate(
      a.length + 1,
          (i) => List.generate(b.length + 1, (j) => i == 0 ? j : (j == 0 ? i : 0)),
    );

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
            .reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[a.length][b.length];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBJECT EXTRACTION — ordered strategies, first non-empty wins
  // ═══════════════════════════════════════════════════════════════════════════

  static String _extractSubject(
      String text,
      String rawText,
      RegExpMatch? amountMatch,
      double parsedAmount,
      TransactionType type,
      ) {
    var work = text;

    // Remove the amount phrase from the working text.
    if (amountMatch != null) {
      final matchedStr = amountMatch.group(0);
      if (matchedStr != null) {
        work = work.replaceFirst(matchedStr.toLowerCase(), ' ');
      }
    } else if (parsedAmount > 0) {
      final numStr = parsedAmount % 1 == 0
          ? parsedAmount.toInt().toString()
          : parsedAmount.toString();
      final idx = work.lastIndexOf(numStr);
      if (idx >= 0 && idx + numStr.length <= work.length) {
        work = work.replaceRange(idx, idx + numStr.length, ' ');
      }
    }

    work = work
        .replaceAll(RegExp(r'\b(?:rupees?|rs\.?|inr|₹)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(?:worth|costing?|costs?|price)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    String? candidate;

    // Strategy 1: "for <noun>"
    candidate = _matchPrep(work, r'for', allowStopWords: false);
    if (candidate != null) return candidate;

    // Strategy 2: "to <noun>"
    candidate = _matchPrep(work, r'to', allowStopWords: false);
    if (candidate != null) return candidate;

    // Strategy 3: Income "from <noun>"
    if (type == TransactionType.income) {
      candidate = _matchPrep(work, r'from', allowStopWords: false);
      if (candidate != null) return candidate;
    }

    // Strategy 4: verb + direct object
    final verbMatch = RegExp(
      r'\b(?:bought|purchased|ordered|ate|had|drank|booked|hired|'
      r'subscribed\s+to|visited|watched|paid\s+for|spent\s+on|used\s+on)'
      r'\s+(?:an?\s+)?([a-z][a-z0-9 ]{0,35}?)(?=\s+(?:worth|costing|for|from|at|in|on|by|\d)|$)',
      caseSensitive: false,
    ).firstMatch(work);
    if (verbMatch != null) {
      final c = _trim(verbMatch.group(1)!);
      if (c.isNotEmpty) return c;
    }

    // Strategy 5: "at <place>"
    candidate = _matchPrep(work, r'at', allowStopWords: false);
    if (candidate != null) return candidate;

    // Strategy 6: "on <noun>"
    candidate = _matchPrep(work, r'on', allowStopWords: false);
    if (candidate != null) return candidate;

    // Strategy 7: First meaningful token (digits already handled by pre-processing)
    final tokens = work
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_stopWords.contains(t.toLowerCase()))
        .toList();
    return tokens.isNotEmpty ? tokens.first : '';
  }

  static String? _matchPrep(String text, String prep,
      {bool allowStopWords = false}) {
    final pattern = RegExp(
      '\\b$prep\\s+(?:the\\s+|a\\s+|an\\s+)?'
      r'([a-z][a-z0-9 ]{0,35}?)(?=\s+(?:for|from|at|in|on|by|to|and|'
      r'worth|costing|rupees|rs|inr|₹|\d)|$)',
      caseSensitive: false,
    );
    final m = pattern.firstMatch(text);
    if (m == null) return null;
    final candidate = _trim(m.group(1)!);
    if (candidate.isEmpty) return null;
    final first = candidate.split(' ').first.toLowerCase();
    if (!allowStopWords && _stopWords.contains(first)) return null;
    return candidate;
  }

  static String _trim(String s) {
    final words = s.split(' ');
    while (words.isNotEmpty && _stopWords.contains(words.last.toLowerCase())) {
      words.removeLast();
    }
    return words.join(' ').trim();
  }

  static String _fallbackTitle(String transcript) =>
      transcript.trim().split(RegExp(r'\s+')).take(4).join(' ');

  static String _capitalize(String s) => s.isEmpty
      ? s
      : s
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal model
// ─────────────────────────────────────────────────────────────────────────────

class _Brand {
  final String category;
  final String title;
  const _Brand(this.category, this.title);
}
