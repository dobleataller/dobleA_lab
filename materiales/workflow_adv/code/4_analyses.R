
# ==============================================================
# 4_analyses.R
# PROPÓSITO: Análisis globales sobre toda la muestra.
#
# CONTENIDO:
#   Sección 1 – Estadísticas descriptivas (tablas)
#   Sección 2 – Visualizaciones (5 tipos de gráficos distintos)
#   Sección 3 – Análisis de Componentes Principales (PCA)
#   Sección 4 – Clustering K-means de empresas
#   Sección 5 – Modelos de regresión OLS
#
# OUTPUTS: tablas (.txt / .tex) y figuras (.pdf) en results/
# ==============================================================


# ==============================================================
# SECCIÓN 1: ESTADÍSTICAS DESCRIPTIVAS
# ==============================================================

# ---- 1.1 NPS neto por región --------------------------------
# NPS Neto = %Promotores − %Detractores  (rango: −100 a +100)
# Es la métrica estándar que el cliente espera ver primero.

nps_por_region <- encuesta_sub %>%
  group_by(region) %>%
  summarise(
    n_respuestas    = n(),
    pct_promotores  = round(mean(nps_categoria == "Promotor")  * 100, 1),
    pct_pasivos     = round(mean(nps_categoria == "Pasivo")    * 100, 1),
    pct_detractores = round(mean(nps_categoria == "Detractor") * 100, 1),
    nps_neto        = round(pct_promotores - pct_detractores, 1),
    .groups         = "drop"
  ) %>%
  arrange(desc(nps_neto))

filename <- paste0(dirresults, "tabla_nps_region.txt")
nps_por_region %>%
  as.data.frame() %>%
  stargazer(type = "text", summary = FALSE, rownames = FALSE, out = filename)


# ---- 1.2 Satisfacción media por región ----------------------
# Exportar en formato LaTeX para incluir en reportes formales

filename <- paste0(dirresults, "tabla_sat_region.tex")
encuesta_sub %>%
  group_by(region) %>%
  summarise(
    across(
      starts_with("sat_"),
      list(
        media = ~ round(mean(.x, na.rm = TRUE), 2),
        sd    = ~ round(sd(.x,   na.rm = TRUE), 2)
      ),
      .names = "{.col}_{.fn}"
    ),
    .groups = "drop"
  ) %>%
  xtable(
    caption = "Satisfacción media (DE) por región y dimensión",
    digits  = 2
  ) %>%
  print(file = filename, include.rownames = FALSE)


# ==============================================================
# SECCIÓN 2: VISUALIZACIONES
# ==============================================================
# Se muestran 5 tipos de gráfico distintos, apropiados para
# diferentes preguntas analíticas y diferentes audiencias.


# ---- 2.1 BARRAS HORIZONTALES: NPS neto por región -----------
# Cuándo usar: comparar una métrica entre grupos ordenables.
# Coloreado en gradiente rojo–verde (divergente desde 0).
# El geom_text() agrega el valor exacto dentro/fuera de cada barra.

