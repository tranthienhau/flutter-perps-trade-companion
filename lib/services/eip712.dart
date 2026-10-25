import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/digests/keccak.dart';

/// Minimal EIP-712 encoder for flat structs (address, bool, string, uintN,
/// bytes32). Enough to build and hash the two messages this app signs:
/// the one-time session key registration and each trade intent.
Uint8List keccak256(List<int> data) => KeccakDigest(256).process(Uint8List.fromList(data));

String toHex(List<int> b) => '0x${hex.encode(b)}';

class Field {
  const Field(this.name, this.type);
  final String name;
  final String type;
}

class TypedStruct {
  const TypedStruct(this.name, this.fields);
  final String name;
  final List<Field> fields;

  String get encodeType => '$name(${fields.map((f) => '${f.type} ${f.name}').join(',')})';
  Uint8List get typeHash => keccak256(utf8.encode(encodeType));

  Uint8List hashStruct(Map<String, Object> v) {
    final out = BytesBuilder()..add(typeHash);
    for (final f in fields) {
      out.add(_encodeValue(f.type, v[f.name]!));
    }
    return keccak256(out.toBytes());
  }
}

Uint8List _word(BigInt n) {
  final h = n.toRadixString(16).padLeft(64, '0');
  return Uint8List.fromList(hex.decode(h));
}

Uint8List _encodeValue(String type, Object value) {
  if (type == 'string') return keccak256(utf8.encode(value as String));
  if (type == 'bool') return _word(BigInt.from((value as bool) ? 1 : 0));
  if (type == 'address') return _word(BigInt.parse((value as String).substring(2), radix: 16));
  if (type == 'bytes32') return Uint8List.fromList(hex.decode((value as String).substring(2)));
  if (type.startsWith('uint')) return _word(value is BigInt ? value : BigInt.from(value as int));
  throw ArgumentError('unsupported EIP-712 type $type');
}

const domainType = TypedStruct('EIP712Domain', [
  Field('name', 'string'),
  Field('version', 'string'),
  Field('chainId', 'uint256'),
  Field('verifyingContract', 'address'),
]);

/// Signed once by the user's main wallet. Registers the server-held agent key
/// with a hard expiry and the approved builder fee address.
const approveAgentType = TypedStruct('ApproveAgent', [
  Field('agent', 'address'),
  Field('agentName', 'string'),
  Field('builder', 'address'),
  Field('validUntil', 'uint64'),
  Field('nonce', 'uint64'),
]);

/// Signed by the agent key for every open or close. There is no field for
/// transfers or withdrawals, so the key has nothing else it can authorize.
const tradeIntentType = TypedStruct('TradeIntent', [
  Field('account', 'address'),
  Field('asset', 'uint32'),
  Field('isBuy', 'bool'),
  Field('size', 'string'),
  Field('limitPx', 'string'),
  Field('triggerPx', 'string'),
  Field('reduceOnly', 'bool'),
  Field('nonce', 'uint64'),
]);

class Eip712Message {
  const Eip712Message(this.domain, this.type, this.message);
  final Map<String, Object> domain;
  final TypedStruct type;
  final Map<String, Object> message;

  Uint8List get domainSeparator => domainType.hashStruct(domain);

  /// keccak256("\x19\x01" || domainSeparator || hashStruct(message))
  Uint8List get digest => keccak256([0x19, 0x01, ...domainSeparator, ...type.hashStruct(message)]);

  Map<String, Object> toJson() => {
        'primaryType': type.name,
        'domain': domain,
        'types': {type.name: type.fields.map((f) => {'name': f.name, 'type': f.type}).toList()},
        'message': message,
      };
}

const exchangeDomain = <String, Object>{
  'name': 'Exchange',
  'version': '1',
  'chainId': 42161,
  'verifyingContract': '0x0000000000000000000000000000000000000000',
};
