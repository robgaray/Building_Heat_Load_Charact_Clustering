normalize_min_max <- function(x) {
  if(is.numeric(x)) {
    return((x - min(x)) / (max(x) - min(x)))
  } else {
    return(x)  # Devolver la columna tal cual si no es numérica
  }
}