fig_nps_region <- nps_por_region %>%
  ggplot(aes(
    x    = nps_neto,
    y    = reorder(region, nps_neto),   # ordenar de mayor a menor
    fill = nps_neto
  )) +
  geom_col() +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
  geom_text(
    aes(label = paste0(nps_neto, "%")),
    hjust = ifelse(nps_por_region$nps_neto >= 0, -0.15, 1.15),
    size  = 3.5
  ) +
  # Escala divergente: rojo negativo, amarillo neutro, verde positivo
  scale_fill_gradient2(
    low      = "#d73027",
    mid      = "#fee08b",
    high     = "#1a9850",
    midpoint = 0
  ) +
  labs(
    title    = "NPS Neto por Región",
    subtitle = "% Promotores – % Detractores  |  rango: –100 a +100",
    x        = "NPS Neto (%)",
    y        = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

filename <- paste0(dirresults, "fig_nps_region.pdf")
ggsave(filename, fig_nps_region, width = 16, height = 10, units = "cm")


# ---- 2.2 BOXPLOT AGRUPADO: NPS por región y segmento -------
# Cuándo usar: mostrar distribución completa (mediana, IQR, outliers)
# comparando simultáneamente dos variables categóricas.
# Pregunta: ¿las PYME tienen NPS distinto que las empresas grandes?

fig_boxplot <- encuesta_sub %>%
  ggplot(aes(x = region, y = nps_score, fill = segmento)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.7, outlier.alpha = 0.5) +
  scale_fill_viridis(discrete = TRUE, option = "viridis") +
  labs(
    title    = "Distribución del NPS por Región y Segmento",
    subtitle = "Caja = IQR (P25–P75) | Línea = mediana | Puntos = outliers",
    x        = "Región",
    y        = "NPS Score (0–10)",
    fill     = "Segmento"
  ) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

filename <- paste0(dirresults, "fig_boxplot.pdf")
ggsave(filename, fig_boxplot, width = 18, height = 12, units = "cm")


# ---- 2.3 RIDGE PLOT: densidad de NPS por región ------------
# Cuándo usar: mostrar la forma completa de la distribución
# para varios grupos, especialmente cuando es bimodal o asimétrica.
# Más informativo que el boxplot para distribuciones irregulares.
# geom_density_ridges_gradient: rellena con gradiente de color.

fig_ridge <- encuesta_sub %>%
  ggplot(aes(
    x    = nps_score,
    y    = reorder(region, nps_score, FUN = median),   # orden por mediana
    fill = after_stat(x)   # color del relleno = valor del eje x
  )) +
  geom_density_ridges_gradient(
    scale          = 2,           # cuánto se solapan las curvas
    rel_min_height = 0.01,        # cortar colas muy pequeñas
    quantile_lines = TRUE,        # línea vertical en la mediana
    quantiles      = 2            # solo la mediana (divide en 2)
  ) +
  scale_fill_viridis(option = "plasma", name = "NPS") +
  scale_x_continuous(breaks = 0:10) +
  labs(
    title    = "Distribución del NPS Score por Región",
    subtitle = "Densidad de Kernel | Línea vertical = mediana",
    x        = "NPS Score (0–10)",
    y        = NULL
  ) +
  theme_ridges(grid = FALSE, center_axis_labels = TRUE)

filename <- paste0(dirresults, "fig_ridge.pdf")
ggsave(filename, fig_ridge, width = 16, height = 14, units = "cm")


# ---- 2.4 HEATMAP: satisfacción media por región × dimensión
# Cuándo usar: comparar muchas variables para muchos grupos a la vez.
# Permite detectar patrones de fortaleza/debilidad cruzados.
# Pregunta: ¿en qué dimensión falla cada región?

sat_long <- encuesta_sub %>%
  group_by(region) %>%
  summarise(across(starts_with("sat_"), ~ mean(.x, na.rm = TRUE)),
            .groups = "drop") %>%
  pivot_longer(
    cols      = starts_with("sat_"),
    names_to  = "dimension",
    values_to = "media"
  ) %>%
  # Reemplazar nombres técnicos por etiquetas descriptivas
  mutate(dimension = recode(dimension,
    "sat_producto" = "Producto",
    "sat_servicio" = "Servicio",
    "sat_precio"   = "Precio/Valor",
    "sat_soporte"  = "Soporte",
    "sat_entrega"  = "Entrega"
  ))

fig_heatmap <- sat_long %>%
  ggplot(aes(
    x    = dimension,
    y    = reorder(region, media),   # regiones ordenadas por satisfacción global
    fill = media
  )) +
  geom_tile(color = "white", linewidth = 0.6) +
  geom_text(aes(label = round(media, 2)), size = 3.2, color = "white",
            fontface = "bold") +
  scale_fill_viridis(
    option = "magma",
    limits = c(1, 5),
    name   = "Media\n(1–5)"
  ) +
  labs(
    title    = "Satisfacción Media por Región y Dimensión",
    subtitle = "Escala 1–5 | Colores más claros = mayor satisfacción",
    x        = "Dimensión de Satisfacción",
    y        = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

filename <- paste0(dirresults, "fig_heatmap.pdf")
ggsave(filename, fig_heatmap, width = 16, height = 12, units = "cm")


# ---- 2.5 SCATTER CON SMOOTH: antigüedad del cliente vs NPS neto
# Cuándo usar: explorar la relación entre dos variables continuas.
# Pregunta: ¿los clientes más antiguos tienen mayor NPS?
# geom_smooth(method="lm") agrega línea de regresión con IC 95%.

fig_scatter <- empresas_agg %>%
  ggplot(aes(
    x     = antiguedad_cliente,
    y     = nps_neto,
    color = region,
    size  = n_respondentes   # tamaño del punto proporcional al N de la empresa
  )) +
  geom_jitter(alpha = 0.6, width = 0.15) +
  geom_smooth(
    aes(group = 1),   # group=1: una sola línea de tendencia global
    method   = "lm",
    se       = TRUE,   # banda de error estándar al 95%
    color    = "black",
    linewidth = 0.9,
    alpha    = 0.2
  ) +
  scale_color_viridis(discrete = TRUE, option = "turbo") +
  scale_size_continuous(range = c(1.5, 5)) +
  labs(
    title    = "Antigüedad del Cliente vs. NPS Neto",
    subtitle = "Cada punto = una empresa | Tamaño = N respondentes",
    x        = "Antigüedad como cliente (años)",
    y        = "NPS Neto (%)",
    color    = "Región",
    size     = "N resp."
  ) +
  theme_minimal(base_size = 11)

filename <- paste0(dirresults, "fig_scatter.pdf")
ggsave(filename, fig_scatter, width = 18, height = 12, units = "cm")


# ==============================================================
# SECCIÓN 3: ANÁLISIS DE COMPONENTES PRINCIPALES (PCA)
# ==============================================================
# CUÁNDO USAR PCA:
#   Cuando tienes muchas variables correlacionadas y quieres
#   reducirlas a unos pocos "factores latentes" que capturan
#   la mayor parte de la variación.
#
# INTERPRETACIÓN:
#   PC1 = la dimensión que más varianza explica en los datos.
#   Las "cargas" (loadings) indican cuánto contribuye cada
#   variable original a cada componente.
#
# SUPUESTO CLAVE: las variables deben estar correlacionadas.
#   Si no lo están, PCA no aporta información nueva.


# ---- 3.1 Matriz de correlación visual ----------------------
# Antes del PCA, verificar visualmente que las dimensiones
# de satisfacción están correlacionadas entre sí.

cor_matrix <- encuesta_sub %>%
  select(starts_with("sat_")) %>%
  cor(use = "pairwise.complete.obs")

fig_corr <- ggcorrplot(
  cor_matrix,
  method   = "circle",   # círculos (tamaño = correlación)
  type     = "lower",    # solo triángulo inferior (evita redundancia)
  lab      = TRUE,       # mostrar valores numéricos
  lab_size = 3.5,
  colors   = c("#d73027", "white", "#1a9850"),
  title    = "Correlación entre Dimensiones de Satisfacción"
)

filename <- paste0(dirresults, "fig_correlacion.pdf")
ggsave(filename, fig_corr, width = 14, height = 12, units = "cm")


# ---- 3.2 Calcular PCA ---------------------------------------
# prcomp() es la función estándar para PCA en R.
# scale = TRUE: estandariza variables a media=0, sd=1 antes del PCA.
# SIEMPRE escalar cuando las variables tienen diferentes rangos/unidades.

sat_matrix <- encuesta_sub %>%
  select(starts_with("sat_")) %>%
  drop_na()   # PCA requiere datos sin NA

pca_result <- prcomp(sat_matrix, scale = TRUE, center = TRUE)

cat("\n--- PCA: Varianza explicada por componente ---\n")
summary(pca_result)

# Cargas de cada variable en los primeros 3 componentes
cat("\n--- PCA Loadings (primeros 3 componentes) ---\n")
pca_result$rotation[, 1:3] %>% round(3) %>% print()


# ---- 3.3 Scree plot (gráfico de codo) ----------------------
# Muestra qué % de varianza explica cada componente.
# La "rodilla" del gráfico sugiere cuántos componentes retener.
# Regla Kaiser: retener PCs con varianza > 1 (en datos estandarizados).
#
# Implementación manual con ggplot2 (más robusta que fviz_eig,
# que tiene problemas de compatibilidad con versiones recientes
# de ggplot2 a través de ggpar()).
#
# pca_result$sdev son las desviaciones estándar de cada PC.
# La varianza de cada PC = sdev^2.
# La proporción explicada = sdev^2 / sum(sdev^2).

var_pct     <- pca_result$sdev^2 / sum(pca_result$sdev^2) * 100
var_acum    <- cumsum(var_pct)
n_pcs       <- length(var_pct)

scree_data <- tibble(
  pc        = factor(paste0("PC", seq_len(n_pcs)), levels = paste0("PC", seq_len(n_pcs))),
  varianza  = var_pct,
  acumulada = var_acum
)

fig_scree <- scree_data %>%
  ggplot(aes(x = pc, y = varianza)) +
  geom_col(aes(fill = pc), color = "white", show.legend = FALSE) +
  # Línea de varianza acumulada (eje secundario visual, no real)
  geom_line(aes(y = acumulada, group = 1),
            color = "#d73027", linewidth = 0.9) +
  geom_point(aes(y = acumulada),
             color = "#d73027", size = 2.5) +
  # Etiquetas con % en cada barra
  geom_text(aes(label = paste0(round(varianza, 1), "%")),
            vjust = -0.4, size = 3.2) +
  scale_fill_viridis(discrete = TRUE) +
  scale_y_continuous(limits = c(0, 105)) +
  labs(
    title    = "PCA – Varianza Explicada por Componente",
    subtitle = "Barras = % individual | Línea roja = % acumulado",
    x        = "Componente Principal",
    y        = "% de Varianza Explicada"
  ) +
  theme_minimal(base_size = 11)

filename <- paste0(dirresults, "fig_pca_scree.pdf")
ggsave(filename, fig_scree, width = 14, height = 10, units = "cm")


# ---- 3.4 Biplot PCA -----------------------------------------
# Muestra observaciones (puntos) y variables (flechas) juntos
# en el espacio de los dos primeros componentes principales.
# Flechas en la misma dirección → variables correlacionadas.
# Flechas opuestas → correlación negativa.
# Un punto en la dirección de una flecha → alto valor en esa variable.
#
# Implementación manual: extrae scores (coordenadas de los
# individuos) y loadings (coordenadas de las variables) desde
# el objeto prcomp y los grafica con ggplot2.

# Scores: coordenadas de cada observación en el espacio PCA
scores_df <- as.data.frame(pca_result$x[, 1:2]) %>%
  rename(PC1 = 1, PC2 = 2)

# Loadings: dirección y peso de cada variable original
loadings_df <- as.data.frame(pca_result$rotation[, 1:2]) %>%
  rename(PC1 = 1, PC2 = 2) %>%
  rownames_to_column("variable") %>%
  mutate(variable = recode(variable,
    "sat_producto" = "Producto",
    "sat_servicio" = "Servicio",
    "sat_precio"   = "Precio/Valor",
    "sat_soporte"  = "Soporte",
    "sat_entrega"  = "Entrega"
  ))

# Factor de escala para que las flechas sean visibles
# junto a los puntos (que tienen otra escala)
escala <- max(abs(scores_df)) / max(abs(loadings_df[, 2:3])) * 0.65

fig_biplot <- ggplot() +
  # Puntos (individuos / respondentes)
  geom_point(data = scores_df,
             aes(x = PC1, y = PC2),
             alpha = 0.25, color = "steelblue", size = 0.9) +
  # Flechas (variables originales)
  geom_segment(data = loadings_df,
               aes(x = 0, y = 0,
                   xend = PC1 * escala,
                   yend = PC2 * escala),
               arrow     = arrow(length = unit(0.25, "cm"), type = "closed"),
               color     = "#d73027",
               linewidth = 0.8) +
  # Etiquetas de las variables (desplazadas 15% más allá de la punta)
  geom_text(data = loadings_df,
            aes(x = PC1 * escala * 1.15,
                y = PC2 * escala * 1.15,
                label = variable),
            color = "#d73027", size = 3.5, fontface = "bold") +
  # Ejes cruzados en el origen
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray70") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray70") +
  labs(
    title    = "Biplot PCA – Dimensiones de Satisfacción",
    subtitle = paste0("PC1 = ", round(var_pct[1], 1), "% | ",
                      "PC2 = ", round(var_pct[2], 1), "% de varianza"),
    x        = paste0("PC1 (", round(var_pct[1], 1), "%)"),
    y        = paste0("PC2 (", round(var_pct[2], 1), "%)")
  ) +
  theme_minimal(base_size = 11)

filename <- paste0(dirresults, "fig_pca_biplot.pdf")
ggsave(filename, fig_biplot, width = 16, height = 14, units = "cm")


# ==============================================================
# SECCIÓN 4: CLUSTERING K-MEANS DE EMPRESAS
# ==============================================================
# CUÁNDO USAR CLUSTERING:
#   Cuando quieres identificar "tipos" de clientes sin haberlos
#   definido a priori. El algoritmo agrupa empresas similares.
#
# UTILIDAD EN CONSULTORA:
#   Los clusters permiten personalizar acciones:
#   Cluster A (alto NPS) → programa de embajadores
#   Cluster B (bajo servicio) → plan de mejora en soporte
#   Cluster C (bajo precio) → revisar política comercial
#
# K-MEANS EN PALABRAS:
#   1. Elegir K centros aleatoriamente
#   2. Asignar cada punto al centro más cercano
#   3. Recalcular centros como promedio de los puntos asignados
#   4. Repetir 2-3 hasta que los centros no cambien


# ---- 4.1 Preparar matriz para clustering -------------------
# Usamos datos a nivel empresa (empresas_agg).
# scale() estandariza a z-scores: sin esto, variables con mayor
# rango (nps_neto: −100 a 100) dominarían sobre otras (sat: 1–5).

cluster_matrix <- empresas_agg %>%
  select(starts_with("sat_"), nps_neto) %>%
  scale()

# ---- 4.2 Método del codo para elegir K ----------------------
# Probamos K = 1 a 10 y calculamos la inercia total (WSS =
# Within-cluster Sum of Squares) para cada K.
# Buscamos el "codo": el K donde la mejora se vuelve marginal.
#
# Implementación manual con map_dbl() de purrr:
# map_dbl(1:10, ~ expr) aplica la expresión para cada valor de K
# y devuelve un vector numérico de resultados.

set.seed(42)   # k-means tiene aleatoriedad; fijar semilla = reproducibilidad

wss_valores <- map_dbl(1:10, function(k) {
  kmeans(cluster_matrix, centers = k, nstart = 10)$tot.withinss
  # tot.withinss = suma de varianzas intra-cluster (inercia total)
})

fig_elbow <- tibble(k = 1:10, wss = wss_valores) %>%
  ggplot(aes(x = k, y = wss)) +
  geom_line(color = "steelblue", linewidth = 0.9) +
  geom_point(size = 3, color = "steelblue") +
  geom_vline(xintercept = 4, linetype = "dashed", color = "#d73027") +
  annotate("text", x = 4.2, y = max(wss_valores) * 0.95,
           label = "K = 4\n(elegido)", hjust = 0,
           color = "#d73027", size = 3.2) +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title    = "Método del Codo – Número Óptimo de Clusters",
    subtitle = "WSS = varianza intra-cluster total | Buscar cambio de pendiente",
    x        = "Número de clusters (K)",
    y        = "WSS (inercia total)"
  ) +
  theme_minimal(base_size = 11)

