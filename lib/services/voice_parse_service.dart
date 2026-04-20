import '../models/isar_expense.dart';
import '../models/voice_parse_result.dart';

/// Pure-Dart, on-device NLP parser — zero latency, no network calls.
///
/// Parse priority pipeline:
///   1. Strip command/meta words  ("add expense", "log income", "record", …)
///   2. Extract amount            (currency-qualified → bare number fallback)
///   3. Detect transaction type   (explicit command word → keyword scan)
///   4. Extract subject/topic     (for-phrase → verb-object → at/on → tokens)
///   5. Brand/service lookup      (uber → Travel/"Uber", zomato → Food/"Zomato", …)
///   6. Social-context check      (friends, mom, party, … → Social)
///   7. Generic keyword category  (petrol → Travel, gym → Health, …)
///   8. Derive title + category   (from subject, brand, or social noun)
class VoiceParseService {
  VoiceParseService._();

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Command / meta words stripped before NLP
  // ───────────────────────────────────────────────────────────────────────────

  static final _commandWordRegex = RegExp(
    r'\b(?:add|log|record|track|note|create|new|mark|enter|save|register)\b',
    caseSensitive: false,
  );
  static final _metaWordRegex = RegExp(
    r'\b(?:expense|income|transaction|entry|spending|payment|transfer)\b',
    caseSensitive: false,
  );

  /// Words that explicitly set [TransactionType] regardless of other signals.
  static const Map<String, TransactionType> _explicitTypeWords = {
    'expense':     TransactionType.expense,
    'spending':    TransactionType.expense,
    'spent':       TransactionType.expense,
    'debit':       TransactionType.expense,
    'paid':        TransactionType.expense,
    'bought':      TransactionType.expense,
    'purchased':   TransactionType.expense,
    'income':      TransactionType.income,
    'earning':     TransactionType.income,
    'earned':      TransactionType.income,
    'received':    TransactionType.income,
    'credited':    TransactionType.income,
    'salary':      TransactionType.income,
    'got':         TransactionType.income,
  };

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Amount regexes
  // ───────────────────────────────────────────────────────────────────────────

  /// Priority order (first match wins):
  ///   G1 – ₹400 / ₹ 400
  ///   G2 – 400 rupees / 400 rs
  ///   G3 – rupees 400
  ///   G4 – "worth|costing|cost|price" + optional-currency + number
  static final _currencyAmountRegex = RegExp(
    r'(?:₹\s?(\d+(?:\.\d+)?))'
    r'|(?:(\d+(?:\.\d+)?)\s*(?:rupees?|rs\.?|inr)\b)'
    r'|(?:(?:rupees?|rs\.?|inr)\s*(\d+(?:\.\d+)?))'
    r'|(?:(?:worth|costing?|costs?|price)\s+(?:rupees?|rs\.?|₹\s?)?\s*(\d+(?:\.\d+)?))',
    caseSensitive: false,
  );

