
#   Rscript --vanilla countDSLEntities.R DSL/WarshipCombatManagement.norasi
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1 || basename(args[1]) != "WarshipCombatManagement.norasi")
  stop("give the one file this script counts: WarshipCombatManagement.norasi")
tx <- readLines(args[1], warn = FALSE, encoding = "UTF-8")
if (!any(trimws(tx) == "model WarshipCombatManagement")) stop("this file is not the DSL example WarshipCombatManagement")
fmt <- function(x) vapply(x, function(v) format(v, big.mark = ","), "")
words <- function(s) strsplit(trimws(s), "[[:space:]]+")[[1]]
names_in <- function(s) { v <- trimws(strsplit(s, ",", fixed = TRUE)[[1]]); v[nzchar(v)] }

# ---- 1. read the file -----------------------------------------------------------------------
ELEMENT <- c("entity", "system", "component", "node", "behavior")          # what performs a function
fun <- data.frame(layer = character(0), name = character(0), owner = integer(0), line = integer(0), stringsAsFactors = FALSE)
blk <- data.frame(kind = character(0), name = character(0), ekind = character(0), parent = integer(0),
                  layer = character(0), stringsAsFactors = FALSE)           # every element block, by number
mops <- data.frame(layer = character(0), name = character(0), kind = character(0), chain = character(0),
                   band = logical(0), formula = character(0), refines = character(0), raci = character(0),
                   stringsAsFactors = FALSE)
par <- data.frame(layer = character(0), owner = character(0), name = character(0), value = character(0),
                  type = character(0), stringsAsFactors = FALSE)
exch <- data.frame(layer = character(0), from = character(0), to = character(0), stringsAsFactors = FALSE)
steps <- data.frame(layer = character(0), chain = character(0), name = character(0), stringsAsFactors = FALSE)
alloc <- data.frame(entity = integer(0), name = character(0), stringsAsFactors = FALSE)
deploy <- data.frame(node = integer(0), name = character(0), stringsAsFactors = FALSE)
n_chain <- n_comm <- n_iface <- n_item <- n_real <- n_formula <- n_reads <- 0L
LAYERS <- c("OA", "SA", "LA", "PA")
per <- lapply(c(chains = 0, links = 0, interfaces = 0, items = 0, realises = 0, formulas = 0), function(z) setNames(integer(4), LAYERS))
add <- function(kind, n = 1L) per[[kind]][layer] <<- per[[kind]][layer] + as.integer(n)   # one more, in the layer being read
layer <- ""; stack <- list()
top <- function(kinds) { for (k in rev(seq_along(stack))) if (stack[[k]]$kind %in% kinds) return(stack[[k]]); NULL }
el_of <- function() { e <- top(ELEMENT); if (is.null(e)) NA_integer_ else e$el }
EXCH_RX <- "^([A-Za-z_][A-Za-z0-9_]*)(\\s*\\[[^]]*\\])?\\s*->\\s*([A-Za-z_][A-Za-z0-9_]*)(\\s*\\[[^]]*\\])?\\s*:\\s*([A-Za-z_][A-Za-z0-9_]*)"

