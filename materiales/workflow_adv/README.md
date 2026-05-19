# Workflow de Análisis NPS – Proyecto de Consultoría

Este proyecto es un ejemplo completo de un workflow reproducible de análisis de datos para consultoría. Demuestra las buenas prácticas cubiertas en la clase: estructura de carpetas predecible, datos crudos intocados, outputs siempre desde código, e iteración en lugar de copy-paste.

**Escenario simulado:** Un cliente nos encarga medir la satisfacción de sus 150 empresas-cliente distribuidas en 6 regiones del país. El entregable es un reporte global + 6 reportes regionales en Word, producidos con un solo `Ctrl+Shift+Enter`.

---

## Estructura del proyecto

```
workflow_adv/
│
├── README.md                  ← este archivo
│
├── data/
│   └── nps_consultoria.csv    ← datos generados por 0_simulate_data.R
│                                 (en un proyecto real: el archivo del cliente)
│
├── code/
│   ├── 0_simulate_data.R      ← genera los datos sintéticos de NPS
│   ├── 1_masterfile.R         ← punto de entrada; orquesta todo el pipeline
│   ├── 2_exploration.R        ← exploración inicial de los datos
│   ├── 3_recoding.R           ← recodificación y creación de variables
│   ├── 4_analyses.R           ← análisis global (descriptivos, PCA, clusters, regresión)
│   ├── 5_analyses_byregion.R  ← análisis por región (llamado dentro de un loop)
│   └── 6_reportes.qmd         ← plantilla de reporte Word parametrizada (Quarto)
│
└── results/
    ├── tabla_nps_region.txt        ← NPS neto por región
    ├── tabla_sat_region.tex        ← satisfacción por región (LaTeX)
    ├── tabla_regresion.txt         ← modelos OLS globales
    ├── fig_nps_region.pdf          ← barras horizontales NPS por región
    ├── fig_boxplot.pdf             ← boxplot NPS por región y segmento
    ├── fig_ridge.pdf               ← ridge plot densidades NPS
    ├── fig_heatmap.pdf             ← heatmap satisfacción región × dimensión
    ├── fig_scatter.pdf             ← scatter antigüedad vs NPS neto
    ├── fig_correlacion.pdf         ← matriz de correlación (ggcorrplot)
    ├── fig_pca_scree.pdf           ← gráfico de codo del PCA
    ├── fig_pca_biplot.pdf          ← biplot PCA
    ├── fig_cluster_elbow.pdf       ← método del codo para K
    ├── fig_clusters.pdf            ← clusters proyectados en espacio PCA
    ├── fig_perfil_clusters.pdf     ← perfil de satisfacción por cluster
    ├── fig_coeficientes.pdf        ← coeficientes OLS con IC 95%
    ├── tabla_desc_[región].txt     ← descriptivos por segmento (×6 regiones)
    ├── tabla_reg_[región].txt      ← regresión por región (×6 regiones)
    ├── fig_hist_[región].pdf       ← histograma NPS (×6 regiones)
    ├── fig_top_bottom_[región].pdf ← top/bottom 5 empresas (×6 regiones)
    └── reporte_[región].docx       ← reporte Word completo (×6 regiones)
```

---

## Cómo reproducir todos los resultados

**Requisitos previos:** R ≥ 4.2 y los paquetes listados abajo.

**Pasos:**

1. Abrir la carpeta `workflow_adv/` en Positron (File → Open Folder).
2. Abrir `code/1_masterfile.R`.
3. Cambiar la línea `folder <-` con la ruta a tu carpeta `workflow_adv/`:
   ```r
   folder <- "/tu/ruta/workflow_adv/"
   ```
4. Ejecutar el script completo (`Ctrl+Shift+Enter` en Positron).
5. Todos los outputs aparecen en `results/` de forma automática.

> **Principio clave:** ningún paso se ejecuta a mano. No hay copy-paste de tablas a Word, no hay gráficos guardados con clic derecho, no hay filtros manuales. Todo es código, todo es reproducible.

---

## Descripción de cada script

### `0_simulate_data.R` — Generación de datos

Crea los datos sintéticos de la encuesta NPS y los guarda como `data/nps_consultoria.csv`. En un proyecto real este script se reemplaza por la carga directa del archivo enviado por el cliente (ej. `read_csv("data/encuesta_cliente.csv")`). El archivo de datos crudos nunca se modifica.

**Variables generadas:**

