
# ==============================================================
# 0_simulate_data.R
# PROPÓSITO: Generar datos sintéticos de encuesta NPS que
#            simulan un proyecto real de consultoría.
#
# ESCENARIO: Un cliente nos encargó medir la satisfacción de sus
#            150 empresas-cliente distribuidas en 6 regiones.
#            Entre 15 y 25 contactos por empresa respondieron
#            una encuesta de satisfacción + la pregunta NPS.
#
# NOTA: En un proyecto real, este script se reemplaza por la
#       carga directa del archivo enviado por el cliente.
#       Aquí simulamos para que el workflow sea auto-contenido.
#
# VARIABLES GENERADAS:
#   id_respuesta      : ID único por respuesta
#   empresa_id        : código empresa (EMP001 – EMP150)
#   region            : región geográfica (6 categorías)
#   segmento          : tamaño de empresa (Pyme / Mediana / Grande)
#   antiguedad_cliente: años como cliente (1–10)
#   n_compras         : compras en el último año
#   nps_score         : pregunta NPS cruda (0–10)
#   sat_producto      : satisfacción con el producto (1–5)
#   sat_servicio      : satisfacción con el servicio (1–5)
#   sat_precio        : satisfacción precio/valor (1–5)
#   sat_soporte       : satisfacción con soporte técnico (1–5)
#   sat_entrega       : satisfacción con tiempos de entrega (1–5)
# ==============================================================

set.seed(42)   # semilla para reproducibilidad exacta de los datos

# ---- Parámetros del diseño ----------------------------------

n_empresas <- 150

regiones   <- c("Norte", "Sur", "Centro", "Oriente",
                "Occidente", "Metropolitana")

segmentos  <- c("Pyme", "Mediana", "Grande")

# Cada región tiene un "efecto base" diferente sobre la satisfacción
# (escala 0–10). Metropolitana = mayor satisfacción; Oriente = menor.
# Esto simula diferencias reales de desempeño por zona geográfica.
region_baseline <- c(
  Norte         = 5.8,
  Sur           = 6.3,
  Centro        = 6.8,
  Oriente       = 5.5,
  Occidente     = 6.5,
  Metropolitana = 7.2
)

# ---- Crear datos a nivel empresa ----------------------------

empresas_df <- tibble(
  empresa_id = sprintf("EMP%03d", 1:n_empresas),

  # Distribución no uniforme: más empresas en Metropolitana y Centro,
  # menos en Norte y Sur (refleja densidad empresarial realista)
  region = sample(
    regiones, n_empresas, replace = TRUE,
    prob = c(0.10, 0.10, 0.20, 0.15, 0.15, 0.30)
  ),

  # Mix de segmentos: la mayoría son PYME (refleja mercado real)
  segmento = sample(
    segmentos, n_empresas, replace = TRUE,
    prob = c(0.50, 0.35, 0.15)
  ),

  # Antigüedad como cliente: entre 1 y 10 años (distribución uniforme)
  antiguedad = sample(1:10, n_empresas, replace = TRUE),

  # Número de respondentes por empresa (varía naturalmente)
  n_resp = sample(15:25, n_empresas, replace = TRUE)
)

# ---- Expandir a nivel respondente ---------------------------
# rowwise() + reframe(): para cada fila-empresa, genera n_resp filas
# (una por contacto que respondió la encuesta dentro de esa empresa)
# Es el equivalente a hacer un "expand" o "uncount" personalizado.

encuesta_raw <- empresas_df %>%
  rowwise() %>%
  reframe(
    empresa_id         = empresa_id,
    region             = region,
    segmento           = segmento,
    antiguedad_cliente = antiguedad,
    resp_n             = seq_len(n_resp)   # respondente 1, 2, …, n
  ) %>%
  ungroup() %>%
  mutate(
    id_respuesta = row_number(),

    # Recuperar el efecto base de la región para cada fila
    base = region_baseline[region],

    # ---- NPS score (pregunta: "¿cuán probable es que nos recomiendes?" 0–10)
    # Modelado como una variable latente continua + redondeo al entero.
    # rnorm(n(), 0, 2) = ruido individual alrededor del promedio regional.
    # pmax/pmin fuerzan los límites del rango válido (0–10).
    nps_score = pmax(0L, pmin(10L,
                  as.integer(round(base + rnorm(n(), 0, 2.0))))),

    # ---- Dimensiones de satisfacción (escala Likert 1–5) ----------------
    # Positivamente correlacionadas con nps_score y entre sí,
    # pero con varianza propia (no son meras transformaciones del NPS).
    # base/2.5 ≈ transforma escala 0–10 a ~1–5 centrado.
    sat_producto = pmax(1L, pmin(5L,
                    as.integer(round(base / 2.5 + rnorm(n(),  0.0, 0.8))))),
    sat_servicio = pmax(1L, pmin(5L,
                    as.integer(round(base / 2.5 + rnorm(n(), -0.2, 0.9))))),
    sat_precio   = pmax(1L, pmin(5L,
                    as.integer(round(base / 2.8 + rnorm(n(),  0.0, 0.8))))),
    sat_soporte  = pmax(1L, pmin(5L,
                    as.integer(round(base / 2.5 + rnorm(n(),  0.1, 0.9))))),
    sat_entrega  = pmax(1L, pmin(5L,
                    as.integer(round(base / 2.4 + rnorm(n(),  0.0, 0.8))))),

    # ---- Número de compras en el último año (correlacionado con antigüedad)
    n_compras = pmax(1L, as.integer(
                  round(4 + antiguedad_cliente * 0.5 + rnorm(n(), 0, 2))))
  ) %>%
  # Eliminar columnas auxiliares y ordenar
  select(id_respuesta, empresa_id, region, segmento,
         antiguedad_cliente, n_compras, nps_score,
         sat_producto, sat_servicio, sat_precio, sat_soporte, sat_entrega)

# ---- Guardar datos ------------------------------------------
# CSV es el formato más portable: lo abre cualquier software
# En proyectos reales, guardar en data/raw/ (sin modificar el original)

write_csv(encuesta_raw, paste0(dirdata, "nps_consultoria.csv"))

cat("================ DATOS SIMULADOS Y GUARDADOS ====================\n")
cat("  Filas:    ", nrow(encuesta_raw), "\n")
cat("  Columnas: ", ncol(encuesta_raw), "\n")
cat("  Empresas: ", n_distinct(encuesta_raw$empresa_id), "\n")
cat("  Regiones: ", paste(sort(unique(encuesta_raw$region)), collapse = ", "), "\n\n")
