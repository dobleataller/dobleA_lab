
# ==============================================================
# 3_recoding.R
# PROPÓSITO: Preparar los datos para el análisis.
#            Crear nuevas variables derivadas y producir
#            el dataset agregado a nivel empresa.
#
# PRINCIPIO: nunca modificar 'encuesta' (los datos originales).
#            Trabajamos sobre copias para poder volver al origen.
#
# OUTPUTS:
#   encuesta_sub  : datos a nivel respondente (con nuevas variables)
#   empresas_agg  : datos agregados a nivel empresa (para PCA y clustering)
# ==============================================================


# ---- Copia de trabajo ---------------------------------------
# Nunca modificar el objeto original ('encuesta').
# Si algo sale mal en la recodificación, encuesta sigue intacto.

encuesta_sub <- encuesta


# ---- Categoría NPS ------------------------------------------
# Regla estándar de la metodología NPS (Reichheld, 2003):
#   Promotores  (9–10): clientes leales que recomiendan activamente
#   Pasivos     (7–8) : satisfechos pero no entusiastas
#   Detractores (0–6) : insatisfechos, pueden generar boca-a-boca negativo
#
# La métrica clave es el NPS Neto = %Promotores − %Detractores
# (rango posible: −100 a +100)

encuesta_sub <- encuesta_sub %>%
  mutate(
    nps_categoria = case_when(
      nps_score >= 9               ~ "Promotor",
      nps_score >= 7               ~ "Pasivo",
      nps_score < 7                ~ "Detractor",
      TRUE                         ~ NA_character_   # por si hay NA
    ),
    # Factor ordenado: permite comparaciones ordinales y gráficos correctos
    nps_categoria = factor(
      nps_categoria,
      levels  = c("Detractor", "Pasivo", "Promotor"),
      ordered = TRUE
    )
  )


# ---- Segmento como factor ordenado -------------------------
# Convertir a factor con orden lógico (tamaño creciente).
# Esto asegura que en gráficos aparezca Pyme < Mediana < Grande.

encuesta_sub <- encuesta_sub %>%
  mutate(
    segmento = factor(
      segmento,
      levels  = c("Pyme", "Mediana", "Grande"),
      ordered = TRUE
    )
  )


# ---- Índice de satisfacción compuesto -----------------------
# Promedio simple de las 5 dimensiones de satisfacción (escala 1–5).
# rowMeans() calcula el promedio fila a fila de varias columnas.
# En un proyecto real, podría usarse un promedio ponderado según
# la importancia declarada por el cliente en el brief.

encuesta_sub <- encuesta_sub %>%
  mutate(
    indice_sat = rowMeans(
      select(., sat_producto, sat_servicio, sat_precio,
             sat_soporte, sat_entrega),
      na.rm = TRUE
    )
  )


# ---- Agregación a nivel empresa ----------------------------
# Para PCA y clustering necesitamos UNA fila por empresa.
# Colapsamos los respondentes usando promedios.
# group_by() + summarise() es el equivalente de tabla dinámica en Excel.

empresas_agg <- encuesta_sub %>%
  group_by(empresa_id, region, segmento, antiguedad_cliente) %>%
  summarise(
    # NPS neto: métrica principal del cliente
    # mean(...) da la proporción; ×100 convierte a porcentaje
    pct_promotores  = mean(nps_categoria == "Promotor",  na.rm = TRUE) * 100,
    pct_pasivos     = mean(nps_categoria == "Pasivo",    na.rm = TRUE) * 100,
    pct_detractores = mean(nps_categoria == "Detractor", na.rm = TRUE) * 100,
    nps_neto        = pct_promotores - pct_detractores,

    # Promedios de cada dimensión de satisfacción
    # across() aplica la misma función a múltiples columnas a la vez
    across(starts_with("sat_"), ~ mean(.x, na.rm = TRUE)),

    # Índice de satisfacción compuesto (promedio de dimensiones)
    indice_sat_prom = mean(indice_sat, na.rm = TRUE),

    # Cuántos respondentes tiene esta empresa (tamaño de muestra)
    n_respondentes  = n(),

    .groups = "drop"   # elimina el agrupamiento al terminar
  )


# ---- Verificación -------------------------------------------
cat("================ RECODIFICACIÓN LISTA !!!! ====================\n")
cat("  encuesta_sub : ", nrow(encuesta_sub), "filas (nivel respondente)\n")
cat("  empresas_agg :", nrow(empresas_agg), "filas (nivel empresa)\n")
cat("  Distribución NPS:\n")
encuesta_sub %>% count(nps_categoria) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>% print()
cat("\n")
