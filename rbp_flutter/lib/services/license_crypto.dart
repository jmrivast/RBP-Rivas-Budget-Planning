import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

class LicensePayload {
  const LicensePayload({
    required this.version,
    required this.machineFingerprint,
    required this.issuedAt,
    required this.flags,
  });

  final int version;
  final String machineFingerprint;
  final DateTime issuedAt;
  final int flags;
}

class LicenseCrypto {
  static const int currentVersion = 3;
  static const int _legacyVersion = 2;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _legacyIvLength = 16;
  static const int _macLength = 16;
  static const int _fingerprintLength = 16;
  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const String _publicSalt = String.fromEnvironment(
    'RBP_LICENSE_SALT',
    defaultValue: 'RBP_SECRET_SALT_CHANGE_ME',
  );
  static const String _aesSecret = String.fromEnvironment(
    'RBP_LICENSE_AES_SECRET',
    defaultValue: 'RBP_AES_SECRET_CHANGE_ME',
  );
  static final AesGcm _aesGcm = AesGcm.with256bits();

  static Future<String> generateLicenseToken(
    String machineId, {
    DateTime? issuedAt,
  }) async {
    final normalizedMachine = _normalizeMachine(machineId);
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final payload = _buildPayloadBytes(
      machineFingerprint: _machineFingerprint(normalizedMachine),
      issuedAt: issuedAt ?? DateTime.now().toUtc(),
      flags: 1,
    );
    final key = _deriveKey(
      purpose: 'license-token-v3',
      normalizedMachine: normalizedMachine,
      salt: salt,
    );
    final secretBox = await _aesGcm.encrypt(
      payload,
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: utf8.encode('rbp-license-v3'),
    );
    final envelope = Uint8List.fromList([
      currentVersion,
      ...salt,
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return _groupToken(_encodeBase32(envelope));
  }

  static Future<LicensePayload?> decryptLicenseToken(
    String machineId,
    String token,
  ) async {
    try {
      final bytes = _decodeBase32(_stripToken(token));
      if (bytes.isEmpty) {
        return null;
      }
      final version = bytes[0];
      if (version == currentVersion) {
        return _decryptVersion3License(machineId, bytes);
      }
      if (version == _legacyVersion) {
        return _decryptLegacyLicense(machineId, bytes);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String> encryptLocalRecord({
    required String machineId,
    required Map<String, Object?> payload,
  }) async {
    final normalizedMachine = _normalizeMachine(machineId);
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final plain = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    final key = _deriveKey(
      purpose: 'local-record-v3',
      normalizedMachine: normalizedMachine,
      salt: salt,
    );
    final secretBox = await _aesGcm.encrypt(
      plain,
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: utf8.encode('rbp-local-record-v3'),
    );
    final envelope = Uint8List.fromList([
      currentVersion,
      ...salt,
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return _groupToken(_encodeBase32(envelope));
  }

  static Future<Map<String, Object?>?> decryptLocalRecord({
    required String machineId,
    required String token,
  }) async {
    try {
      final bytes = _decodeBase32(_stripToken(token));
      if (bytes.isEmpty) {
        return null;
      }
      final version = bytes[0];
      if (version == currentVersion) {
        return _decryptVersion3LocalRecord(machineId, bytes);
      }
      if (version == _legacyVersion) {
        return _decryptLegacyLocalRecord(machineId, bytes);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String machineFingerprint(String machineId) {
    return _machineFingerprint(_normalizeMachine(machineId));
  }

  static bool looksLikeV2Token(String key) {
    final raw = _stripToken(key);
    if (raw.length < 80) {
      return false;
    }
    return RegExp(r'^[A-Z2-7]+$').hasMatch(raw);
  }

  static String normalizeToken(String key) {
    final raw = _stripToken(key);
    if (raw.isEmpty) {
      return '';
    }
    return _groupToken(raw);
  }

  static Future<LicensePayload?> _decryptVersion3License(
    String machineId,
    Uint8List bytes,
  ) async {
    if (bytes.length < 1 + _saltLength + _nonceLength + _macLength + 1) {
      return null;
    }
    const saltStart = 1;
    const nonceStart = saltStart + _saltLength;
    const cipherStart = nonceStart + _nonceLength;
    final macStart = bytes.length - _macLength;
    final salt = Uint8List.fromList(bytes.sublist(saltStart, nonceStart));
    final nonce = Uint8List.fromList(bytes.sublist(nonceStart, cipherStart));
    final cipherText = Uint8List.fromList(bytes.sublist(cipherStart, macStart));
    final mac = Mac(bytes.sublist(macStart));
    final normalizedMachine = _normalizeMachine(machineId);
    final key = _deriveKey(
      purpose: 'license-token-v3',
      normalizedMachine: normalizedMachine,
      salt: salt,
    );
    final plain = await _aesGcm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: SecretKey(key),
      aad: utf8.encode('rbp-license-v3'),
    );
    return _parsePayloadBytes(Uint8List.fromList(plain), normalizedMachine,
        expectedVersion: currentVersion);
  }

  static Future<Map<String, Object?>?> _decryptVersion3LocalRecord(
    String machineId,
    Uint8List bytes,
  ) async {
    if (bytes.length < 1 + _saltLength + _nonceLength + _macLength + 1) {
      return null;
    }
    const saltStart = 1;
    const nonceStart = saltStart + _saltLength;
    const cipherStart = nonceStart + _nonceLength;
    final macStart = bytes.length - _macLength;
    final salt = Uint8List.fromList(bytes.sublist(saltStart, nonceStart));
    final nonce = Uint8List.fromList(bytes.sublist(nonceStart, cipherStart));
    final cipherText = Uint8List.fromList(bytes.sublist(cipherStart, macStart));
    final mac = Mac(bytes.sublist(macStart));
    final normalizedMachine = _normalizeMachine(machineId);
    final key = _deriveKey(
      purpose: 'local-record-v3',
      normalizedMachine: normalizedMachine,
      salt: salt,
    );
    final plain = await _aesGcm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: SecretKey(key),
      aad: utf8.encode('rbp-local-record-v3'),
    );
    final decoded = jsonDecode(utf8.decode(plain));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  }

  static LicensePayload? _decryptLegacyLicense(String machineId, Uint8List bytes) {
    if (bytes.length < 1 + _saltLength + _legacyIvLength + _macLength + 1) {
      return null;
    }
    const saltStart = 1;
    const ivStart = saltStart + _saltLength;
    const cipherStart = ivStart + _legacyIvLength;
    final macStart = bytes.length - _macLength;
    final salt = Uint8List.fromList(bytes.sublist(saltStart, ivStart));
    final iv = Uint8List.fromList(bytes.sublist(ivStart, cipherStart));
    final cipherText = Uint8List.fromList(bytes.sublist(cipherStart, macStart));
    final mac = Uint8List.fromList(bytes.sublist(macStart));

    final normalizedMachine = _normalizeMachine(machineId);
    final key = _deriveLegacyKey(
      purpose: 'license-token',
      normalizedMachine: normalizedMachine,
      salt: salt,
    );
    final macKey = _deriveLegacyMacKey(
      purpose: 'license-token',
      normalizedMachine: normalizedMachine,
      salt: salt,
    );
    final envelope = Uint8List.fromList(bytes.sublist(0, macStart));
    final expectedMac = _computeLegacyMac(macKey, envelope);
    if (!_constantTimeEquals(expectedMac, mac)) {
      return null;
    }

    final plain = _legacyAesCtrTransform(cipherText, key, iv);
    return _parsePayloadBytes(plain, normalizedMachine,
        expectedVersion: _legacyVersion);
  }

  static Map<String, Object?>? _decryptLegacyLocalRecord(
    String machineId,
    Uint8List bytes,
  ) {
    if (bytes.length < 1 + _saltLength + _legacyIvLength + _macLength + 1) {
      return null;
    }
    const saltStart = 1;
    const ivStart = saltStart + _saltLength;
    const cipherStart = ivStart + _legacyIvLength;
    final macStart = bytes.length - _macLength;
    final salt = Uint8List.fromList(bytes.sublist(saltStart, ivStart));
    final iv = Uint8List.fromList(bytes.sublist(ivStart, cipherStart));
    final cipherText = Uint8List.fromList(bytes.sublist(cipherStart, macStart));
    final mac = Uint8List.fromList(bytes.sublist(macStart));

    final normalizedMachine = _normalizeMachine(machineId);
    final key = _deriveLegacyKey(
      purpose: 'local-record',
      normalizedMachine: normalizedMachine,
      salt: salt,
    );
    final macKey = _deriveLegacyMacKey(
      purpose: 'local-record',
      normalizedMachine: normalizedMachine,
      salt: salt,
    );
    final envelope = Uint8List.fromList(bytes.sublist(0, macStart));
    final expectedMac = _computeLegacyMac(macKey, envelope);
    if (!_constantTimeEquals(expectedMac, mac)) {
      return null;
    }

    final plain = _legacyAesCtrTransform(cipherText, key, iv);
    final decoded = jsonDecode(utf8.decode(plain));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  }

  static String _normalizeMachine(String machineId) {
    return machineId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static Uint8List _buildPayloadBytes({
    required String machineFingerprint,
    required DateTime issuedAt,
    required int flags,
  }) {
    final bytes = Uint8List(21);
    final fingerprintBytes = _hexToBytes(machineFingerprint);
    bytes.setRange(0, _fingerprintLength, fingerprintBytes);
    final issuedSeconds = issuedAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    bytes[16] = (issuedSeconds >> 24) & 0xff;
    bytes[17] = (issuedSeconds >> 16) & 0xff;
    bytes[18] = (issuedSeconds >> 8) & 0xff;
    bytes[19] = issuedSeconds & 0xff;
    bytes[20] = flags & 0xff;
    return bytes;
  }

  static LicensePayload? _parsePayloadBytes(
    Uint8List plain,
    String normalizedMachine, {
    required int expectedVersion,
  }) {
    if (plain.length != 21) {
      return null;
    }
    final machineFingerprint = _bytesToHex(plain.sublist(0, _fingerprintLength));
    final expectedFingerprint = _machineFingerprint(normalizedMachine);
    if (machineFingerprint != expectedFingerprint) {
      return null;
    }
    final issuedSeconds =
        (plain[16] << 24) | (plain[17] << 16) | (plain[18] << 8) | plain[19];
    final flags = plain[20];
    final issuedAt = DateTime.fromMillisecondsSinceEpoch(
      issuedSeconds * 1000,
      isUtc: true,
    );
    return LicensePayload(
      version: expectedVersion,
      machineFingerprint: machineFingerprint,
      issuedAt: issuedAt,
      flags: flags,
    );
  }

  static Uint8List _deriveKey({
    required String purpose,
    required String normalizedMachine,
    required Uint8List salt,
  }) {
    final digest = crypto.sha256.convert(
      utf8.encode(
        '$purpose|$normalizedMachine|${_bytesToHex(salt)}|$_publicSalt|$_aesSecret',
      ),
    );
    return Uint8List.fromList(digest.bytes);
  }

  static Uint8List _deriveLegacyKey({
    required String purpose,
    required String normalizedMachine,
    required Uint8List salt,
  }) {
    final digest = crypto.sha256.convert(
      utf8.encode(
        '$purpose|$normalizedMachine|${_bytesToHex(salt)}|$_publicSalt|$_aesSecret',
      ),
    );
    return Uint8List.fromList(digest.bytes);
  }

  static Uint8List _deriveLegacyMacKey({
    required String purpose,
    required String normalizedMachine,
    required Uint8List salt,
  }) {
    final digest = crypto.sha256.convert(
      utf8.encode(
        'mac|$purpose|$normalizedMachine|${_bytesToHex(salt)}|$_publicSalt|$_aesSecret',
      ),
    );
    return Uint8List.fromList(digest.bytes);
  }

  static String _machineFingerprint(String normalizedMachine) {
    final digest = crypto.sha256.convert(
      utf8.encode('fingerprint|$normalizedMachine|$_publicSalt|$_aesSecret'),
    );
    return _bytesToHex(digest.bytes.sublist(0, _fingerprintLength));
  }

  static Uint8List _computeLegacyMac(Uint8List key, Uint8List data) {
    final mac = crypto.Hmac(crypto.sha256, key).convert(data);
    return Uint8List.fromList(mac.bytes.sublist(0, _macLength));
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static String _stripToken(String key) {
    return key.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
  }

  static String _groupToken(String raw) {
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 5 == 0) {
        buffer.write('-');
      }
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  static String _encodeBase32(Uint8List bytes) {
    if (bytes.isEmpty) {
      return '';
    }
    final output = StringBuffer();
    var buffer = 0;
    var bitsLeft = 0;
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        final index = (buffer >> (bitsLeft - 5)) & 31;
        bitsLeft -= 5;
        output.write(_base32Alphabet[index]);
      }
    }
    if (bitsLeft > 0) {
      final index = (buffer << (5 - bitsLeft)) & 31;
      output.write(_base32Alphabet[index]);
    }
    return output.toString();
  }

  static Uint8List _decodeBase32(String input) {
    final values = <int>[];
    for (final rune in input.runes) {
      final index = _base32Alphabet.indexOf(String.fromCharCode(rune));
      if (index < 0) {
        throw const FormatException('Invalid base32 token.');
      }
      values.add(index);
    }
    var buffer = 0;
    var bitsLeft = 0;
    final output = <int>[];
    for (final value in values) {
      buffer = (buffer << 5) | value;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        output.add((buffer >> bitsLeft) & 0xff);
      }
    }
    if (bitsLeft > 0 && (buffer & ((1 << bitsLeft) - 1)) != 0) {
      throw const FormatException('Invalid base32 remainder.');
    }
    return Uint8List.fromList(output);
  }

  static Uint8List _hexToBytes(String hex) {
    final cleaned = hex.trim();
    final bytes = <int>[];
    for (var i = 0; i < cleaned.length; i += 2) {
      bytes.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  static String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString().toUpperCase();
  }

  static bool _constantTimeEquals(Uint8List left, Uint8List right) {
    if (left.length != right.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < left.length; i++) {
      diff |= left[i] ^ right[i];
    }
    return diff == 0;
  }

  static Uint8List _legacyAesCtrTransform(Uint8List input, Uint8List key, Uint8List iv) {
    final cipher = _AesEngine(key);
    final counter = Uint8List.fromList(iv);
    final output = Uint8List(input.length);
    var offset = 0;
    while (offset < input.length) {
      final block = cipher.encryptBlock(counter);
      final remaining = input.length - offset;
      final blockSize = remaining >= 16 ? 16 : remaining;
      for (var i = 0; i < blockSize; i++) {
        output[offset + i] = input[offset + i] ^ block[i];
      }
      offset += blockSize;
      _incrementCounter(counter);
    }
    return output;
  }

  static void _incrementCounter(Uint8List counter) {
    for (var i = counter.length - 1; i >= 0; i--) {
      counter[i] = (counter[i] + 1) & 0xff;
      if (counter[i] != 0) {
        break;
      }
    }
  }
}

class _AesEngine {
  _AesEngine(Uint8List key)
      : _sbox = _buildSBox(),
        _expandedKey = _expandKey(key, _buildSBox()),
        _rounds = (key.length ~/ 4) + 6;

  final Uint8List _sbox;
  final Uint8List _expandedKey;
  final int _rounds;

  Uint8List encryptBlock(Uint8List input) {
    if (input.length != 16) {
      throw ArgumentError('AES block must be 16 bytes.');
    }
    final state = Uint8List.fromList(input);
    _addRoundKey(state, 0);
    for (var round = 1; round < _rounds; round++) {
      _subBytes(state);
      _shiftRows(state);
      _mixColumns(state);
      _addRoundKey(state, round);
    }
    _subBytes(state);
    _shiftRows(state);
    _addRoundKey(state, _rounds);
    return state;
  }

  void _addRoundKey(Uint8List state, int round) {
    final offset = round * 16;
    for (var i = 0; i < 16; i++) {
      state[i] ^= _expandedKey[offset + i];
    }
  }

  void _subBytes(Uint8List state) {
    for (var i = 0; i < 16; i++) {
      state[i] = _sbox[state[i]];
    }
  }

  void _shiftRows(Uint8List state) {
    final copy = Uint8List.fromList(state);
    state[0] = copy[0];
    state[4] = copy[4];
    state[8] = copy[8];
    state[12] = copy[12];

    state[1] = copy[5];
    state[5] = copy[9];
    state[9] = copy[13];
    state[13] = copy[1];

    state[2] = copy[10];
    state[6] = copy[14];
    state[10] = copy[2];
    state[14] = copy[6];

    state[3] = copy[15];
    state[7] = copy[3];
    state[11] = copy[7];
    state[15] = copy[11];
  }

  void _mixColumns(Uint8List state) {
    for (var col = 0; col < 4; col++) {
      final index = col * 4;
      final a0 = state[index];
      final a1 = state[index + 1];
      final a2 = state[index + 2];
      final a3 = state[index + 3];
      state[index] = _mul2(a0) ^ _mul3(a1) ^ a2 ^ a3;
      state[index + 1] = a0 ^ _mul2(a1) ^ _mul3(a2) ^ a3;
      state[index + 2] = a0 ^ a1 ^ _mul2(a2) ^ _mul3(a3);
      state[index + 3] = _mul3(a0) ^ a1 ^ a2 ^ _mul2(a3);
    }
  }

  static Uint8List _expandKey(Uint8List key, Uint8List sbox) {
    final nk = key.length ~/ 4;
    if (nk != 4 && nk != 6 && nk != 8) {
      throw ArgumentError('AES key must be 128, 192 or 256 bits.');
    }
    final rounds = nk + 6;
    final expandedLength = 16 * (rounds + 1);
    final expanded = Uint8List(expandedLength);
    expanded.setRange(0, key.length, key);
    final temp = Uint8List(4);
    var bytesGenerated = key.length;
    var rconIndex = 1;
    while (bytesGenerated < expandedLength) {
      temp.setRange(0, 4, expanded.sublist(bytesGenerated - 4, bytesGenerated));
      if (bytesGenerated % key.length == 0) {
        _rotWord(temp);
        _subWord(temp, sbox);
        temp[0] ^= _rcon(rconIndex++);
      } else if (nk > 6 && bytesGenerated % key.length == 16) {
        _subWord(temp, sbox);
      }
      for (var i = 0; i < 4; i++) {
        expanded[bytesGenerated] = expanded[bytesGenerated - key.length] ^ temp[i];
        bytesGenerated++;
      }
    }
    return expanded;
  }

  static void _rotWord(Uint8List word) {
    final first = word[0];
    word[0] = word[1];
    word[1] = word[2];
    word[2] = word[3];
    word[3] = first;
  }

  static void _subWord(Uint8List word, Uint8List sbox) {
    for (var i = 0; i < 4; i++) {
      word[i] = sbox[word[i]];
    }
  }

  static int _rcon(int index) {
    var value = 1;
    for (var i = 1; i < index; i++) {
      value = _xtime(value);
    }
    return value;
  }

  static Uint8List _buildSBox() {
    final sbox = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      final inv = i == 0 ? 0 : _gfPow(i, 254);
      final value = inv ^ _rotl8(inv, 1) ^ _rotl8(inv, 2) ^ _rotl8(inv, 3) ^ _rotl8(inv, 4) ^ 0x63;
      sbox[i] = value & 0xff;
    }
    return sbox;
  }

  static int _rotl8(int value, int shift) {
    return ((value << shift) | (value >> (8 - shift))) & 0xff;
  }

  static int _gfPow(int base, int exponent) {
    var result = 1;
    var factor = base;
    var power = exponent;
    while (power > 0) {
      if ((power & 1) == 1) {
        result = _gfMul(result, factor);
      }
      factor = _gfMul(factor, factor);
      power >>= 1;
    }
    return result;
  }

  static int _gfMul(int left, int right) {
    var a = left;
    var b = right;
    var result = 0;
    while (b > 0) {
      if ((b & 1) != 0) {
        result ^= a;
      }
      a = _xtime(a);
      b >>= 1;
    }
    return result & 0xff;
  }

  static int _xtime(int value) {
    final shifted = value << 1;
    return ((shifted & 0xff) ^ ((value & 0x80) != 0 ? 0x1b : 0x00)) & 0xff;
  }

  static int _mul2(int value) => _xtime(value);
  static int _mul3(int value) => _xtime(value) ^ value;
}