filename <- paste0(dirresults, "fig_cluster_elbow.pdf")
ggsave(filename, fig_elbow, width = 14, height = 10, units = "cm")


# ---- 4.3 K-means con K = 4 ----------------------------------
# nstart = 25: repite el algoritmo 25 veces con centros iniciales
# aleatorios y queda con la mejor solución (menor inercia total).
# Esto evita quedar atrapado en un mínimo local.

set.seed(42)
kmeans_result <- kmeans(cluster_matrix, centers = 4, nstart = 25)

# Agregar la asignación de cluster al dataset de empresas
empresas_agg <- empresas_agg %>%
  mutate(cluster = factor(kmeans_result$cluster))

cat("\n--- Distribución de empresas por cluster ---\n")
print(table(empresas_agg$cluster))


# ---- 4.4 Visualizar clusters en espacio PCA ----------------
# Para graficar en 2D, proyectamos los datos de clustering en las
# 2 primeras dimensiones del PCA (que capturan la mayor varianza).
# Los colores muestran a qué cluster pertenece cada empresa.
# stat_ellipse() dibuja una elipse de confianza al 95% por cluster.
#
# Implementación manual: aplicamos prcomp() a cluster_matrix
# (ya estandarizada), extraemos los scores de PC1 y PC2, y
# los unimos con la asignación de cluster.