| Variable | Descripción | Rango |
|---|---|---|
| `id_respuesta` | ID único por respuesta | — |
| `empresa_id` | Código de la empresa (EMP001–EMP150) | — |
| `region` | Región geográfica | 6 categorías |
| `segmento` | Tamaño de empresa | Pyme / Mediana / Grande |
| `antiguedad_cliente` | Años como cliente | 1–10 |
| `n_compras` | Compras en el último año | ≥ 1 |
| `nps_score` | Pregunta NPS cruda ("¿cuán probable es que nos recomiendes?") | 0–10 |
| `sat_producto` | Satisfacción con el producto | 1–5 |
| `sat_servicio` | Satisfacción con el servicio al cliente | 1–5 |
| `sat_precio` | Satisfacción con precio / valor percibido | 1–5 |
| `sat_soporte` | Satisfacción con soporte técnico | 1–5 |
| `sat_entrega` | Satisfacción con tiempos de entrega | 1–5 |

---

### `1_masterfile.R` — Orquestador del pipeline

Punto de entrada único del proyecto. Define los directorios, carga los paquetes, y llama a todos los demás scripts en el orden correcto. El loop al final itera sobre las 6 regiones y produce para cada una un análisis y un reporte Word, sin duplicar una sola línea de código.

```
1_masterfile.R
    ├── source("0_simulate_data.R")   → crea el CSV
    ├── read_csv("nps_consultoria.csv")
    ├── source("2_exploration.R")     → exploración
    ├── source("3_recoding.R")        → recodificación
    ├── source("4_analyses.R")        → análisis global
    └── for r in regiones:
            ├── source("5_analyses_byregion.R")
            └── quarto_render("6_reportes.qmd") → reporte_[r].docx
```

**Paquetes requeridos** (se instalan automáticamente con `pacman` si no están):

| Paquete | Para qué se usa |
|---|---|
| `tidyverse` | Manipulación de datos (dplyr, tidyr) y gráficos (ggplot2) |
| `knitr` | Tablas formateadas con `kable()` |
| `stargazer` | Tablas de regresión y descriptivos exportables |
| `xtable` | Tablas en formato LaTeX |
| `rmarkdown` | `render()` para producir reportes `.Rmd` a Word / HTML / PDF (bundled con Positron) |
| `viridis` | Paletas de color accesibles y consistentes |
| `scales` | Formato de ejes (porcentajes, monedas, etc.) |
| `ggridges` | Ridge plots (densidades solapadas por grupo) |
| `patchwork` | Combinar múltiples ggplots en un solo panel |
| `cluster` | Algoritmos de clustering (k-means, silhouette) |
| `broom` | Convertir modelos en tibbles: `tidy()`, `glance()` |
| `ggcorrplot` | Heatmap de matrices de correlación |

---

### `2_exploration.R` — Exploración de datos

Primer vistazo sistemático antes de cualquier análisis. Imprime en consola (no guarda archivos). El propósito es detectar problemas temprano: valores faltantes inesperados, variables con rangos anómalos, grupos sub-representados en la muestra.

**Qué verifica:**
- Estructura y tipos de columnas (`glimpse`)
- Conteo de `NA` por variable
- Distribución de frecuencias del NPS (0–10)
- Balance de la muestra por región × segmento
- Número de empresas por región
- Correlaciones entre dimensiones de satisfacción

---

### `3_recoding.R` — Preparación de datos

Crea las variables derivadas necesarias para el análisis. Nunca modifica el objeto `encuesta` original; trabaja sobre una copia `encuesta_sub`.

**Variables creadas:**

| Variable | Descripción | Lógica |
|---|---|---|
| `nps_categoria` | Promotor / Pasivo / Detractor | 9–10 / 7–8 / 0–6 (estándar NPS) |
| `segmento` | Factor ordenado | Pyme < Mediana < Grande |
| `indice_sat` | Índice de satisfacción compuesto | Promedio de las 5 dimensiones (1–5) |

**Dataset adicional creado:**

- `empresas_agg`: datos agregados a nivel empresa (una fila por empresa), con NPS neto, promedios de satisfacción y N de respondentes. Este dataset se usa en PCA, clustering y regresión.

---

### `4_analyses.R` — Análisis global

El script más extenso. Organizado en 5 secciones claramente separadas.

#### Sección 1: Estadísticas descriptivas

