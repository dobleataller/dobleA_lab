
# ==============================================================
# 2_exploration.R
# PROPÓSITO: Primer vistazo sistemático a los datos antes de
#            cualquier análisis. Detectar problemas temprano.
#
# REGLA: este script solo IMPRIME en consola, no guarda archivos.
#        La exploración es para el analista, no para el cliente.
#
# QUÉ VERIFICAR SIEMPRE:
#   1. Estructura del dataset (tipos de variables, N)
#   2. Valores faltantes (NA)
#   3. Distribución de la variable clave (NPS)
#   4. Balance de la muestra (¿hay regiones sub-representadas?)
#   5. Correlaciones entre variables (¿hay multicolinealidad?)
# ==============================================================


# ---- 1. Estructura general ----------------------------------
# glimpse() muestra tipo de cada columna y primeros valores
# Es más legible que str() y más informativo que head()

cat("\n--- Estructura del dataset ---\n")
glimpse(encuesta)


# ---- 2. Resumen estadístico ---------------------------------
# summary() da mínimo, cuartiles, media, máximo y count de NAs

cat("\n--- Resumen estadístico ---\n")
summary(encuesta)


# ---- 3. Valores faltantes -----------------------------------
# Fundamental: saber si hay NAs antes de calcular medias o modelos
# colSums(is.na(.)) cuenta NAs por columna

cat("\n--- Valores faltantes por variable ---\n")
encuesta %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(),
               names_to  = "variable",
               values_to = "n_NA") %>%
  filter(n_NA > 0) %>%   # mostrar solo columnas con algún NA
  print()
cat("(si no aparece nada, no hay NAs en los datos)\n")


# ---- 4. Distribución del NPS --------------------------------
# Tabla de frecuencias: ¿cómo se distribuye el score 0–10?
# Importante detectar si hay acumulación anormal en algún valor

cat("\n--- Distribución del NPS score (0–10) ---\n")
encuesta %>%
  count(nps_score) %>%
  mutate(
    pct       = round(n / sum(n) * 100, 1),
    categoria = case_when(
      nps_score <= 6 ~ "Detractor",
      nps_score <= 8 ~ "Pasivo",
      TRUE           ~ "Promotor"
    )
  ) %>%
  print(n = 11)   # mostrar las 11 filas (0 a 10)


# ---- 5. Balance de la muestra: región × segmento -----------
# ¿Hay grupos con muy pocas observaciones?
# Si una celda tiene N < 30, interpretar sus resultados con cuidado.

cat("\n--- Número de respondentes por región y segmento ---\n")
encuesta %>%
  count(region, segmento) %>%
  pivot_wider(names_from = segmento, values_from = n, values_fill = 0) %>%
  knitr::kable(format = "simple")


# ---- 6. Número de empresas por región -----------------------
cat("\n--- Empresas por región ---\n")
encuesta %>%
  distinct(empresa_id, region) %>%   # a nivel empresa (no respondente)
  count(region, name = "n_empresas") %>%
  arrange(desc(n_empresas)) %>%
  print()


# ---- 7. Correlación entre dimensiones de satisfacción ------
# Si las dimensiones están muy correlacionadas (r > 0.8),
# puede haber multicolinealidad en los modelos de regresión.
# También confirma que las variables miden constructos distintos.

cat("\n--- Correlaciones entre dimensiones de satisfacción ---\n")
encuesta %>%
  select(starts_with("sat_")) %>%
  cor(use = "pairwise.complete.obs") %>%
  round(2) %>%
  knitr::kable(format = "simple")


cat("\n================ EXPLORACIÓN LISTA !!!! ====================\n\n")
