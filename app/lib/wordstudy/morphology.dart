/// Expands Robinson (Greek) and ETCBC/TAHOT (Hebrew) morphology codes into
/// plain English, segment by segment, so unseen codes still degrade gracefully.
///   "V-AAI-3S" → "verb · aorist active indicative, 3rd person singular"
///   "HVqp3ms"  → "verb qal perfect 3rd person masculine singular"
class Morphology {
  static const _pos = {
    'N': 'noun',
    'V': 'verb',
    'T': 'article',
    'A': 'adjective',
    'P': 'personal pronoun',
    'R': 'relative pronoun',
    'D': 'demonstrative pronoun',
    'K': 'correlative pronoun',
    'I': 'interrogative pronoun',
    'X': 'indefinite pronoun',
    'F': 'reflexive pronoun',
    'S': 'possessive pronoun',
    'C': 'reciprocal pronoun',
    'Q': 'correlative or interrogative pronoun',
    'CONJ': 'conjunction',
    'PREP': 'preposition',
    'ADV': 'adverb',
    'PRT': 'particle',
    'COND': 'conditional',
    'INJ': 'interjection',
  };
  static const _tense = {
    'P': 'present',
    'I': 'imperfect',
    'F': 'future',
    'A': 'aorist',
    'R': 'perfect',
    'L': 'pluperfect',
    '2A': '2nd aorist',
    '2F': '2nd future',
    '2R': '2nd perfect',
    '2L': '2nd pluperfect',
  };
  static const _voice = {
    'A': 'active',
    'M': 'middle',
    'P': 'passive',
    'E': 'middle or passive',
    'D': 'middle deponent',
    'O': 'passive deponent',
    'N': 'middle/passive deponent',
    'Q': 'impersonal active',
  };
  static const _mood = {
    'I': 'indicative',
    'S': 'subjunctive',
    'O': 'optative',
    'M': 'imperative',
    'N': 'infinitive',
    'P': 'participle',
    'R': 'imperative participle',
  };
  static const _case = {
    'N': 'nominative',
    'G': 'genitive',
    'D': 'dative',
    'A': 'accusative',
    'V': 'vocative',
  };
  static const _number = {'S': 'singular', 'P': 'plural'};
  static const _gender = {'M': 'masculine', 'F': 'feminine', 'N': 'neuter'};

  static const _hStem = {
    'q': 'qal',
    'N': 'niphal',
    'p': 'piel',
    'P': 'pual',
    'h': 'hiphil',
    'H': 'hophal',
    't': 'hithpael',
    'o': 'polel',
    'O': 'polal',
    'r': 'hithpolel',
  };
  static const _hConj = {
    'p': 'perfect',
    'q': 'sequential perfect',
    'i': 'imperfect',
    'w': 'sequential imperfect',
    'h': 'cohortative',
    'j': 'jussive',
    'v': 'imperative',
    'a': 'infinitive absolute',
    'c': 'infinitive construct',
    'r': 'active participle',
    's': 'passive participle',
  };
  static const _hGender = {
    'm': 'masculine',
    'f': 'feminine',
    'b': 'common',
    'c': 'common',
  };
  static const _hNumber = {'s': 'singular', 'p': 'plural', 'd': 'dual'};
  static const _hState = {'a': 'absolute', 'c': 'construct', 'd': 'determined'};
  static const _hParticle = {
    'a': 'affirmation',
    'd': 'definite article',
    'e': 'exhortation',
    'i': 'interrogative',
    'j': 'interjection',
    'm': 'demonstrative',
    'n': 'negative',
    'o': 'object marker',
    'r': 'relative',
  };

  static String describe(String code) {
    if (code.isEmpty) return code;
    final hebrew = (code[0] == 'H' || code[0] == 'A') && !code.contains('-');
    return hebrew ? _hebrew(code) : _greek(code);
  }