- **NPS neto por región** (tabla `.txt`): % Promotores, % Pasivos, % Detractores y NPS Neto = %P − %D. Es la métrica central que el cliente quiere ver.
- **Satisfacción por región** (tabla `.tex`): media y desviación estándar de cada dimensión.

#### Sección 2: Visualizaciones

Cinco tipos de gráficos distintos para distintas preguntas analíticas:

| Gráfico | Tipo | Pregunta que responde |
|---|---|---|
| `fig_nps_region.pdf` | Barras horizontales con gradiente rojo–verde | ¿Cuál es el NPS de cada región? |
| `fig_boxplot.pdf` | Boxplot agrupado | ¿Cómo se distribuye el NPS por región y segmento? |
| `fig_ridge.pdf` | Ridge plot (densidades) | ¿Qué forma tiene la distribución? ¿Es bimodal? |
| `fig_heatmap.pdf` | Heatmap región × dimensión | ¿En qué dimensión falla cada región? |
| `fig_scatter.pdf` | Scatter con smooth | ¿Los clientes más antiguos tienen mayor NPS? |

#### Sección 3: Análisis de Componentes Principales (PCA)

**Cuándo usar PCA:** cuando tienes múltiples variables correlacionadas y quieres saber si reflejan uno o pocos factores latentes subyacentes. Aquí preguntamos: ¿las 5 dimensiones de satisfacción miden constructos distintos, o básicamente miden lo mismo?

**Outputs:**
- `fig_correlacion.pdf`: heatmap de la matriz de correlación entre dimensiones. Confirma que el PCA tiene sentido (las variables deben estar correlacionadas).
- `fig_pca_scree.pdf`: gráfico de codo. Muestra qué % de varianza explica cada componente. La "rodilla" sugiere cuántos componentes conservar.
- `fig_pca_biplot.pdf`: biplot. Muestra observaciones (puntos) y variables (flechas) en el espacio PCA. Flechas en la misma dirección = variables correlacionadas.

**Interpretación típica:** si el PC1 explica >50% de la varianza y todas las variables cargan positivamente sobre él, las 5 dimensiones son básicamente un factor único de "satisfacción general". Si hay dos componentes relevantes, los datos distinguen dos tipos de satisfacción (ej. calidad de producto vs. calidad de servicio).

#### Sección 4: Clustering K-means

**Cuándo usar clustering:** cuando quieres identificar "tipos" de clientes sin haberlos definido a priori. El algoritmo agrupa empresas con perfiles similares de satisfacción.

**Utilidad en consultoría:** los clusters permiten personalizar acciones. Por ejemplo:
- *Cluster de alto NPS + baja antigüedad* → programa de fidelización temprana
- *Cluster de bajo soporte + precio aceptable* → intervención en equipo técnico
- *Cluster de alto producto + bajo servicio* → capacitación en atención al cliente

**Pasos del análisis:**
1. `fig_cluster_elbow.pdf`: método del codo para elegir K. Se grafica la inercia (varianza intra-cluster) para K = 1 a 10. La "rodilla" de la curva indica el K óptimo.
2. K-means con K = 4 (25 inicializaciones aleatorias para evitar mínimos locales).
3. `fig_clusters.pdf`: clusters proyectados en las 2 primeras dimensiones del PCA, con elipses convexas.
4. `fig_perfil_clusters.pdf`: barras facetadas mostrando la satisfacción media en cada dimensión para cada cluster. Este es el paso más importante: transforma los números en perfiles interpretables.

#### Sección 5: Regresión OLS

**Cuándo usar regresión (vs. correlación):** la regresión permite cuantificar el efecto de cada dimensión *controlando por las demás*. Una correlación alta entre "servicio" y NPS podría deberse a que las empresas con buen servicio también tienen buen producto. La regresión separa esos efectos.

**Tres modelos anidados:**
- Modelo 1: NPS Neto ~ sat_producto + sat_servicio + sat_precio + sat_soporte + sat_entrega
- Modelo 2: + antigüedad del cliente + segmento
- Modelo 3: + efectos fijos de región

La comparación de R² ajustado y AIC entre modelos revela si las características de la empresa o la región explican varianza adicional más allá de la satisfacción.

**Outputs:**
- `tabla_regresion.txt`: tabla stargazer con los 3 modelos lado a lado.
- `fig_coeficientes.pdf`: coefficient plot del Modelo 1. Más intuitivo que la tabla para audiencias no técnicas: si el IC 95% no cruza el cero, el efecto es estadísticamente significativo.