for (i in seq_along(tx)) {
  s <- trimws(tx[i])
  if (!nzchar(s) || startsWith(s, "#")) next
  if (s == "}") { stack[[length(stack)]] <- NULL; next }
  opens <- endsWith(s, "{")
  h <- trimws(sub("\\{$", "", s))
  w <- words(h); key <- w[1]
  in_measure <- !is.null(top(c("moe", "mop"))); in_decision <- !is.null(top("decision"))
  if (grepl(EXCH_RX, h, perl = TRUE) && !startsWith(h, "communication")) {          # A -> B : Name
    m <- regmatches(h, regexec(EXCH_RX, h, perl = TRUE))[[1]]
    exch[nrow(exch) + 1, ] <- list(layer, m[2], m[4])
    if (opens) stack[[length(stack) + 1]] <- list(kind = "exchange", name = m[6])
    next
  }
  if (opens) {
    b <- list(kind = key, name = if (length(w) > 1) w[2] else "")
    if (key == "layer") layer <- w[2]
    if (key %in% ELEMENT) {
      nm <- if (key == "system") "System" else w[2]
      ek <- if (key == "entity") (if (length(w) > 2 && w[3] == "human") "human" else "") else key
      blk[nrow(blk) + 1, ] <- list(key, nm, ek, el_of(), layer)
      b$el <- nrow(blk); b$name <- nm
    }
    if (key %in% c("function", "activity")) fun[nrow(fun) + 1, ] <- list(layer, w[2], el_of(), i)
    if (key == "chain") { n_chain <- n_chain + 1L; add("chains") }
    if (key %in% c("moe", "mop")) {
      ch <- top("chain")
      mops[nrow(mops) + 1, ] <- list(layer, w[2], toupper(key), if (is.null(ch)) NA else ch$name,
                                     grepl("\\[[^]]*\\.\\.[^]]*\\]", h, perl = TRUE), NA, NA, NA)
      b$mop <- nrow(mops)
    }
    if (key == "technique" && !is.null(top("function"))) {                        # a technique block: one computed value
      par[nrow(par) + 1, ] <- list(layer, top("function")$name, w[2], NA, "Computed")
      b$par <- nrow(par)
    }
    if (key == "communication") { n_comm <- n_comm + 1L; add("links") }
    if (key == "interface") { n_iface <- n_iface + 1L; add("interfaces") }
    stack[[length(stack) + 1]] <- b
    next
  }
  # a statement inside the innermost block
  inner <- if (length(stack)) stack[[length(stack)]] else list(kind = "")
  rest <- trimws(sub("^\\S+", "", s))
  if (key %in% c("function", "activity") && length(w) == 2) fun[nrow(fun) + 1, ] <- list(layer, w[2], el_of(), i)
  else if (key == "step" && inner$kind == "chain") steps[nrow(steps) + 1, ] <- list(layer, inner$name, w[2])
  else if (key == "realizes") { n_real <- n_real + length(names_in(rest)); add("realises", length(names_in(rest))) }
  else if (key == "formula") {
    n_formula <- n_formula + 1L; add("formulas")
    for (a in c("PN", "MOPV", "TECH", "LEVEL", "FVEC", "PVEC", "EVEC", "AVEC", "IVEC", "FSPAN", "FROLE", "FWHERE"))   # what a formula reads
      n_reads <- n_reads + length(gregexpr(paste0("\\b", a, "\\("), rest, perl = TRUE)[[1]][gregexpr(paste0("\\b", a, "\\("), rest, perl = TRUE)[[1]] > 0])
    if (!is.null(inner$mop)) mops$formula[inner$mop] <- rest
    if (!is.null(inner$par)) par$value[inner$par] <- rest
  }
  else if (key == "refines" && !is.null(inner$mop)) mops$refines[inner$mop] <- rest
  else if (key %in% c("accountable", "responsible", "consulted", "informed") && !is.null(inner$mop))
    mops$raci[inner$mop] <- paste(na.omit(c(mops$raci[inner$mop], s)), collapse = "; ")
  else if (key == "allocates" && !is.null(inner$el)) for (f in names_in(rest)) alloc[nrow(alloc) + 1, ] <- list(inner$el, f)
  else if (key == "deploys" && !is.null(inner$el)) for (f in names_in(rest)) deploy[nrow(deploy) + 1, ] <- list(inner$el, f)
  else if (key %in% c("event", "flow", "operation", "data") && inner$kind == "interface") { n_item <- n_item + 1L; add("items") }
  else if (grepl("^[A-Za-z_][A-Za-z0-9_]*\\s*=\\s*\\S", s, perl = TRUE) && !in_measure && !in_decision &&
           inner$kind %in% c(ELEMENT, "function", "activity", "chain", "exchange")) {    # k = v, a value written down
    par[nrow(par) + 1, ] <- list(layer, inner$name, sub("\\s*=.*$", "", s), trimws(sub("^[^=]*=", "", s)), "Value")
  }
}