  static String _ordinal(String c) => switch (c) {
    '1' => 'st',
    '2' => 'nd',
    '3' => 'rd',
    _ => 'th',
  };

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  static String _hebrew(String code) {
    final aramaic = code.startsWith('A');
    final out = <String>[];
    for (final m in code.substring(1).split('/')) {
      if (m.isEmpty) continue;
      final pos = m[0];
      final rest = m.substring(1).split('');
      var i = 0;
      String? at() => i < rest.length ? rest[i] : null;
      switch (pos) {
        case 'N':
          var bits = ['noun'];
          if (at() == 'p') {
            bits = ['proper noun'];
            i++;
          } else if (at() == 'c') {
            i++;
          } else if (at() == 'g') {
            bits = ['gentilic noun'];
            i++;
          }
          if (_hGender[at()] case final g?) {
            bits.add(g);
            i++;
          }
          if (_hNumber[at()] case final n?) {
            bits.add(n);
            i++;
          }
          if (_hState[at()] case final st?) bits.add(st);
          out.add(bits.join(' '));
        case 'V':
          final bits = ['verb'];
          if (_hStem[at()] case final st?) {
            bits.add(st);
            i++;
          }
          if (_hConj[at()] case final c?) {
            bits.add(c);
            i++;
          }
          if (at() case final p? when _isDigit(p)) {
            bits.add('$p${_ordinal(p)} person');
            i++;
          }
          if (_hGender[at()] case final g?) {
            bits.add(g);
            i++;
          }
          if (_hNumber[at()] case final n?) bits.add(n);
          out.add(bits.join(' '));
        case 'T':
          out.add(_hParticle[at()] ?? 'particle');
        case 'R':
          out.add(at() == 'd' ? 'preposition with article' : 'preposition');
        case 'C' || 'c':
          out.add('conjunction');
        case 'D':
          out.add('adverb');
        case 'A':
          final bits = ['adjective'];
          if (at() == 'c' || at() == 'g' || at() == 'o') i++;
          if (_hGender[at()] case final g?) {
            bits.add(g);
            i++;
          }
          if (_hNumber[at()] case final n?) {
            bits.add(n);
            i++;
          }
          if (_hState[at()] case final st?) bits.add(st);
          out.add(bits.join(' '));
        case 'P':
          out.add('pronoun');
        case 'S':
          out.add('suffix');
        default:
          out.add(m);
      }
    }
    if (out.isEmpty) return code;
    return '${aramaic ? 'Aramaic · ' : ''}${out.join(' + ')}';
  }

  static String _greek(String code) {
    final segs = code.split('-');
    final head = _pos[segs.first];
    final detail = [for (final s in segs.skip(1)) ?_segment(s)];
    if (detail.isEmpty) return head ?? code;
    return '${head == null ? '' : '$head · '}${detail.join(', ')}';
  }

  static String? _segment(String seg) {
    if (seg.length == 2 && _isDigit(seg[0]) && _number[seg[1]] != null) {
      return '${seg[0]}${_ordinal(seg[0])} person ${_number[seg[1]]}';
    }
    if (seg.length == 3 &&
        _isDigit(seg[0]) &&
        _case[seg[1]] != null &&
        _number[seg[2]] != null) {
      return '${seg[0]}${_ordinal(seg[0])} person ${_case[seg[1]]} ${_number[seg[2]]}';
    }
    if (_tvm(seg) case final tvm?) return tvm;
    if (seg.length == 3 &&
        _case[seg[0]] != null &&
        _number[seg[1]] != null &&
        _gender[seg[2]] != null) {
      return '${_case[seg[0]]} ${_number[seg[1]]} ${_gender[seg[2]]}';
    }
    return switch (seg) {
      'P' => 'proper',
      'T' => 'title',
      'L' => 'location',
      'N' => 'name',
      'ABB' => 'abbreviated',
      'NUI' => 'numeral (indeclinable)',
      'C' => 'comparative',
      'S' => 'superlative',
      _ => null,
    };
  }

  static String? _tvm(String seg) {
    var s = seg;
    var prefix = '';
    if (s.startsWith('2') && s.length == 4) {
      prefix = '2';
      s = s.substring(1);
    }
    if (s.length != 3) return null;
    final t = _tense['$prefix${s[0]}'] ?? _tense[s[0]];
    final v = _voice[s[1]];
    final m = _mood[s[2]];
    if (t == null || v == null || m == null) return null;
    return '$t $v $m';
  }
}
