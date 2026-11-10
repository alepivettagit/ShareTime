/// Algoritmo di hash a 32 bit FNV-1a (Fowler-Noll-Vo).
/// Garantisce lo STESSO IDENTICO risultato su 64-bit Dart VM (Android nativo)
/// e 32-bit JavaScript (Flutter Web compilato), a differenza di hashCode nativo.
int fnv1a32(String input) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < input.length; i++) {
    hash ^= input.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