# ---- 2. the counts Fig. 4 shows ---------------------------------------------------------------
# a port is not written: each function gets one out port if an exchange leaves it, one in port if one
# arrives, in SA, LA and PA (an OA activity has none)
dx <- exch[exch$layer != "OA", ]
ports <- nrow(unique(dx[, c("layer", "from")])) + nrow(unique(dx[, c("layer", "to")]))
# the performer of a function: the element block it is written in, or in OA the entity that allocates it
for (k in which(is.na(fun$owner))) {
  a <- alloc[alloc$name == fun$name[k] & blk$layer[alloc$entity] == fun$layer[k], ]
  if (nrow(a)) fun$owner[k] <- a$entity[1]
}
own <- fun$owner[!is.na(fun$owner)]
links_perf <- length(own)                                                    # who performs each function
is_kind <- nzchar(blk$ekind[own])                                             # its kind, unless non-human
is_in <- vapply(own, function(e) { p <- blk$parent[e]; !is.na(p) && blk$kind[p] != "system" }, FALSE)   # its group
links_kind <- sum(is_kind); links_in <- sum(is_in)
dep_host <- vapply(seq_along(own), function(k) {                             # a PA function's software, deployed on a node
  e <- own[k]; if (blk$kind[e] != "behavior") return(NA_integer_)
  d <- deploy$node[deploy$name == blk$name[e]]; if (length(d)) d[1] else NA_integer_ }, 0L)
is_dep <- !is.na(dep_host)
is_dep_in <- vapply(dep_host, function(d) !is.na(d) && !is.na(blk$parent[d]) && blk$kind[blk$parent[d]] != "system", FALSE)
links_dep <- sum(is_dep); links_dep_in <- sum(is_dep_in)
written <- nrow(par)
values <- written + links_perf + links_kind + links_in + links_dep + links_dep_in
oa_actors <- sum(blk$layer == "OA")
c4 <- list(actors = oa_actors, scenarios = n_chain, functions = nrow(fun), exchanges = nrow(exch),
           refines = sum(!is.na(mops$refines)), ports = ports, formulas = n_formula, realises = n_real,
           components = nrow(blk) - oa_actors, interfaces = n_iface, items = n_item, links = n_comm,
           measures = nrow(mops), values = values, raci = sum(!is.na(mops$raci)))
verdicts <- sum(mops$band)                                                    # a measure gets a verdict when it has a band

# the sensitivity sweep: each measure of SA, LA and PA moved in 4 steps each way, 9 points, and an edge
# to every measure the move reaches -- up its layer through MOPV, then across by `refines` to the
# measure of the layer above it stands for (when no measure of its layer reads it), up to SA
SWEEP <- c("PA", "LA", "SA")
readers <- function(lay, nm) {
  mo <- mops[mops$layer == lay, ]; f <- ifelse(is.na(mo$formula), "", mo$formula)
  hit <- mo$name != nm & (grepl(paste0("MOPV('", nm, "')"), f, fixed = TRUE) | grepl(paste0("MOPV(\"", nm, "\")"), f, fixed = TRUE))
  mo$name[hit]
}
up <- function(lay, nms) { seen <- character(0); front <- nms
  while (length(front)) { nx <- character(0)
    for (f in front) for (r in readers(lay, f)) if (!r %in% c(nms, seen)) { seen <- c(seen, r); nx <- c(nx, r) }
    front <- unique(nx) }
  seen }
stands_for <- function(lay, nm) {
  rf <- mops$refines[mops$layer == lay & mops$name == nm][1]
  if (is.na(rf) || length(readers(lay, nm))) return(NA_character_)
  trimws(strsplit(rf, ";", fixed = TRUE)[[1]][1])
}
reach <- function(lay, nm) {
  n <- 0L; at <- lay; starts <- nm
  repeat {
    dep <- up(at, starts); n <- n + length(dep)
    if (at == "SA") break
    nxt <- SWEEP[match(at, SWEEP) + 1]
    chain <- c(starts, dep); tops <- chain[vapply(chain, function(x) !length(readers(at, x)), FALSE)]
    sub <- unique(na.omit(vapply(tops, function(x) stands_for(at, x), "")))
    sub <- sub[sub %in% mops$name[mops$layer == nxt]]
    if (!length(sub)) break
    n <- n + length(sub); at <- nxt; starts <- sub
  }
  n
}
sweep_measures <- mops[mops$layer %in% SWEEP, ]
edges <- sum(mapply(reach, sweep_measures$layer, sweep_measures$name))
sweep_points <- edges * (2 * 4 + 1)

