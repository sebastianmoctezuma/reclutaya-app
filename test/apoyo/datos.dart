import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';

/// Datos de ejemplo para las pruebas de widgets. Construidos con los
/// constructores, no con JSON: el parseo tiene sus propias pruebas.

const yoNegocio = Yo(
  tipo: 'negocio',
  nombre: 'Antonio',
  iniciales: 'AP',
  rol: 'owner',
  veDinero: true,
  empresa: EmpresaYo(nombre: 'Tacos Don Beto', logoFit: 'cover'),
);

const yoCandidato = Yo(
  tipo: 'candidato',
  nombre: 'Ana',
  iniciales: 'AP',
  correo: 'ana@correo.com',
);

const inicioEjemplo = Inicio(
  indicadores: Indicadores(
    velocidad: 2.5,
    velocidadDelta: 10,
    cumplenPct: 60,
    cumplenN: 6,
    cumplenTotal: 10,
    cumplenDelta: 5,
    respuestaPct: 70,
    respuestaDelta: -3,
    tiempoDias: 4,
    tiempoDelta: -1,
  ),
  saldo: Saldo(plan: 20, extra: 3, total: 23),
);

const vacanteActiva = VacanteResumen(
  id: 'v1',
  puesto: 'Mesero',
  estado: 'ACTIVA',
  slug: 'mesero-abc',
  ubicacion: 'Reynosa',
  sueldoTexto: r'$2,500 semanales',
  sucursal: SucursalRef(id: 's1', nombre: 'Centro', colorIdx: 2),
  candidatos: 14,
  sinRankear: 3,
  diasRestantes: 40,
);

final vacanteCerradaEjemplo = VacanteCerrada(
  id: 'v2',
  puesto: 'Cocinero',
  slug: 'cocinero-x',
  cerradaAt: DateTime(2026, 9, 20),
  huboContratacion: true,
  candidatos: 8,
  diasParaArchivar: 18,
);

const fichaVacante = VacanteFicha(
  id: 'v1',
  puesto: 'Mesero',
  estado: 'ACTIVA',
  slug: 'mesero-abc',
  descripcion: 'Atender mesas en turno matutino.',
  ubicacion: 'Reynosa',
  sueldoTexto: r'$2,500',
  turno: 'Matutino',
  sucursal: 'Centro',
  diasParaResponder: 3,
  diasRestantes: 40,
  preguntas: [
    Pregunta(id: 'q1', texto: '¿Tienes licencia?', esRequisito: true),
    Pregunta(id: 'q2', texto: '¿Cuántos años de experiencia?'),
  ],
  conteos: Conteos(
    total: 14,
    rankeados: 11,
    sinRankear: 3,
    cumplenRequisitos: 9,
    pideRequisitos: true,
  ),
);

const rankingEjemplo = Ranking(
  total: 13,
  visibles: [
    FilaRanking(
      postulacionId: 'p1',
      ranking: 1,
      nombre: 'Ana',
      apellidoOculto: true,
      zona: 'Centro',
      score: 87,
      resumen: 'Buena actitud · Vive cerca',
      razones: ['Buena actitud', 'Vive cerca'],
      fase: 'sin_iniciar',
      minutosTraslado: 20,
      requisitosIncumplidos: 1,
      requisitosTotal: 4,
    ),
    FilaRanking(
      postulacionId: 'p2',
      ranking: 2,
      nombre: 'Luis Pérez',
      whatsapp: '5218331234567',
      zona: 'Jarachina',
      score: 81,
      minutosTraslado: 35,
      contactado: true,
      videoSolicitado: true,
      videoRecibido: true,
      testEstado: 'RESPONDIDA',
      testScore: 74,
      documentoSolicitado: true,
      fase: 'en_proceso',
    ),
    FilaRanking(
      postulacionId: 'p3',
      ranking: 3,
      nombre: 'Marta Ruiz',
      whatsapp: '5218339876543',
      score: 78,
      contactado: true,
      contratado: true,
      requisitosTotal: 4,
      fase: 'contratado',
    ),
  ],
  bloqueados: [Bloqueado(postulacionId: 'p12', ranking: 12, score: 41)],
);

const fichaCandidatoContactada = FichaCandidato(
  postulacionId: 'p2',
  nombre: 'Luis Pérez Ruiz',
  contactado: true,
  whatsapp: '5218331234567',
  zona: 'Jarachina',
  minutosTraslado: 35,
  score: 81,
  resumen: 'Experiencia en cocina rápida.',
  experienciaMeses: 14,
  turnoDisponible: 'Matutino',
  sueldoEsperado: r'Hasta $2,750',
  video: Entregable(
    solicitado: true,
    recibido: true,
    url: 'https://x.test/video.mp4',
  ),
  documento: Entregable(
    solicitado: true,
    recibido: true,
    tipo: 'application/pdf',
    url: 'https://x.test/cv.pdf',
  ),
  test: Test(
    estado: 'RESPONDIDA',
    duracion: '6 min',
    resultado: ResultadoTest(
      rasgos: {'Responsabilidad': 70, 'Trabajo en equipo': 82},
      top3: ['Trabajo en equipo', 'Responsabilidad', 'Servicio'],
      arquetipo: ['Colaborador'],
      comentarios: ['Responde con consistencia.'],
      integridad: 'Integridad aceptable',
      integridadTono: 'bajo',
      respuestasMarcadas: 1,
    ),
  ),
  respuestas: [
    Respuesta(texto: '¿Tienes licencia?', respuesta: 'Sí', requisito: true),
    Respuesta(
      texto: '¿Disponibilidad fines de semana?',
      respuesta: 'No',
      requisito: true,
      incumple: true,
    ),
  ],
  extras: [Respuesta(texto: 'Escolaridad', respuesta: 'Preparatoria')],
);