---

### `5_analyses_byregion.R` — Análisis por región

Llamado dentro del loop de `1_masterfile.R` para cada una de las 6 regiones. La variable `r` contiene el nombre de la región activa; `encuesta_region` contiene los datos ya filtrados.

**Produce para cada región:**

| Output | Contenido |
|---|---|
| `tabla_desc_[r].txt` | NPS neto por segmento de empresa |
| `fig_top_bottom_[r].pdf` | Top 5 y Bottom 5 empresas por NPS neto |
| `fig_hist_[r].pdf` | Histograma del NPS con zonas coloreadas por categoría |
| `tabla_reg_[r].txt` | Regresión OLS de NPS neto sobre dimensiones de satisfacción |

El análisis de Top/Bottom 5 es especialmente valorado en consultoría: identifica los "quick wins" (empresas en riesgo que merecen intervención inmediata) y los casos de éxito (posibles embajadores de marca).

La regresión por región permite detectar heterogeneidad en los "drivers" del NPS: en una región puede importar más el precio, en otra el tiempo de entrega. Esta información orienta acciones diferenciadas.

---

### `6_reportes.qmd` — Plantilla de reporte parametrizado (Quarto)

Documento Quarto que produce un reporte Word profesional para una región. El mismo archivo genera los 6 reportes regionales gracias al parámetro `titulo_region` que recibe del loop.

**Estructura del reporte:**
1. **Resumen ejecutivo NPS**: tabla con % Promotores, % Pasivos, % Detractores y NPS Neto, más interpretación automática en texto.
2. **Distribución del NPS**: histograma con zonas coloreadas (rojo / amarillo / verde).
3. **Satisfacción por dimensión**: comparación visual región vs. promedio global con un "dumbbell plot" (segmento de línea).
4. **NPS por segmento**: tabla cruzada dentro de la región.
5. **Empresas destacadas**: Top 3 y Bottom 3 por NPS neto.
6. **Factores explicativos**: tabla de regresión OLS con interpretación en texto.

> La fecha del reporte, el N de respondentes y la interpretación del NPS Neto se insertan **automáticamente** mediante código R en línea (`\`r ...\``). Si los datos cambian, el texto cambia solo.

---

## Control de versiones con GitHub desde Positron

GitHub actúa como una "máquina del tiempo" para el proyecto: guarda cada versión del código con una descripción de qué cambió y por qué. Si algo se rompe, se puede volver a cualquier estado anterior. Si trabajas con otras personas, cada quien puede trabajar en paralelo sin pisarse.

Positron tiene un panel de Git integrado que permite hacer todo esto con botones — sin necesidad de usar la terminal.

---

### Paso 0: Configuración inicial (solo una vez por computador)

Antes de usar Git por primera vez, hay que decirle quién eres. Ejecutar esto en la terminal de Positron (panel **Terminal**, abajo):

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