# ---- 3. the counts Table 4 shows: one selection per task, as a person assembles it by hand -------
# where each element is defined: its layer, kind and name, and the line
defs <- data.frame(layer = character(0), kind = character(0), name = character(0), line = integer(0), stringsAsFactors = FALSE)
lay <- ""
for (i in seq_along(tx)) {
  m <- regmatches(tx[i], regexec("^\\s*layer\\s+([A-Z]{2})\\s*\\{", tx[i], perl = TRUE))[[1]]
  if (length(m)) { lay <- m[2]; next }
  m <- regmatches(tx[i], regexec("^\\s*(component|node|behavior|function|activity|chain|mop|moe|scale|decision|entity)\\s+([A-Za-z_][A-Za-z0-9_]*)", tx[i], perl = TRUE))[[1]]
  if (length(m)) defs[nrow(defs) + 1, ] <- list(lay, m[2], m[3], i)
}
where <- function(l, nm) { d <- defs[defs$name == nm & (defs$layer == l | l == ""), ]; if (nrow(d)) d$line[1] else NA_integer_ }
grab <- function(rx, s) if (is.na(s)) character(0) else regmatches(s, gregexpr(rx, s, perl = TRUE))[[1]]
tag <- function(prefix, v) if (length(v)) paste0(prefix, v) else character(0)
tech <- par[par$type == "Computed", ]
# what one measure reads: its formula's values (PN), the measures (MOPV, LEVEL) and techniques (TECH) it
# calls, and in each technique the function's own values its formula names
trace <- function(m) {
  seen <- character(0); vals <- character(0); owners <- character(0); todo <- m
  while (length(todo)) {
    k <- todo[1]; todo <- todo[-1]
    if (k %in% seen) next
    seen <- c(seen, k)
    if (startsWith(k, "TECH:")) {
      fn <- sub("^TECH:", "", k); t <- tech[tech$owner == fn, ][1, ]
      mine <- par$name[par$owner == fn & par$type != "Computed"]
      used <- mine[vapply(mine, function(p) grepl(paste0("\\b", p, "\\b"), t$value, perl = TRUE), FALSE)]
      vals <- c(vals, paste0(fn, ".", used)); owners <- c(owners, fn)
      todo <- c(todo, tag("TECH:", grab("(?<=TECH\\(')[^']+", t$value)))
    } else {
      f <- mops$formula[mops$name == k][1]
      pn <- grab("PN\\('[^']+'\\s*,\\s*'[^']+'\\)", f)
      vals <- c(vals, gsub("PN\\('([^']+)'\\s*,\\s*'([^']+)'\\)", "\\1.\\2", pn, perl = TRUE))
      owners <- c(owners, gsub("PN\\('([^']+)'.*", "\\1", pn, perl = TRUE))
      todo <- c(todo, grab("(?<=MOPV\\(')[^']+", f), tag("TECH:", grab("(?<=TECH\\(')[^']+", f)), grab("(?<=LEVEL\\(')[^']+", f))
    }
  }
  list(values = unique(vals), formulas = seen, owners = unique(owners))
}
layer_of <- function(m) mops$layer[mops$name == m][1]
places_of <- function(tr, l) c(vapply(tr$formulas, function(k) if (startsWith(k, "TECH:")) where(l, sub("^TECH:", "", k)) else where(layer_of(k), k), 0L),
                               vapply(tr$owners, function(o) where(l, o), 0L))
SEL <- data.frame(task = character(0), selection = character(0), items = integer(0), places = integer(0),
                  apart = integer(0), formulas = integer(0), stringsAsFactors = FALSE)
