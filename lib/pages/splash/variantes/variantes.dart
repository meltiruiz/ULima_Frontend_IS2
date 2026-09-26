// lib/pages/splash/variantes/variantes.dart
// La variante de cada tipo (RF-SPL-6).

import '../../../services/splash_variante_service.dart';
import 'codigo.dart';
import 'ensamble.dart';
import 'incremento.dart';
import 'variante_de_intro.dart';

export 'variante_de_intro.dart';

VarianteDeIntro varianteDe(VarianteSplash tipo) => switch (tipo) {
  VarianteSplash.ensamble => const Ensamble(),
  VarianteSplash.incremento => const Incremento(),
  VarianteSplash.codigo => const Codigo(),
};