pca_clusters <- prcomp(cluster_matrix, scale = FALSE, center = FALSE)
# scale=FALSE, center=FALSE: cluster_matrix ya fue estandarizada con scale()

pct_cluster <- pca_clusters$sdev^2 / sum(pca_clusters$sdev^2) * 100

cluster_scores_df <- as.data.frame(pca_clusters$x[, 1:2]) %>%
  rename(PC1 = 1, PC2 = 2) %>%
  mutate(cluster = empresas_agg$cluster)

fig_clusters <- cluster_scores_df %>%
  ggplot(aes(x = PC1, y = PC2, color = cluster, fill = cluster)) +
  geom_point(alpha = 0.7, size = 2) +
  # stat_ellipse: elipse de confianza al 95% para cada cluster
  stat_ellipse(geom = "polygon", alpha = 0.12, linewidth = 0.6) +
  scale_color_viridis(discrete = TRUE, name = "Cluster") +
  scale_fill_viridis(discrete  = TRUE, name = "Cluster") +
  labs(
    title    = "K-means: Clusters de Empresas (K = 4)",
    subtitle = "Proyección en espacio PCA | Elipses = IC 95% por cluster",
    x        = paste0("PC1 (", round(pct_cluster[1], 1), "% varianza)"),
    y        = paste0("PC2 (", round(pct_cluster[2], 1), "% varianza)")
  ) +
  theme_minimal(base_size = 11)