row <- function(task, selection, items, lines, formulas) {
  lines <- sort(unique(lines[!is.na(lines)]))
  SEL[nrow(SEL) + 1, ] <<- list(task, selection, as.integer(items), length(lines), max(lines) - min(lines), as.integer(formulas))
}
need <- "Air_Raid_Defeated_Before_Reaching_The_Ship"
tr <- trace(need)                                                              # T1: the need, its scale, its LEVEL
sc <- sub("^\\s*scale\\s+(\\S+).*", "\\1", grep("^\\s*scale\\s", tx[where("OA", need) + 0:6], value = TRUE)[1])   # the need's own scale
row("T1", need, 3 + length(tr$values), c(where("OA", need), where("", sc), places_of(tr, "SA")), length(tr$formulas))
ch <- "Time_Critical_Sensor_To_Track"                                          # T2: one thread, its steps, exchanges, measures
st <- steps$name[steps$layer == "LA" & steps$chain == ch]
at <- where("LA", ch)
nex <- sum(grepl(paste0("^\\s*(", paste(st, collapse = "|"), ")\\s.*->"), tx[at:(at + 40)], perl = TRUE))
ms <- mops$name[!is.na(mops$chain) & mops$chain == ch]                      # its measures are items, so their definitions are places
row("T2", ch, length(st) + nex + length(ms), c(at, vapply(st, function(s) where("LA", s), 0L), vapply(ms, function(m) where("LA", m), 0L)), 0L)
kids <- function(m) unique(c(mops$name[!is.na(mops$refines) & mops$refines == m], grab("(?<=MOPV\\(')[^']+", mops$formula[mops$name == m][1])))
tree <- need; todo <- need                                                     # T3: the need's tree of measures
while (length(todo)) { k <- todo[1]; todo <- todo[-1]; nk <- setdiff(kids(k), tree); tree <- c(tree, nk); todo <- c(todo, nk) }
# T3 asks only whether each measure is linked, which reads names, so it counts no formula (8p, 23 October 2026)
row("T3", paste(need, "tree"), length(tree), vapply(tree, function(m) where(layer_of(m), m), 0L), 0L)
fn <- "Fuse_Tracks"                                                            # T4: a technique to the PA part that runs it
pa_fn <- defs$name[defs$layer == "PA" & defs$kind == "function" & vapply(defs$line, function(l) any(grepl(paste0("realizes\\s+", fn, "\\b"), tx[l:min(length(tx), l + 3)], perl = TRUE)), FALSE)][1]
beh <- { l <- where("PA", pa_fn); b <- defs[defs$layer == "PA" & defs$kind == "behavior" & defs$line < l, ]; b$name[nrow(b)] }
node <- { d <- grep(paste0("deploys\\s+.*\\b", beh, "\\b"), tx, perl = TRUE); n <- defs[defs$layer == "PA" & defs$kind == "node" & defs$line < d[1], ]; n$name[nrow(n)] }
row("T4", paste(fn, "->", pa_fn, "on", beh, "on", node), 5, c(where("LA", fn), where("PA", pa_fn), where("PA", beh), where("PA", node)), 1L)
tops <- c(); k <- need                                                         # T5: the need's trace, a top measure a layer
repeat { nx <- mops$name[!is.na(mops$refines) & mops$refines == k]; if (!length(nx)) break; tops <- c(tops, nx[1]); k <- nx[1] }
trs <- lapply(tops, trace)
row("T5", paste(c(need, tops), collapse = " > "), 1 + length(tops) + length(unique(unlist(lapply(trs, `[[`, "values")))),
    c(where("OA", need), unlist(Map(function(t, m) places_of(t, layer_of(m)), trs, tops))), length(unique(unlist(lapply(trs, `[[`, "formulas")))))
m6 <- "Fusion_Processor_Detect_To_Advice_Time_s"; t6 <- trace(m6)                              # T6: what a failing measure reads
row("T6", m6, length(t6$values), places_of(t6, "PA"), length(t6$formulas))
alt <- "Fuse_IMM_PDAF_Track.fusion_nodes"                                      # T7: one alternative, as a what-if
pa_m <- mops$name[mops$layer == "PA" & mops$kind == "MOP"]
moved <- pa_m[vapply(pa_m, function(m) alt %in% trace(m)$values, FALSE)]
trs <- lapply(moved, trace)                                                   # the values the moved formulas read are items too
redo <- length(unique(unlist(lapply(trs, function(t) t$formulas))))
row("T7", sprintf("%s changed: moves %d PA measures", alt, length(moved)), length(unique(c(alt, moved, unlist(lapply(trs, function(t) t$values))))),
    c(where("PA", "Fuse_IMM_PDAF_Track"), vapply(moved, function(m) where("PA", m), 0L), unlist(lapply(trs, places_of, "PA"))), redo)
who <- "Tactical_Action_Officer"                                               # T8: every measure that names one stakeholder
mine <- mops$name[grepl(paste0("\\b", who, "\\b"), ifelse(is.na(mops$raci), "", mops$raci), perl = TRUE)]
row("T8", who, length(mine), vapply(mine, function(m) where(layer_of(m), m), 0L), 0L)

