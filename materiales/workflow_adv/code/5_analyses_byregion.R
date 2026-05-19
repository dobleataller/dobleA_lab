
# ==============================================================
# 5_analyses_byregion.R
# PROPÓSITO: Análisis específico para la región 'r'.
#
# CÓMO SE USA: este script NO se corre directamente.
#   Es llamado desde el loop de 1_masterfile.R para cada región.
#   Cuando se ejecuta, las siguientes variables ya existen:
#     r               → nombre de la región (string, ej. "Norte")
#     encuesta_region → datos filtrados para esa región
#     empresas_agg    → datos de empresas (todas las regiones)
#     dirresults      → ruta de la carpeta de resultados
#
# OUTPUTS: archivos con sufijo "_[región]" en results/
#   tabla_desc_[r].txt   → descriptivos NPS por segmento
#   tabla_reg_[r].txt    → tabla de regresión
#   fig_hist_[r].pdf     → histograma del NPS
#   fig_top_bottom_[r].pdf → empresas con mayor/menor NPS
# ==============================================================


# ---- A. Descriptivos de la región ---------------------------
# NPS neto desagregado por segmento dentro de la región.
# Este análisis responde: ¿hay diferencias por tamaño de empresa?

nps_seg <- encuesta_region %>%
  group_by(segmento) %>%
  summarise(
    n_resp          = n(),
    pct_promotores  = round(mean(nps_categoria == "Promotor")  * 100, 1),
    pct_pasivos     = round(mean(nps_categoria == "Pasivo")    * 100, 1),
    pct_detractores = round(mean(nps_categoria == "Detractor") * 100, 1),
    nps_neto        = round(pct_promotores - pct_detractores, 1),
    indice_sat      = round(mean(indice_sat, na.rm = TRUE), 2),
    .groups         = "drop"
  )

filename <- paste0(dirresults, "tabla_desc_", r, ".txt")
nps_seg %>%
  as.data.frame() %>%
  stargazer(
    type     = "text",
    summary  = FALSE,
    rownames = FALSE,
    title    = paste("NPS por Segmento -", r),
    out      = filename
  )


# ---- B. Top 5 y Bottom 5 empresas de la región -------------
# En consultora, este análisis es muy valorado:
#   Top 5    → casos de éxito, posibles embajadores de marca
#   Bottom 5 → prioridades de intervención inmediata ("quick wins")

empresas_reg <- empresas_agg %>% filter(region == r)

top5 <- empresas_reg %>%
  slice_max(nps_neto, n = 5) %>%
  select(empresa_id, segmento, nps_neto, indice_sat_prom, n_respondentes)

bottom5 <- empresas_reg %>%
  slice_min(nps_neto, n = 5) %>%
  select(empresa_id, segmento, nps_neto, indice_sat_prom, n_respondentes)

cat("\n  Top 5 NPS en", r, ":\n"); print(top5)
cat("\n  Bottom 5 NPS en", r, ":\n"); print(bottom5)

# Gráfico dumbbell: muestra el rango NPS de la región
# destacando las 5 mejores y 5 peores empresas
fig_top_bottom <- bind_rows(
  top5    %>% mutate(grupo = "Top 5"),
  bottom5 %>% mutate(grupo = "Bottom 5")
) %>%
  ggplot(aes(
    x     = nps_neto,
    y     = reorder(empresa_id, nps_neto),
    color = grupo,
    shape = as.character(segmento)   # as.character() evita warning de factor ordenado
  )) +
  geom_point(size = 4) +
  geom_vline(
    xintercept = mean(empresas_reg$nps_neto),
    linetype   = "dashed", color = "gray50"
  ) +
  annotate(
    "text", x = mean(empresas_reg$nps_neto),
    y = 0.4, label = "Media\nregión",
    size = 2.8, color = "gray50", hjust = -0.1
  ) +
  scale_color_manual(values = c("Top 5" = "#1a9850", "Bottom 5" = "#d73027")) +
  labs(
    title    = paste0("Top y Bottom 5 - Region ", r),
    subtitle = "Cada punto = empresa | Línea = media regional",
    x        = "NPS Neto (%)",
    y        = NULL,
    color    = NULL,
    shape    = "Segmento"
  ) +
  theme_minimal(base_size = 10)

filename <- paste0(dirresults, "fig_top_bottom_", r, ".pdf")
ggsave(filename, fig_top_bottom, width = 14, height = 10, units = "cm")


# ---- C. Histograma NPS con cortes Promotor/Pasivo/Detractor
# Muestra la distribución completa con las zonas coloreadas.
# Permite ver si la región tiene distribución bimodal (señal de alerta).

fig_hist <- encuesta_region %>%
  ggplot(aes(x = nps_score, fill = nps_categoria)) +
  geom_histogram(binwidth = 1, color = "white", center = 0.5) +
  # Líneas verticales en los umbrales 6.5 (Detractor/Pasivo) y 8.5 (Pasivo/Promotor)
  geom_vline(xintercept = c(6.5, 8.5), linetype = "dashed", color = "gray30") +
  annotate("text", x = 3.0, y = Inf, label = "Detractores",
           vjust = 2, size = 2.8, color = "gray30") +
  annotate("text", x = 7.5, y = Inf, label = "Pasivos",
           vjust = 2, size = 2.8, color = "gray30") +
  annotate("text", x = 9.5, y = Inf, label = "Promotores",
           vjust = 2, size = 2.8, color = "gray30") +
  scale_fill_manual(values = c(
    "Detractor" = "#d73027",
    "Pasivo"    = "#fee08b",
    "Promotor"  = "#1a9850"
  )) +
  scale_x_continuous(breaks = 0:10) +
  labs(
    title    = paste0("Distribución NPS - Región ", r),
    subtitle = paste0("N = ", nrow(encuesta_region), " respondentes"),
    x        = "NPS Score (0-10)",
    y        = "Frecuencia",
    fill     = "Categoría NPS"
  ) +
  theme_minimal(base_size = 11)

filename <- paste0(dirresults, "fig_hist_", r, ".pdf")
ggsave(filename, fig_hist, width = 14, height = 10, units = "cm")


# ---- D. Regresión OLS por región ----------------------------
# Modelo separado para cada región.
# Permite detectar si los "drivers" del NPS difieren por zona:
# En una región puede importar más el precio; en otra, el servicio.
# Esta heterogeneidad regional es muy valiosa para el cliente.

model_reg <- lm(
  nps_neto ~ sat_producto + sat_servicio + sat_precio + sat_soporte + sat_entrega,
  data = empresas_reg
)

filename <- paste0(dirresults, "tabla_reg_", r, ".txt")
stargazer(
  model_reg,
  type             = "text",
  out              = filename,
  title            = paste("Regresión NPS Neto -", r),
  covariate.labels = c("Producto", "Servicio", "Precio/Valor",
                       "Soporte", "Entrega"),
  dep.var.labels   = "NPS Neto (%)"
)


cat("================ ANÁLISIS REGIÓN:", r, "LISTO !!!! ====================\n")