  /// "of 400" / "of ₹400" — lower priority than full currency match.
  static final _ofAmountRegex = RegExp(
    r'\bof\s+(?:rupees?|rs\.?|₹\s?)?(\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  );

  static final _bareNumberRegex = RegExp(r'\b(\d+(?:\.\d+)?)\b');

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Brand / service / place map  →  canonical {category, title}
  //    Checked BEFORE generic keyword maps for precision.
  //    Add entries freely; keys are lower-cased substrings.
  // ───────────────────────────────────────────────────────────────────────────

  static const Map<String, _Brand> _brandMap = {
    // ── Ride-sharing & transport ──────────────────────────────────────────
    'uber':           _Brand('Travel', 'Uber'),
    'ola':            _Brand('Travel', 'Ola'),
    'rapido':         _Brand('Travel', 'Rapido'),
    'lyft':           _Brand('Travel', 'Lyft'),
    'irctc':          _Brand('Travel', 'IRCTC'),
    'makemytrip':     _Brand('Travel', 'MakeMyTrip'),
    'redbus':         _Brand('Travel', 'RedBus'),
    'indigo':         _Brand('Travel', 'IndiGo'),
    'spicejet':       _Brand('Travel', 'SpiceJet'),
    'air india':      _Brand('Travel', 'Air India'),
    'vistara':        _Brand('Travel', 'Vistara'),

    // ── Food delivery & restaurants ───────────────────────────────────────
    'swiggy':         _Brand('Food', 'Swiggy'),
    'zomato':         _Brand('Food', 'Zomato'),
    'dominos':        _Brand('Food', "Domino's"),
    "domino's":       _Brand('Food', "Domino's"),
    'mcdonalds':      _Brand('Food', "McDonald's"),
    "mcdonald's":     _Brand('Food', "McDonald's"),
    'kfc':            _Brand('Food', 'KFC'),
    'subway':         _Brand('Food', 'Subway'),
    'starbucks':      _Brand('Food', 'Starbucks'),
    'chaayos':        _Brand('Food', 'Chaayos'),
    "dunkin":         _Brand('Food', "Dunkin'"),
    'blinkit':        _Brand('Food', 'Blinkit'),
    'zepto':          _Brand('Food', 'Zepto'),
    'bigbasket':      _Brand('Food', 'BigBasket'),
    'big basket':     _Brand('Food', 'BigBasket'),
    'instamart':      _Brand('Food', 'Instamart'),
    'burger king':    _Brand('Food', 'Burger King'),
    'pizza hut':      _Brand('Food', 'Pizza Hut'),
    'haldiram':       _Brand('Food', 'Haldirams'),
    "mcdonald":       _Brand('Food', "McDonald's"),

    // ── Shopping ─────────────────────────────────────────────────────────
    'amazon':         _Brand('Shopping', 'Amazon'),
    'flipkart':       _Brand('Shopping', 'Flipkart'),
    'myntra':         _Brand('Shopping', 'Myntra'),
    'meesho':         _Brand('Shopping', 'Meesho'),
    'nykaa':          _Brand('Shopping', 'Nykaa'),
    'ajio':           _Brand('Shopping', 'Ajio'),
    'ikea':           _Brand('Shopping', 'IKEA'),
    'reliance':       _Brand('Shopping', 'Reliance'),
    'dmart':          _Brand('Shopping', 'D-Mart'),
    'd-mart':         _Brand('Shopping', 'D-Mart'),
    'snapdeal':       _Brand('Shopping', 'Snapdeal'),
    'croma':          _Brand('Shopping', 'Croma'),

    // ── Entertainment ────────────────────────────────────────────────────
    'netflix':        _Brand('Entertainment', 'Netflix'),
    'spotify':        _Brand('Entertainment', 'Spotify'),
    'hotstar':        _Brand('Entertainment', 'Hotstar'),
    'disney+':        _Brand('Entertainment', 'Disney+'),
    'disney plus':    _Brand('Entertainment', 'Disney+'),
    'prime video':    _Brand('Entertainment', 'Prime Video'),
    'amazon prime':   _Brand('Entertainment', 'Prime Video'),
    'youtube':        _Brand('Entertainment', 'YouTube Premium'),
    'bookmyshow':     _Brand('Entertainment', 'BookMyShow'),
    'pvr':            _Brand('Entertainment', 'PVR'),
    'inox':           _Brand('Entertainment', 'INOX'),
    'jiocinema':      _Brand('Entertainment', 'JioCinema'),
    'sony liv':       _Brand('Entertainment', 'SonyLIV'),
    'sonyliv':        _Brand('Entertainment', 'SonyLIV'),
    'zee5':           _Brand('Entertainment', 'ZEE5'),
    'mxplayer':       _Brand('Entertainment', 'MX Player'),
    'mx player':      _Brand('Entertainment', 'MX Player'),
    'apple music':    _Brand('Entertainment', 'Apple Music'),

    // ── Utilities & telecom ───────────────────────────────────────────────
    'airtel':         _Brand('Utilities', 'Airtel'),
    'jio':            _Brand('Utilities', 'Jio'),
    ' vi ':           _Brand('Utilities', 'Vi'),   // spaces avoid false-positive "via"
    'bsnl':           _Brand('Utilities', 'BSNL'),
    'tata sky':       _Brand('Utilities', 'Tata Sky'),
    'tataplay':       _Brand('Utilities', 'Tata Play'),
    'act broadband':  _Brand('Utilities', 'ACT Broadband'),
    'hathway':        _Brand('Utilities', 'Hathway'),

    // ── Health & fitness ──────────────────────────────────────────────────
    'cultfit':        _Brand('Health', 'Cult.fit'),
    'cult.fit':       _Brand('Health', 'Cult.fit'),
    'cult fit':       _Brand('Health', 'Cult.fit'),
    'healthifyme':    _Brand('Health', 'HealthifyMe'),
    '1mg':            _Brand('Health', '1mg'),
    'apollo':         _Brand('Health', 'Apollo Pharmacy'),
    'practo':         _Brand('Health', 'Practo'),
    'netmeds':        _Brand('Health', 'Netmeds'),
    'medplus':        _Brand('Health', 'MedPlus'),
    'pharm':          _Brand('Health', 'Pharmacy'),  // "pharmacy" prefix

    // ── Finance / wallet (category = Others unless context clarifies) ─────
    'phonepe':        _Brand('Others', 'PhonePe'),
    'phone pe':       _Brand('Others', 'PhonePe'),
    'paytm':          _Brand('Others', 'Paytm'),
    'gpay':           _Brand('Others', 'Google Pay'),
    'google pay':     _Brand('Others', 'Google Pay'),
    'cred':           _Brand('Others', 'CRED'),
    'slice':          _Brand('Others', 'Slice'),

    // ── Education ────────────────────────────────────────────────────────
    'udemy':          _Brand('Education', 'Udemy'),
    'coursera':       _Brand('Education', 'Coursera'),
    'unacademy':      _Brand('Education', 'Unacademy'),
    'byju':           _Brand('Education', "BYJU's"),
    'vedantu':        _Brand('Education', 'Vedantu'),
    'khan academy':   _Brand('Education', 'Khan Academy'),
  };

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Social / people nouns → "Social" category
  // ───────────────────────────────────────────────────────────────────────────

  /// The canonical title used when matched; we prefer the extracted noun over
  /// the generic social word when a fuller phrase is found (e.g. "my girlfriend").
  static const Map<String, String> _socialWordTitles = {
    'friend':      'Friends',
    'friends':     'Friends',
    'buddy':       'Friend',
    'buddies':     'Friends',
    'pal':         'Friend',
    'pals':        'Friends',
    'family':      'Family',
    'mom':         'Mom',
    'dad':         'Dad',
    'mother':      'Mom',
    'father':      'Dad',
    'brother':     'Brother',
    'sister':      'Sister',
    'sibling':     'Sibling',
    'cousin':      'Cousin',
    'uncle':       'Uncle',
    'aunt':        'Aunt',
    'grandma':     'Grandma',
    'grandpa':     'Grandpa',
    'girlfriend':  'Girlfriend',
    'boyfriend':   'Boyfriend',
    'partner':     'Partner',
    'spouse':      'Spouse',
    'wife':        'Wife',
    'husband':     'Husband',
    'colleague':   'Colleague',
    'colleagues':  'Colleagues',
    'coworker':    'Coworker',
    'coworkers':   'Coworkers',
    'boss':        'Boss',
    'party':       'Party',
    'hangout':     'Hangout',
    'outing':      'Outing',
    'date':        'Date',
    'treat':       'Treat',
    'celebration': 'Celebration',
    'wedding':     'Wedding',
    'birthday':    'Birthday',
    'anniversary': 'Anniversary',
    'get-together':'Get-together',
  };

  // ───────────────────────────────────────────────────────────────────────────
  // 5. Generic keyword → category maps (fallback after brand + social checks)
  // ───────────────────────────────────────────────────────────────────────────

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

  // ───────────────────────────────────────────────────────────────────────────
  // 6. Stop words (excluded from title/category extraction)
  // ───────────────────────────────────────────────────────────────────────────

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
  };