También necesitas una cuenta en [github.com](https://github.com) (es gratis).

---

### Paso 1: Crear el repositorio en GitHub

1. Ir a [github.com](https://github.com) → botón verde **New** (arriba a la izquierda).
2. Ponerle nombre al repositorio (ej. `analisis-nps`).
3. Dejarlo en **Private** si los datos son confidenciales, **Public** si es material de clase.
4. **No** marcar "Add a README" ni ninguna otra opción — el repositorio debe quedar vacío.
5. Clic en **Create repository**.
6. GitHub muestra una página con instrucciones. Copiar la URL del repositorio (termina en `.git`), por ejemplo:
   ```
   https://github.com/tu-usuario/analisis-nps.git
   ```

---

### Paso 2: Conectar la carpeta local con GitHub

En la terminal de Positron, dentro de la carpeta `workflow_adv/`:

```bash
# Inicializar Git en la carpeta (solo la primera vez)
git init

# Conectar con el repositorio remoto que creaste en GitHub
git remote add origin https://github.com/tu-usuario/analisis-nps.git

# Verificar que la conexión quedó bien
git remote -v
```

Debería mostrar:
```
origin  https://github.com/tu-usuario/analisis-nps.git (fetch)
origin  https://github.com/tu-usuario/analisis-nps.git (push)
```

---

### Paso 3: Crear un `.gitignore`

El `.gitignore` le dice a Git qué archivos **no** debe rastrear. Los outputs (`results/`) y los datos crudos grandes generalmente no se suben: se pueden regenerar con el código. Crear el archivo `workflow_adv/.gitignore` con este contenido:

```
# Outputs (se regeneran corriendo el pipeline)
results/

# Datos crudos grandes (subir solo si son pequeños y no confidenciales)
# data/

# Archivos temporales de R y Positron
.Rhistory
.RData
.Rproj.user/
*.Rproj

# Archivos temporales del sistema
.DS_Store
Thumbs.db
```

> **Nota sobre los datos:** si el archivo de datos es pequeño (< 50 MB) y no es confidencial, se puede subir eliminando la línea `# data/`. Si es confidencial o grande, no subirlo nunca — documentar en el README cómo conseguirlo.

---

### Paso 4: Primer commit y push

Desde el **panel de Source Control** en Positron (ícono de rama en la barra lateral izquierda):

**Con la interfaz gráfica:**

1. Aparece una lista de todos los archivos con cambios (en amarillo/verde).
2. Hacer clic en el **+** junto a cada archivo que quieres incluir, o en el **+** al lado de "Changes" para seleccionar todos. Esto hace el *stage* de los archivos.
3. Escribir un mensaje en el campo de texto arriba (ej. `"estructura inicial del proyecto"`).
4. Clic en el botón **Commit** (marca de verificación ✓).
5. Clic en el botón **Publish Branch** o **Push** (ícono de nube con flecha ↑) para subir a GitHub.

**O desde la terminal:**

```bash
# Agregar todos los archivos al "stage" (seleccionar qué va en este commit)
git add .

# Crear el commit con un mensaje descriptivo
git commit -m "estructura inicial del proyecto"

# Subir a GitHub (primera vez: -u establece el branch por defecto)
git push -u origin main
```

Ir a `github.com/tu-usuario/analisis-nps` — el código ya está ahí.

---

### Rutina diaria: el ciclo Pull → Trabajar → Stage → Commit → Push

Este es el flujo que se repite en cada sesión de trabajo. Los nombres en inglés son los estándar de Git:

```
┌─────────────────────────────────────────────────────┐
│  Al EMPEZAR la sesión        →  Pull                │
│  Trabajar normalmente        →  editar, correr código│
│  Al TERMINAR (o cada rato)   →  Stage → Commit → Push│
└─────────────────────────────────────────────────────┘
```

**Pull** (bajar cambios): antes de empezar a trabajar, bajar lo que otros subieron (o lo que tú subiste desde otro computador). En Positron: botón **Pull** (ícono de nube con flecha ↓) en el panel Source Control. O en terminal: `git pull`.

**Stage** (seleccionar): elegir qué archivos van en el próximo commit. No todos los cambios tienen que ir juntos — podés agruparlos por tema.

**Commit** (guardar versión): crear un punto de control con un mensaje que explique *qué* cambió y *por qué*. El mensaje es para tu yo del futuro (y para tus colaboradores).

**Push** (subir): enviar los commits locales a GitHub.

---

### Cómo escribir buenos mensajes de commit

El mensaje de commit es el historial legible del proyecto. Un buen mensaje explica el *por qué*, no solo el *qué*:

| Mal mensaje | Buen mensaje |
|---|---|
| `"cambios"` | `"agrega análisis PCA de dimensiones de satisfacción"` |
| `"fix"` | `"corrige filtro de región en 5_analyses_byregion.R"` |
| `"update"` | `"actualiza datos del cliente con oleada 2 (mayo 2025)"` |
| `"wip"` | `"añade clustering k-means con K=4 según método del codo"` |

Convención útil: empezar con un verbo en presente (`agrega`, `corrige`, `actualiza`, `elimina`, `reorganiza`).

---

### Ver el historial y recuperar versiones anteriores

**Ver historial** desde Positron: en el panel Source Control → ícono de reloj (Timeline), o instalar la extensión **Git Graph** (buscarla en Extensions). Muestra todos los commits como una línea de tiempo.

**Desde la terminal:**
```bash
# Ver los últimos commits
git log --oneline

# Ver qué cambió en un commit específico
git show abc1234   # reemplazar abc1234 con el hash del commit

# Comparar el estado actual con el último commit
git diff
```

**Recuperar un archivo borrado o dañado:**
```bash
# Restaurar un archivo al estado del último commit
git checkout HEAD -- code/4_analyses.R
```

**Volver a una versión anterior completa** (con cuidado — descarta cambios no guardados):
```bash
# Ver el hash del commit al que quieres volver
git log --oneline

# Crear una rama nueva desde ese punto (más seguro que reescribir el historial)
git checkout -b recuperacion abc1234
```

---

### Trabajar con otras personas: ramas y pull requests

Cuando varias personas trabajan en el mismo proyecto, las **ramas** (branches) evitan que los cambios de uno interfieran con los del otro.

**Flujo básico:**

```bash
# Crear una rama para tu trabajo (ej. "nueva-seccion-clustering")
git checkout -b nueva-seccion-clustering

# Trabajar normalmente: editar, commit, push de esta rama
git push origin nueva-seccion-clustering
```

En GitHub → **Pull Request**: proponer que tu rama se mezcle con `main`. El otro colaborador la revisa, comenta y aprueba. Una vez aprobado, se hace el *merge*.

En proyectos de consultoría con un solo analista, las ramas sirven para explorar cambios experimentales sin romper la versión que ya funciona.

---

### Qué subir y qué no subir a GitHub

| Subir ✓ | No subir ✗ |
|---|---|
| Todo el código (`code/`) | Datos confidenciales del cliente |
| `README.md` | Outputs grandes (`results/*.pdf`, `*.docx`) |
| `.gitignore` | Archivos temporales (`.Rhistory`, `.DS_Store`) |
| Datos pequeños y no confidenciales | Credenciales o tokens de API |

> **Regla de oro:** si no lo escribiste tú (o no es un dato de entrada que el cliente autorizó compartir), probablemente no debería estar en el repositorio.

---

### Solución a problemas comunes

**"rejected — non-fast-forward"** al hacer push: hay cambios en GitHub que no tienes localmente. Hacer `git pull` primero, resolver posibles conflictos, y luego `git push`.

**Conflicto de merge**: ocurre cuando dos personas editaron el mismo archivo en la misma línea. Git marca el conflicto en el archivo con `<<<<<<`, `======`, `>>>>>>`. Editar el archivo manualmente para quedarte con la versión correcta, luego `git add` y `git commit`.

**Subiste algo que no debías** (ej. un archivo con credenciales): eliminarlo del historial es complejo. La solución más práctica es revocar las credenciales inmediatamente y nunca volver a subirlas. Para el futuro: agregar el archivo al `.gitignore` antes del primer commit.

**Perdiste cambios no comiteados**: si cerraste Positron sin hacer commit, los cambios están en el disco pero no en Git. Git solo protege lo que fue comiteado. Hacer commits frecuentes es el mejor seguro.

---

## Usar IA (Claude Code u otros) dentro del proyecto

La IA no reemplaza el pipeline — opera *dentro* de él. La regla es simple: cualquier cambio sugerido por la IA debe terminar en un archivo de código bajo control de versiones, nunca en un resultado manual fuera del pipeline. Si la IA te da un gráfico bonito en el chat pero ese gráfico no se puede regenerar corriendo `1_masterfile.R`, no sirve.

Positron permite usar IA de dos formas: como **asistente integrado** (panel de chat dentro del editor) o como **Claude Code** (agente en la terminal que puede leer, editar y correr archivos por sí solo). Son herramientas distintas para tareas distintas.

---

### Opción A: Asistente de chat integrado en Positron

Positron soporta extensiones de VS Code, incluyendo asistentes de IA. La opción más directa es la extensión oficial de Claude.

**Instalación:**

1. En Positron, abrir el panel de extensiones (`Ctrl+Shift+X` / `Cmd+Shift+X`).
2. Buscar `Claude` → instalar **Claude for VS Code** (publicado por Anthropic).
3. Al abrirla por primera vez pedirá un API key. Obtenerlo en [console.anthropic.com](https://console.anthropic.com) (requiere cuenta).
4. Alternativa sin API key: instalar **GitHub Copilot** (requiere cuenta GitHub) o **Codeium** (gratuito, sin cuenta).

**Cómo usarlo:**

El panel de chat aparece en la barra lateral. Permite:

- **Seleccionar código** en un script y preguntar sobre él directamente (`Cmd+L` abre el chat con el código seleccionado como contexto).
- **Adjuntar archivos** al chat para que el modelo lea todo el script antes de responder.
- **Pedir que edite** el archivo abierto directamente (el modelo propone un diff que tú aceptas o rechazas).

**Cuándo es útil:**

| Situación | Ejemplo de prompt |
|---|---|
| Entender un bloque de código ajeno | "¿Qué hace exactamente esta línea de `across()`?" |
| Depurar un error | Pegar el mensaje de error + el código que lo causó |
| Aprender una función nueva | "¿Cómo funciona `fviz_pca_biplot()`? ¿Qué argumentos tiene?" |
| Adaptar un análisis | "Modifica esta regresión para incluir un término cuadrático de `antiguedad_cliente`" |
| Mejorar un gráfico | "Cambia los colores de este ggplot a una paleta de azules y agrega título al eje Y" |

---

### Opción B: Claude Code desde la terminal (agente autónomo)

Claude Code es una herramienta de línea de comandos que actúa como un agente: puede leer el proyecto completo, editar múltiples archivos, correr código y ejecutar comandos de terminal por sí solo. Es mucho más potente que el chat para tareas que afectan varios archivos a la vez.

**Instalación:**

Requiere Node.js instalado. En la terminal de Positron:

```bash
# Instalar Claude Code globalmente
npm install -g @anthropic-ai/claude-code

# Verificar instalación
claude --version
```

En el primer uso pedirá autenticarse con tu cuenta de Anthropic (abre el navegador automáticamente).

**Uso básico:**

```bash
# Abrir Claude Code en la carpeta del proyecto
cd /tu/ruta/workflow_adv
claude
```

Esto inicia una sesión interactiva. Claude Code lee automáticamente los archivos del proyecto y puede responder preguntas o ejecutar tareas.

Para una tarea puntual sin sesión interactiva:

```bash
claude -p "¿Qué hace el script 4_analyses.R? Resúmelo en 5 puntos"
```

**Ejemplos de tareas que Claude Code puede hacer en este proyecto:**

```bash
# Pedir que explique el pipeline completo
claude -p "Lee todos los scripts en code/ y explica el flujo completo del pipeline en español"

# Pedir que agregue un análisis nuevo directamente al código
claude -p "En 4_analyses.R, agrega un violin plot que compare la distribución del NPS neto por cluster. Guárdalo en results/ con ggsave()"

# Pedir que identifique errores potenciales
claude -p "Revisa 3_recoding.R y dime si hay algún caso donde la variable indice_sat podría quedar con NA sin ser detectado"

# Pedir que genere una nueva variante del reporte
claude -p "Crea un script 4b_analyses_segmento.R que replique la estructura de 4_analyses.R pero desagregando por segmento en vez de por región"

# Pedir que actualice el README si cambió algo
claude -p "Acabo de agregar la variable 'canal_venta' a los datos. Actualiza la tabla de variables en el README para incluirla"
```

**La diferencia clave con el chat:** Claude Code *ejecuta* los cambios (con tu aprobación en cada paso), no solo los sugiere. Cuando propone editar un archivo, muestra el diff exacto y pide confirmación antes de guardar.

---

### Principio: la IA opera dentro del pipeline, no fuera

Este es el punto más importante. Hay dos maneras de usar IA en análisis de datos:

**Mal uso (fuera del pipeline):**
```
IA genera gráfico en el chat
→ tú haces screenshot o copias el código suelto
→ lo pegas en Word manualmente
→ nadie más puede reproducirlo
→ si los datos cambian, hay que hacerlo todo de nuevo a mano
```

**Buen uso (dentro del pipeline):**
```
IA edita 4_analyses.R (con tu revisión)
→ el nuevo gráfico vive en el código
→ se regenera solo al correr 1_masterfile.R
→ queda en Git con un mensaje de commit
→ cualquier colaborador obtiene el mismo resultado
```

La pregunta que hay que hacerse siempre: **¿el cambio que sugirió la IA quedó en un archivo de código?** Si la respuesta es sí, está bien. Si es no, algo salió del pipeline.

---

### Qué pedirle a la IA (y qué no)

**Buenas tareas para la IA:**

- Explicar funciones o paquetes desconocidos
- Depurar errores de R (pegar el traceback completo)
- Adaptar código existente a nuevos requerimientos
- Agregar comentarios a código que no los tiene
- Sugerir visualizaciones alternativas para un mismo dato
- Revisar si hay errores lógicos en una recodificación
- Traducir código de un paquete a otro (ej. de `reshape2` a `tidyr`)
- Generar código boilerplate (ej. estructura de un nuevo script)

**Tareas donde la IA falla o hay que tener cuidado:**

- **Interpretación sustantiva de resultados**: la IA puede decirte que el coeficiente es 8.5, pero no sabe si ese tamaño de efecto es *importante* para tu cliente o para tu disciplina. Eso requiere tu juicio.
- **Decisiones de diseño del análisis**: qué variables incluir en el modelo, si K=4 es el número correcto de clusters, si el PCA tiene sentido dado el contexto — son decisiones metodológicas, no de código.
- **Validar que los datos son correctos**: la IA no puede saber si los datos del cliente tienen un error de captura o una convención de codificación rara. Solo tú (o el cliente) lo saben.
- **Código que no puedes entender**: si la IA produce código que no entiendes, no lo uses. No puedes defenderte ante el cliente si algo sale mal.

---

### Flujo recomendado: IA + Git juntos

Combinar IA y Git es especialmente poderoso: la IA puede equivocarse, pero Git permite deshacer cualquier cambio con un solo comando.

```
1. Hacer commit del estado actual ("antes de usar IA")
   git commit -m "estado antes de experimentar con clustering"

2. Pedirle a la IA que modifique el código
   claude -p "agrega análisis de silueta para validar K=4"

3. Revisar los cambios propuestos (git diff)
   git diff code/4_analyses.R

4a. Si los cambios son buenos → commit
    git commit -m "agrega análisis de silueta (sugerido por Claude)"

4b. Si los cambios son malos → deshacer
    git checkout -- code/4_analyses.R
```

Este ciclo elimina el miedo a experimentar: siempre hay un punto de retorno seguro.

---

## Principios de workflow aplicados en este proyecto

Este proyecto ilustra las 5 buenas prácticas discutidas en clase:

**1. Estructura predecible**
Las carpetas `data/`, `code/` y `results/` tienen roles estrictamente separados. Cualquier colaborador (o IA) puede orientarse sin preguntar.

**2. Dato crudo intocado**
El archivo `data/nps_consultoria.csv` nunca se modifica. Todo el procesamiento ocurre en R, sobre copias en memoria. Si algo sale mal, el dato original está intacto.

**3. Outputs siempre desde código**
Ningún gráfico se guarda con clic derecho. Ninguna tabla se copia a Word manualmente. Todo se produce con `ggsave()`, `stargazer()`, `xtable()` y `render()`.

**4. DRY – Don't Repeat Yourself**
El mismo script `5_analyses_byregion.R` y la misma plantilla `6_reportes.qmd` producen los 6 análisis y 6 reportes regionales. Sin el loop, habría que duplicar ese código 6 veces: 6 veces más errores potenciales, 6 veces más trabajo al actualizar.

**5. Un solo punto de entrada**
Ejecutar `1_masterfile.R` de principio a fin reproduce absolutamente todos los resultados. No hay pasos manuales intermedios ni instrucciones orales que recordar.

---

## Preguntas frecuentes

**¿Por qué hay un script separado para simular los datos?**
Para que el workflow sea auto-contenido y funcione sin depender de un archivo externo del cliente. En un proyecto real, `0_simulate_data.R` se reemplaza por una línea de `read_csv()` apuntando al archivo original. El resto del pipeline no cambia.

**¿Por qué se agrega a nivel empresa para PCA y clustering?**
Porque los métodos de reducción de dimensionalidad y clustering buscan patrones entre *unidades de análisis*, y nuestra unidad de análisis de negocio es la empresa, no el respondente individual. Trabajar a nivel respondente inflaría artificialmente los N y mezclaría varianza intra-empresa con varianza entre empresas.

**¿Por qué K = 4 en el clustering?**
El método del codo en `fig_cluster_elbow.pdf` muestra un quiebre de pendiente alrededor de K = 4. Es una decisión analítica, no un resultado automático. En un proyecto real se complementa con análisis de silueta y con el juicio del equipo sobre cuántos segmentos son accionables para el cliente.

**¿Cómo cambio el número de regiones o empresas?**
Modificar los parámetros al inicio de `0_simulate_data.R`: `n_empresas`, `regiones`, `region_baseline`. El resto del pipeline se adapta automáticamente.

**¿Puedo usar datos reales en lugar de los simulados?**
Sí. Reemplazar el bloque de `source("0_simulate_data.R")` en el masterfile por `encuesta <- read_csv("data/tu_archivo.csv")`. Las variables deben tener los mismos nombres que en `nps_consultoria.csv` (ver tabla en sección `0_simulate_data.R` arriba).

---

*Proyecto desarrollado para el Taller DobleA — Diseño y Análisis de Encuestas para Investigación Aplicada.*
