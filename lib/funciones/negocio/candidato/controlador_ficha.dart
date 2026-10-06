/// Las URLs firmadas del video y el documento vencen. La primera vez que una
/// falla, la pantalla vuelve a pedir la ficha (URLs nuevas); a la segunda, se
/// rinde y lo dice. Pura, una por pantalla.
class ControladorFicha {
  int reintentosUrl = 0;

  bool puedeReintentarUrl() => reintentosUrl++ == 0;
}
