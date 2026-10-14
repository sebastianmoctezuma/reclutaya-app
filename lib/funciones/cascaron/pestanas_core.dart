/// Las ramas del cascarón, en el orden de `rutas.dart`.
const ramaInicio = 0;
const ramaVacantes = 1;
const ramaSucursales = 2;
const ramaCuenta = 3;

/// Qué ramas son pestaña: Inicio · Vacantes · Sucursales · Cuenta. «Sucursales» solo
/// con varias (14-oct, como el menú de la web; antes «Vacantes» se llamaba
/// «Sucursales» y traía las sucursales adentro).
List<int> ramasVisibles({required bool variasSucursales}) => variasSucursales
    ? const [ramaInicio, ramaVacantes, ramaSucursales, ramaCuenta]
    : const [ramaInicio, ramaVacantes, ramaCuenta];

/// La pestaña que se pinta activa para la rama abierta. Una rama que ya no es pestaña
/// (la cuenta dejó de tener varias sucursales) devuelve null: hay que ir a otra.
int? pestanaDeRama(int rama, List<int> visibles) {
  final i = visibles.indexOf(rama);
  return i < 0 ? null : i;
}