# ---- 4. the counts Table 1 shows: what the model holds, in the DSL and in Capella ---------------
# The import writes one Capella element for each construct of the DSL, so most of the Capella column
# follows from the DSL by that rule. Two numbers do not: the property values and all model elements are
# counted in the Capella model itself (validation/capella_stats.py), which this script does not read.
# a chain involves each of its steps, and each exchange of its layer that runs forward from one of its steps
# to a later one, written inside the chain or not; a feedback exchange, back to an earlier step, is not involved
involvements <- 0L
for (key in unique(paste(steps$layer, steps$chain))) {
  st <- steps$name[paste(steps$layer, steps$chain) == key]; lay <- sub(" .*", "", key)
  ex <- exch[exch$layer == lay & exch$from %in% st & exch$to %in% st, ]
  involvements <- involvements + length(st) + sum(match(ex$from, st) < match(ex$to, st))
}
t1 <- list(
  c("Functions and activities", fmt(c4$functions), fmt(c4$functions)),
  c("Functional exchanges", fmt(c4$exchanges), fmt(c4$exchanges)),
  c("Ports of the functions", fmt(c4$ports), fmt(c4$ports)),
  c("Chains", fmt(c4$scenarios), sprintf("%s with %s involvements", fmt(c4$scenarios), fmt(involvements))),
  c("Entities, components and parts", fmt(nrow(blk)), fmt(nrow(blk))),
  c("Interfaces", fmt(c4$interfaces), fmt(c4$interfaces)),
  c("Exchange items", fmt(c4$items), fmt(c4$items)),
  c("Values of parameters", fmt(c4$values), "property values: counted in the Capella file"),
  c("Formulas of measures and techniques", fmt(c4$formulas), sprintf("%s constraints with an expression", fmt(nrow(mops) + nrow(tech)))),
  c("Reads of other elements in formulas", fmt(n_reads), "none: text inside the expressions"),
  c("Realisation links between layers", fmt(c4$realises), fmt(c4$realises)),
  c("Measures with a band", fmt(verdicts), sprintf("%s constraints with min and max", fmt(verdicts))),
  c("Top measures that refine the layer above", fmt(c4$refines), sprintf("%s refines values", fmt(c4$refines))),
  c("All model elements", "", "counted in the Capella file"))

# ---- 5. the counts the sorted chart shows: every kind the model holds, layer by layer -------------
# the same rules as above, kept apart by the layer in which each item is written; a link kept as a value
# belongs to the layer of the function it is about, a port to the layer of its function
by <- function(x) vapply(LAYERS, function(l) sum(x == l), 0L)
fl <- fun$layer[!is.na(fun$owner)]                                           # the layer of each performed function
port_by <- vapply(LAYERS, function(l) { d <- dx[dx$layer == l, ]
  nrow(unique(d[, "from", drop = FALSE])) + nrow(unique(d[, "to", drop = FALSE])) }, 0L)
chart <- list(
  list("Parameter values", by(par$layer) + by(fl) + by(fl[is_kind]) + by(fl[is_in]) + by(fl[is_dep]) + by(fl[is_dep_in])),
  list("Function ports", port_by),
  list("Realisation links", per$realises),
  list("Functional exchanges", by(exch$layer)),
  list("Exchange items", per$items),
  list("Interfaces", per$interfaces),
  list("Component exchanges and links", per$links),
  list("Functions and activities", by(fun$layer)),
  list("Entities, components and parts", by(blk$layer)),
  list("Formulas", per$formulas),
  list("Measures (MOE and MOP)", by(mops$layer)),
  list("RACI lines", by(mops$layer[!is.na(mops$raci)])),
  list("Chains, each a ConOps scenario", per$chains),
  list("Refines links", by(mops$layer[!is.na(mops$refines)])))
chart <- chart[order(-vapply(chart, function(r) sum(r[[2]]), 0L))]
# each row must add up to the total the figure's views count above: one rule, two cuts
stopifnot(sum(chart[[which(vapply(chart, `[[`, "", 1) == "Parameter values")]][[2]]) == values,
          sum(port_by) == ports, sum(per$realises) == n_real, sum(per$formulas) == n_formula,
          sum(per$items) == n_item, sum(per$interfaces) == n_iface, sum(per$links) == n_comm, sum(per$chains) == n_chain)