filename <- paste0(dirresults, "fig_clusters.pdf")
ggsave(filename, fig_clusters, width = 16, height = 12, units = "cm")


# ---- 4.5 Perfil de cada cluster ----------------------------
# El análisis de clusters no termina en el gráfico:
# hay que interpretar QUÉ caracteriza a cada grupo.
# Este paso transforma números en recomendaciones para el cliente.

perfil_clusters <- empresas_agg %>%
  group_by(cluster) %>%
  summarise(
    n_empresas   = n(),
    nps_neto     = round(mean(nps_neto), 1),
    sat_producto = round(mean(sat_producto), 2),
    sat_servicio = round(mean(sat_servicio), 2),
    sat_precio   = round(mean(sat_precio), 2),
    sat_soporte  = round(mean(sat_soporte), 2),
    sat_entrega  = round(mean(sat_entrega), 2),
    .groups      = "drop"
  )

cat("\n--- Perfil de satisfacción por cluster ---\n")
print(perfil_clusters)

# Gráfico de barras facetado: perfil de cada cluster por dimensión
# Más robusto que un gráfico de radar y más fácil de leer.

fig_perfil_clusters <- empresas_agg %>%
  pivot_longer(
    cols      = starts_with("sat_"),
    names_to  = "dimension",
    values_to = "valor"
  ) %>%
  mutate(dimension = recode(dimension,
    "sat_producto" = "Producto",
    "sat_servicio" = "Servicio",
    "sat_precio"   = "Precio",
    "sat_soporte"  = "Soporte",
    "sat_entrega"  = "Entrega"
  )) %>%
  group_by(cluster, dimension) %>%
  summarise(media = mean(valor), .groups = "drop") %>%
  ggplot(aes(x = dimension, y = media, fill = cluster)) +
  geom_col() +
  geom_hline(yintercept = 3, linetype = "dashed", color = "gray50") +
  scale_fill_viridis(discrete = TRUE) +
  scale_y_continuous(limits = c(0, 5), breaks = 1:5) +
  facet_wrap(~ cluster, labeller = label_both) +   # un panel por cluster
  labs(
    title    = "Perfil de Satisfacción por Cluster",
    subtitle = "Barras = satisfacción media (1–5) | Línea punteada = punto medio",
    x        = NULL,
    y        = "Satisfacción media"
  ) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 25, hjust = 1))

