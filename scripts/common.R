# scripts/common.R
# Acest fisier configureaza calea catre libraria locala "r_libs"
# Este folosit de toate celalalte scripturi pentru a gasi pachetele instalate.

# Asigura-te ca working directory este radacina proiectului cand rulezi scripturile.
local_lib <- file.path(getwd(), "r_libs")

if (!dir.exists(local_lib)) {
  # Incercam sa vedem daca suntem in folderul scripts
  if (dir.exists("../r_libs")) {
      local_lib <- file.path(getwd(), "../r_libs")
  } else {
      warning("Folderul r_libs nu a fost gasit. Asigura-te ca ai rulat 00_setup.R din radacina proiectului.")
  }
}

if (dir.exists(local_lib)) {
    .libPaths(c(local_lib, .libPaths()))
    # message(paste("Librariile sunt incarcate din:", local_lib))
}