  // ───────────────────────────────────────────────────────────────────────────
  // Main parse entry point
  // ───────────────────────────────────────────────────────────────────────────

  static VoiceParseResult parse(String transcript) {
    final rawText = transcript.trim();
    final text = rawText.toLowerCase();
    int score = 0;

    // ── Step 1: Detect explicit type BEFORE stripping (these words carry meaning)
    final TransactionType? explicitType = _detectExplicitType(text);
    if (explicitType != null) score += 20;

    // ── Step 2: Amount extraction ─────────────────────────────────────────────
    double amount = 0;
    RegExpMatch? usedAmountMatch;

    // Priority 1: full currency match
    final currencyMatch = _currencyAmountRegex.firstMatch(text);
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

    // Priority 2: "of 400" / "of ₹400"
    if (amount == 0) {
      final ofMatch = _ofAmountRegex.firstMatch(text);
      if (ofMatch != null) {
        amount = double.tryParse(ofMatch.group(1) ?? '') ?? 0;
        if (amount > 0) {
          usedAmountMatch = ofMatch;
          score += 30;
        }
      }
    }

    // Priority 3: bare number fallback — last number wins (quantities come first)
    if (amount == 0) {
      final allNums = _bareNumberRegex.allMatches(text).toList();
      if (allNums.isNotEmpty) {
        final best = allNums.length == 1 ? allNums.first : allNums.last;
        amount = double.tryParse(best.group(1)!) ?? 0;
        if (amount > 0) score += 15;
      }
    }

    // ── Step 3: Clean text for NLP ─────────────────────────────────────────
    final cleanText = _stripMeta(text);
    final cleanRaw  = _stripMeta(rawText);

    // ── Step 4: Transaction type ───────────────────────────────────────────
    final TransactionType type = explicitType ?? _detectTypeFromKeywords(cleanText);

    // ── Step 5: Extract subject (what the transaction is about) ───────────
    final String subject = _extractSubject(
      cleanText, cleanRaw, usedAmountMatch, amount, type,
    );

    // ── Step 6: Brand lookup (highest precision) ───────────────────────────
    _Brand? brand = _lookupBrand(subject, cleanText);
    if (brand != null) score += 30;

    // ── Step 7: Social lookup ──────────────────────────────────────────────
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

    // ── Step 8: Generic category ───────────────────────────────────────────
    String category;
    if (brand != null) {
      category = brand.category;
    } else if (socialTitle != null) {
      category = 'Social';
    } else {
      category = _detectCategoryFromKeywords(cleanText, subject, type);
      if (category != 'Others') score += 25;
    }

    // ── Step 9: Title ──────────────────────────────────────────────────────
    String title;
    if (brand != null) {
      // Use canonical brand name regardless of what user said
      title = brand.title;
    } else if (subject.isNotEmpty) {
      // Use the extracted subject; if it matches a social key, prefer its title
      final subjectLower = subject.toLowerCase();
      title = _socialWordTitles.containsKey(subjectLower)
          ? _socialWordTitles[subjectLower]!
          : _capitalize(subject);
    } else if (socialTitle != null) {
      title = socialTitle;
    } else {
      title = _fallbackTitle(rawText);
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

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// Detect type from explicit command/type words — called on raw lowercase text
  /// so "add expense" is still visible before stripping.
  static TransactionType? _detectExplicitType(String text) {
    for (final entry in _explicitTypeWords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Remove command/meta words so they don't pollute subject extraction.
  static String _stripMeta(String text) => text
      .replaceAll(_commandWordRegex, '')
      .replaceAll(_metaWordRegex, '')
      .replaceAll(RegExp(r'\bof\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  /// Keyword-based type detection used only when no explicit type word found.
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

  /// Scan [text] and [subject] against both category maps.
  static String _detectCategoryFromKeywords(
      String text, String subject, TransactionType type) {
    final map = type == TransactionType.income
        ? _incomeCategoryMap
        : _expenseCategoryMap;

    // Check the combined text first, then fall back to the subject alone
    for (final src in [text, subject.toLowerCase()]) {
      for (final entry in map.entries) {
        if (src.contains(entry.key)) return entry.value;
      }
    }
    return 'Others';
  }

  /// Brand lookup: try the extracted [subject] first, then full [text].
  /// Longest matching key wins to handle "amazon prime" vs "amazon".
  static _Brand? _lookupBrand(String subject, String text) {
    _Brand? best;
    int bestLen = 0;

    for (final entry in _brandMap.entries) {
      final key = entry.key;
      if ((subject.toLowerCase().contains(key) || text.contains(key)) &&
          key.length > bestLen) {
        best    = entry.value;
        bestLen = key.length;
      }
    }
    return best;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Subject extraction — ordered strategies, first non-empty wins
  // ───────────────────────────────────────────────────────────────────────────

  static String _extractSubject(
    String text,
    String rawText,
    RegExpMatch? amountMatch,
    double parsedAmount,
    TransactionType type,
  ) {
    // Remove the matched amount phrase from working text.
    // Use replaceFirst (value-based) NOT replaceRange (index-based) because
    // [amountMatch] indices refer to the ORIGINAL text, but [text] passed here
    // is already stripped — so index positions would be wrong and crash.
    var work = text;
    if (amountMatch != null) {
      final matchedStr = amountMatch.group(0);
      if (matchedStr != null) {
        work = work.replaceFirst(matchedStr.toLowerCase(), ' ');
      }
    } else if (parsedAmount > 0) {
      final numStr = parsedAmount % 1 == 0
          ? parsedAmount.toInt().toString()
          : parsedAmount.toString();
      // Use lastIndexOf to remove the amount (not a quantity that came before)
      final idx = work.lastIndexOf(numStr);
      if (idx >= 0 && idx + numStr.length <= work.length) {
        work = work.replaceRange(idx, idx + numStr.length, ' ');
      }
    }

    // Strip currency noise
    work = work
        .replaceAll(RegExp(r'\b(?:rupees?|rs\.?|inr|₹)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(?:worth|costing?|costs?|price)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    String? candidate;

    // ── Strategy 1: "for <noun>" — most natural voice pattern ───────────────
    // "add expense of 400 for uber"  /  "spent 200 for friends"
    candidate = _matchPrep(work, r'for', allowStopWords: false);
    if (candidate != null) return candidate;

    // ── Strategy 2: "to <noun>" — "paid 500 to John" / "sent to mom" ────────
    candidate = _matchPrep(work, r'to', allowStopWords: false);
    if (candidate != null) return candidate;

    // ── Strategy 3: Income source — "from <noun>" ───────────────────────────
    if (type == TransactionType.income) {
      candidate = _matchPrep(work, r'from', allowStopWords: false);
      if (candidate != null) return candidate;
    }

    // ── Strategy 4: Verb + direct object ────────────────────────────────────
    // "bought 2 books", "ordered pizza", "booked an uber ride"
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

    // ── Strategy 5: "at <place>" — "lunch at dominos" / "filled up at shell" ─
    candidate = _matchPrep(work, r'at', allowStopWords: false);
    if (candidate != null) return candidate;

    // ── Strategy 6: "on <noun>" — "spent on petrol" / "used on medicine" ────
    candidate = _matchPrep(work, r'on', allowStopWords: false);
    if (candidate != null) return candidate;

    // ── Strategy 7: First meaningful token ──────────────────────────────────
    final tokens = work
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_stopWords.contains(t.toLowerCase()))
        .toList();
    return tokens.isNotEmpty ? tokens.first : '';
  }

  /// Match "prep + optional-article + noun-phrase" and return the noun phrase,
  /// or null if the first meaningful word is a stop word.
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