filename <- paste0(dirresults, "fig_perfil_clusters.pdf")
ggsave(filename, fig_perfil_clusters, width = 16, height = 12, units = "cm")


# ==============================================================
# SECCIÓN 5: MODELOS DE REGRESIÓN OLS
# ==============================================================
# CUÁNDO USAR REGRESIÓN:
#   Cuando quieres cuantificar el efecto de cada dimensión de
#   satisfacción sobre el NPS neto, controlando por las demás.
#
# VENTAJA FRENTE AL ANÁLISIS DE CORRELACIÓN:
#   La regresión permite decir: "controlando por precio y soporte,
#   una unidad más de satisfacción con el servicio aumenta el
#   NPS neto en X puntos". La correlación simple no controla.
#
# MODELOS INCREMENTALES:
#   Modelo 1: solo dimensiones de satisfacción
#   Modelo 2: + características de la empresa
#   Modelo 3: + efectos fijos de región
#   La comparación entre modelos revela qué factores importan.


# ---- 5.1 Estimar modelos ------------------------------------

# Modelo base: drivers de satisfacción
model1 <- lm(nps_neto ~ sat_producto + sat_servicio +
               sat_precio + sat_soporte + sat_entrega,
             data = empresas_agg)

# + características de la empresa (antigüedad y segmento)
model2 <- update(model1, . ~ . + antiguedad_cliente + segmento)