# ---- 6. report -----------------------------------------------------------------------------
cat(sprintf("%s\n%s lines\n\n", args[1], fmt(length(tx))))
cat("THE MODEL'S SIZE in the 8p's Section 4, Table 1 in 27p, Table 2 in maxp -- what the model holds: the DSL, and the Capella model by the import's one-element rule\n\n")
cat(sprintf("  %-42s %6s   %s\n", "Item in the model", "DSL", "Capella model"))
for (r in t1) cat(sprintf("  %-42s %6s   %s\n", r[1], r[2], r[3]))
cat("\n")
cat("TABLE 2 in 8p, Table 5 in 27p, Table 17 in maxp -- one selection per task, what a person does by hand in the DSL\n\n")
cat(sprintf("  %-4s %6s %7s %13s %9s   %s\n", "Task", "Items", "Places", "Lines apart", "Formulas", "Selection"))
for (k in seq_len(nrow(SEL))) { s <- SEL[k, ]
  cat(sprintf("  %-4s %6d %7d %13s %9d   %s\n", s$task, s$items, s$places, fmt(s$apart), s$formulas, s$selection)) }
cat(sprintf("\n  Places range from %d to %d, over up to %s of the %s lines; up to %d formulas.\n",
            min(SEL$places), max(SEL$places), fmt(max(SEL$apart)), fmt(length(tx)), max(SEL$formulas)))
cat(sprintf("  %d of the %d selections hold more than five items; the largest holds %d.\n", sum(SEL$items > 5), nrow(SEL), max(SEL$items)))

views <- list(
  list("ConOps", "T1 T2", c(actors = c4$actors, scenarios = c4$scenarios)),
  list("Mission Thread", "T2 T3", c(functions = c4$functions, exchanges = c4$exchanges, refines = c4$refines)),
  list("DSL editor", "T3", c(ports = c4$ports, formulas = c4$formulas)),
  list("Math Functions", "T3", c()),
  list("Matrix", "T4", c("realisation links" = c4$realises)),
  list("Boundary", "T4", c("components and parts" = c4$components)),
  list("Interfaces", "T4", c(interfaces = c4$interfaces, items = c4$items, links = c4$links)),
  list("TPM chart", "T5", c(measures = c4$measures)),
  list("Sensitivity", "T6", c()),
  list("Missions", "T6 T7", c(values = c4$values)),
  list("RACI", "T8", c("RACI lines" = c4$raci)))
cat("\nFIG. 19 in 8p, Fig. 20 in 27p, Fig. 24 in maxp -- what each view puts in front of the team (each kind at the first view that shows it)\n\n")
total <- 0
for (k in seq_along(views)) { v <- views[[k]]
  say <- if (length(v[[3]])) paste(sprintf("%s %s", fmt(v[[3]]), names(v[[3]])), collapse = ", ") else ""
  if (v[[1]] == "TPM chart") say <- sprintf("%s, %d verdicts", say, verdicts)
  if (v[[1]] == "Sensitivity") say <- sprintf("computes %d sweep points", sweep_points)
  cat(sprintf("  %2d %-15s %-6s %s\n", k, v[[1]], v[[2]], say)); total <- total + sum(v[[3]]) }
cat(sprintf("\n  Items in view: %s.\n", fmt(total)))
cat(sprintf("  Values: %s = %s written (%s as k = v, %s technique results) + %s links kept as values:\n",
            fmt(values), fmt(written), fmt(sum(par$type == "Value")), fmt(sum(par$type == "Computed")),
            fmt(values - written)))
cat(sprintf("          %s performers, %s performer kinds, %s enclosing groups, %s deployments, %s deployment hosts.\n",
            fmt(links_perf), fmt(links_kind), fmt(links_in), fmt(links_dep), fmt(links_dep_in)))
cat(sprintf("  Verdicts: %d of %d measures have a band (%d MOP, %d MOE).\n", verdicts, nrow(mops),
            sum(mops$band & mops$kind == "MOP"), sum(mops$band & mops$kind == "MOE")))
cat(sprintf("  Sweep: %d edges x 9 points (4 steps each way and the value itself) = %d points.\n", edges, sweep_points))

cat("\nTHE SORTED CHART of Fig. 21 in 8p, Fig. 20 in 27p, Fig. 24 in maxp -- every kind the DSL example models, layer by layer\n\n")
cat(sprintf("  %-32s %6s %6s %6s %6s %7s\n", "Kind", "OA", "SA", "LA", "PA", "Total"))
for (r in chart) cat(sprintf("  %-32s %6s %6s %6s %6s %7s\n", r[[1]], fmt(r[[2]][1]), fmt(r[[2]][2]), fmt(r[[2]][3]), fmt(r[[2]][4]), fmt(sum(r[[2]]))))
cat(sprintf("\n  All items: %s over four layers.\n", fmt(sum(vapply(chart, function(r) sum(r[[2]]), 0L)))))
