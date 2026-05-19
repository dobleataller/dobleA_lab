
# ==============================================================
# 1_masterfile.R  ·  Análisis NPS – Encuesta de Satisfacción
# ==============================================================
# PROPÓSITO: Punto de entrada único del proyecto.
#            Este archivo orquesta TODO el pipeline:
#            simular datos → explorar → recodificar →
#            analizar globalmente → analizar por región →
#            generar reportes Word por región.
#
# INSTRUCCIONES:
#   1. Cambiar la línea "folder <-" con la ruta de tu proyecto
#   2. Ejecutar este script completo (Ctrl+Shift+Enter en Positron)
#   3. Todos los outputs aparecerán automáticamente en results/
#
# PRINCIPIO CLAVE: ningún paso se ejecuta manualmente.
#   Un solo Ctrl+Shift+Enter produce todos los resultados.
# ==============================================================

# Limpiar entorno y consola al inicio de cada sesión
# Esto garantiza que no queden objetos "sucios" de corridas anteriores
cat("\014")       # equivale a Ctrl+L: limpia la consola
rm(list = ls())   # elimina todos los objetos del entorno global


# ==============================================================
# PAQUETES
# ==============================================================
# pacman::p_load() instala el paquete si no existe en el sistema
# y luego lo carga. Es equivalente a:
#   if (!require(pkg)) install.packages(pkg); library(pkg)

library("pacman")
p_load(
  # ---- Manipulación de datos --------------------------------
  "tidyverse",    # dplyr, ggplot2, tidyr, readr, purrr, etc.
                  # El "universo" central del análisis en R

  # ---- Tablas y exportación ---------------------------------
  "knitr",        # kable() para tablas formateadas en consola/Quarto
  "stargazer",    # tablas de regresión y descriptivos profesionales
  "xtable",       # tablas en formato LaTeX (para papers/reportes)
  "rmarkdown",    # render() para producir reportes .Rmd → Word/HTML/PDF

  # ---- Visualización ----------------------------------------
  "viridis",      # paletas de colores accesibles (daltonismo-friendly)
  "scales",       # formatear ejes: percent_format(), comma(), etc.
  "ggridges",     # ridgeline plots: densidades solapadas por grupo
  "patchwork",    # combinar múltiples ggplots con + / / y |

  # ---- Métodos estadísticos avanzados -----------------------
  "cluster",      # algoritmos de clustering: kmeans(), silhouette(), etc.
  "broom",        # convertir objetos lm/glm en tibbles: tidy(), glance()
  "ggcorrplot"    # heatmap de matrices de correlación
)


# ==============================================================
# DIRECTORIOS
# ==============================================================
# Definir las rutas UNA SOLA VEZ aquí.
# El resto de los scripts usan dirdata, dircode, dirresults
# (nunca rutas absolutas dentro de los scripts hijos).

# *** CAMBIAR ESTA LÍNEA con la ruta de tu proyecto ***
folder     <- "/Users/mebucca/Library/Mobile Documents/com~apple~CloudDocs/TallerAA/workflow_adv/"

dircode    <- paste0(folder, "code/")
dirdata    <- paste0(folder, "data/")
dirresults <- paste0(folder, "results/")


# ==============================================================
# PASO 0: SIMULAR / IMPORTAR DATOS
# ==============================================================
# Este script crea nps_consultoria.csv en data/.
# En un proyecto real, este paso se reemplaza por:
#   read_csv("data/nps_raw.csv") o read_xlsx("data/encuesta.xlsx")
# NUNCA modificar el archivo original — solo leer.

setwd(dircode)
source("0_simulate_data.R")

# Cargar el CSV recién generado
setwd(dirdata)
encuesta <- read_csv("nps_consultoria.csv", show_col_types = FALSE)
# show_col_types = FALSE: silencia el mensaje de tipos de columna


# ==============================================================
# PASO 1: EXPLORACIÓN
# ==============================================================
# Primer vistazo: estructura, distribuciones, valores faltantes.
# NUNCA saltarse este paso — los errores silenciosos se detectan aquí.

setwd(dircode)
source("2_exploration.R")


# ==============================================================
# PASO 2: RECODIFICACIÓN
# ==============================================================
# Crear nuevas variables: categoría NPS, índice de satisfacción,
# y datos agregados a nivel empresa (para PCA y clustering).

setwd(dircode)
source("3_recoding.R")


# ==============================================================
# PASO 3: ANÁLISIS GLOBAL
# ==============================================================
# Descriptivos, visualizaciones, PCA, clustering, regresión.
# Outputs guardados en results/ con nombres descriptivos.

setwd(dircode)
source("4_analyses.R")


# ==============================================================
# PASO 4: ANÁLISIS Y REPORTES POR REGIÓN
# ==============================================================
# Principio DRY (Don't Repeat Yourself):
#   En vez de copiar-pegar el código 6 veces (una por región),
#   usamos un loop. Mismo código → 6 análisis + 6 reportes.

regiones_sorted <- sort(unique(encuesta_sub$region))

for (r in regiones_sorted) {

  cat("================ ANÁLISIS REGIÓN:", r, "==================\n")

  # Filtrar datos para la región actual
  # La variable 'r' queda disponible para los scripts sourced
  # y para el .qmd de reporte
  encuesta_region <- encuesta_sub %>% filter(region == r)

  # Análisis específico de la región (tablas + figura)
  setwd(dircode)
  source("5_analyses_byregion.R")

  # Reporte Word parametrizado para esta región.
  # rmarkdown::render() viene bundled con Positron (no requiere CLI externo).
  # output_file acepta rutas absolutas: el archivo va directamente a results/.
  # NOTA: 6_reportes.qmd es la versión equivalente en formato Quarto nativo;
  #       se puede usar con quarto::quarto_render() si el CLI está instalado.
  setwd(dircode)
  rmarkdown::render(
    input       = "6_reportes.Rmd",
    output_file = file.path(dirresults, paste0("reporte_", r, ".docx")),
    params      = list(titulo_region = paste("Reporte NPS -", r)),
    quiet       = TRUE
  )

  cat("  -> Reporte guardado: reporte_", r, ".docx\n\n", sep = "")
}

cat("================ PIPELINE COMPLETO !!!! ====================\n")
cat("Outputs generados en:", dirresults, "\n")