# + efectos fijos de región (controla por diferencias regionales no observadas)
model3 <- update(model2, . ~ . + region)


# ---- 5.2 Comparar modelos con broom::glance() ---------------
# glance() extrae R², AIC, BIC, etc. en un tibble limpio.
# Útil para comparar poder explicativo de modelos anidados.

cat("\n--- Comparación de modelos (R², AIC, BIC) ---\n")
bind_rows(
  glance(model1) %>% mutate(modelo = "1: satisfacción"),
  glance(model2) %>% mutate(modelo = "2: + empresa"),
  glance(model3) %>% mutate(modelo = "3: + región")
) %>%
  select(modelo, r.squared, adj.r.squared, AIC, BIC) %>%
  mutate(across(where(is.numeric), ~ round(., 3))) %>%
  print()


# ---- 5.3 Tabla de regresión para el reporte ----------------
filename <- paste0(dirresults, "tabla_regresion.txt")
stargazer(
  model1, model2, model3,
  type             = "text",
  out              = filename,
  title            = "Determinantes del NPS Neto (OLS, nivel empresa)",
  covariate.labels = c(
    "Satisf. Producto", "Satisf. Servicio", "Satisf. Precio",
    "Satisf. Soporte",  "Satisf. Entrega",
    "Antigüedad cliente", "Segmento: Mediana", "Segmento: Grande"
  ),
  dep.var.labels = "NPS Neto (%)",
  omit            = "region",
  omit.labels     = "FE Región",
  notes           = "FE de región incluidos en Modelo 3 (no reportados)"
)


# ---- 5.4 Gráfico de coeficientes (coefficient plot) --------
# Visualización alternativa a la tabla de regresión.
# Más intuitivo para audiencias no técnicas: si el IC no toca
# el cero, el efecto es estadísticamente significativo al 95%.
# tidy() de broom convierte el modelo en un tibble de coeficientes.

fig_coef <- tidy(model1, conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = recode(term,
      "sat_producto" = "Producto",
      "sat_servicio" = "Servicio",
      "sat_precio"   = "Precio/Valor",
      "sat_soporte"  = "Soporte",
      "sat_entrega"  = "Entrega"
    ),
    # Significativo si el IC 95% no cruza cero
    significativo = if_else(conf.low > 0 | conf.high < 0, "Sí", "No")
  ) %>%
  ggplot(aes(
    x    = estimate,
    y    = reorder(term, estimate),
    xmin = conf.low,
    xmax = conf.high,
    color = significativo
  )) +
  geom_pointrange(linewidth = 0.8, size = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
  scale_color_manual(
    values = c("Sí" = "#1a9850", "No" = "#bdbdbd"),
    name   = "Sig. al 95%"
  ) +
  labs(
    title    = "Coeficientes OLS – Determinantes del NPS Neto",
    subtitle = "Intervalo de confianza al 95% | Variable dep.: NPS Neto (%)",
    x        = "Coeficiente (cambio en NPS Neto por +1 punto de satisfacción)",
    y        = NULL
  ) +
  theme_minimal(base_size = 11)

filename <- paste0(dirresults, "fig_coeficientes.pdf")
ggsave(filename, fig_coef, width = 16, height = 10, units = "cm")


cat("================ ANÁLISIS GLOBALES LISTOS !!!! ====================\n\n")