const fichaCandidatoSinContactar = FichaCandidato(
  postulacionId: 'p1',
  nombre: 'Ana P.',
  zona: 'Centro',
  minutosTraslado: 20,
  score: 87,
  resumen: 'Buena actitud, vive cerca.',
  video: Entregable(solicitado: true),
  test: Test(estado: 'ENVIADA'),
);

/// El Inicio COMPLETO (servidor del 6-oct), de una cuenta Pro multisucursal.
const inicioCompleto = Inicio(
  indicadores: Indicadores(
    velocidad: 3.2,
    velocidadDelta: -36,
    cumplenPct: 80,
    cumplenN: 12,
    cumplenTotal: 15,
    cumplenDelta: -4,
    respuestaPct: 49,
    respuestaDelta: -5,
    tiempoDias: 60,
    tiempoDelta: 0,
  ),
  indicadoresPorSucursal: {'s1': Indicadores(velocidad: 2.1, respuestaPct: 40)},
  negocio: NegocioInicio(
    nombre: 'Grupo Yaqui',
    meta: 'Restaurante o bar · Reynosa, Tamaulipas',
  ),
  resumen: ResumenInicio(
    vacantesAbiertas: 15,
    candidatosNuevos: 3,
    ilimitada: true,
    contratacionesMes: 1,
  ),
  sucursales: [
    SucursalInicio(
      id: 's1',
      nombre: 'Yaqui Parrilla Sonorense',
      colorIdx: 0,
      principal: true,
      vacantesActivas: 12,
      gastados: 285,
    ),
    SucursalInicio(
      id: 's2',
      nombre: 'Spexia cuccina italiana',
      colorIdx: 1,
      vacantesActivas: 1,
      gastados: 4,
    ),
  ],
  consumo: ConsumoInicio(),
  pendientes: [
    PendienteInicio(
      id: 'rank-1',
      tipo: 'ranking',
      titulo: 'Supervisor/a · Yaqui Parrilla Sonorense',
      sub: '1 candidato sin ranking',
      slug: 'supervisor',
    ),
    PendienteInicio(
      id: 'vence-2',
      tipo: 'vence',
      titulo: 'Parrillero/a · Yaqui Parrilla Sonorense',
      sub: 'Vence en 5 días · finalízala o deja que cierre sola.',
      slug: 'parrillero',
    ),
  ],
  proceso: ProcesoInicio(
    total: EmbudoInicio(
      postulaciones: 96,
      cumplenRequisitos: 12,
      conRequisitos: 15,
      contactados: 72,
      contratados: 1,
    ),
  ),
  actividad: [
    ActividadInicio(
      postulacionId: 'a1',
      tipo: 'test',
      candidato: 'Keira Jazmín Martínez Herrera',
      accion: 'respondió el test',
      puesto: 'Hostess',
      slug: 'hostess',
      sucursal: 'Yaqui Parrilla Sonorense',
      hace: 'hace 1 día',
    ),
  ],
  vacantes: [
    VacanteResumen(
      id: 'v9',
      puesto: 'Cocinero/a',
      estado: 'ACTIVA',
      slug: 'cocinero',
      ubicacion: 'Las Chaparritas, Reynosa',
      sucursal: SucursalRef(
        id: 's1',
        nombre: 'Yaqui Parrilla Sonorense',
        colorIdx: 0,
      ),
      candidatos: 1,
      sinRankear: 0,
      siguientePaso: 'Revisar candidatos',
    ),
  ],
);

const sucursalesMulti = Sucursales(
  multisucursal: true,
  items: [
    SucursalConVacantes(
      id: 's1',
      nombre: 'Yaqui Parrilla Sonorense',
      colorIdx: 0,
      principal: true,
      vacantesActivas: 1,
      direccion: 'Privada Ninguno 447, Reynosa',
      activas: 1,
      contactosUsados: 285,
      miembros: [Persona(nombre: 'Sofía Treviño', iniciales: 'ST')],
      vacantes: [
        VacanteDeSucursal(
          slug: 'cocinero',
          puesto: 'Cocinero/a',
          estado: 'ACTIVA',
          candidatos: 1,
        ),
      ],
    ),
    SucursalConVacantes(
      id: 's2',
      nombre: 'Altomar',
      colorIdx: 2,
      vacantesActivas: 1,
      direccion: 'Paseo Colinas del Pedregal 134, Reynosa',
      activas: 1,
      sinRanking: 2,
      contactosUsados: 4,
      vacantes: [
        VacanteDeSucursal(
          slug: 'mesero',
          puesto: 'Mesero',
          estado: 'ACTIVA',
          candidatos: 4,
          sinRankear: 2,
        ),
      ],
    ),
  ],
  equipo: [
    Persona(nombre: 'Antonio Pimentel', iniciales: 'AP', rol: 'Dueño'),
    Persona(
      nombre: 'Sofía Treviño',
      iniciales: 'ST',
      rol: 'Miembro',
      sucursales: [
        SucursalDePersona(nombre: 'Yaqui Parrilla Sonorense', colorIdx: 0),
      ],
    ),
  ],
);
