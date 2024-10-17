## -----------------------------------------------------------------------------
##
## [ PROJ ] Spatial
## [ FILE ] make_maps.R
## [ AUTH ] Benjamin Skinner; bskinner@neh.gov
## [ INIT ] 17 October 2024
##
## -----------------------------------------------------------------------------

## h/t https://pastebin.com/P7CrXugY for basis of code

## libraries
libs <- c("tidyverse", "sf", "sp")
sapply(libs, require, character.only = TRUE)

## paths
args <- commandArgs(trailingOnly = TRUE)
root <- ifelse(length(args) == 0, file.path(".."), args)
dat_dir <- file.path(root, "data")
map_dir <- file.path(root, "map_data")
scr_dir <- file.path(root, "scripts")

## -------------------------------------
## macros
## -------------------------------------

## levels
geolevel <- c("state", "county")

## projection
albers <- "ESRI:102003"

## adjustment table for states / territories to move
ak <- list(stfips = "02",
           rotate = -50,
           scale = 1.8,
           shift_x = -2400000,
           shift_y = -2800000
           )
hi <- list(stfips = "15",
           rotate = -35,
           scale = NULL,
           shift_x = 5800000,
           shift_y = -1900000
           )
as <- list(stfips = "60",
           rotate = -55,
           scale = 0.25,
           shift_x = -2300000,
           shift_y = -3400000
           )
gu <- list(stfips = "66",
           rotate = -65,
           scale = 0.15,
           shift_x = 1200000,
           shift_y = -3200000
           )
nm <- list(stfips = "69",
           rotate = -55,
           scale = 0.85,
           shift_x = 300000,
           shift_y = -3400000
           )
pr <- list(stfips = "72",
           rotate = 13,
           scale = 0.5,
           shift_x = 600000,
           shift_y = -2600000
           )
vi <- list(stfips = "78",
           rotate = 13,
           scale = 0.25,
           shift_x = 1500000,
           shift_y = -2600000
           )

## put together
non_con_us <- list(ak, hi, as, gu, nm, pr, vi) |>
  bind_rows()

## -------------------------------------
## functions
## -------------------------------------

adjust_geo <- function(sp_obj, stfips, rotate = NULL, scale = NULL,
                       shift_x = NULL, shift_y = NULL, match_proj = NULL) {
  ## subset
  subgeo <- sp_obj[sp_obj[["statefp"]] == stfips,]
  ## rotate
  if (!is.na(rotate)) {
    subgeo <- subgeo |>
      elide(rotate = rotate)
  }
  ## scale
  if (!is.na(scale)) {
    subgeo <- subgeo |>
      elide(scale = max(apply(bbox(subgeo), 1, diff)) / scale)
  }
  ## shift
  if (!is.na(shift_x) & !is.na(shift_y)) {
    subgeo <- subgeo |>
      elide(shift = c(shift_x, shift_y))
  }
  ## project
  proj4string(subgeo) <- proj4string(sp_obj)
  ## return
  subgeo
}

## -----------------------------------------------------------------------------
## read in data
## -----------------------------------------------------------------------------

## read in state and county maps
maps <- map(geolevel,
            ~ read_sf(file.path(dat_dir, paste0("cb_2023_us_", .x, "_5m"))) |>
              rename_all(tolower) |>
              select(-starts_with("a"), -ends_with("ns"),
                     -any_of(c("countyfp", "lsad", "geoidfq"))) |>
              st_transform(crs = albers) |>
              as(Class = "Spatial")) |>
  set_names(geolevel)

## -----------------------------------------------------------------------------
## adjust non-contiguous state / territories
## -----------------------------------------------------------------------------

## states
non_con_st <- map(non_con_us |> pull(stfips),
                  ~ {
                    dat <- non_con_us |> filter(stfips == .x)
                    adjust_geo(maps[["state"]],
                               stfips = .x,
                               rotate = dat[["rotate"]],
                               scale = dat[["scale"]],
                               shift_x = dat[["shift_x"]],
                               shift_y = dat[["shift_y"]])
                  })

## counties
non_con_ct <- map(non_con_us |> pull(stfips),
                  ~ {
                    dat <- non_con_us |> filter(stfips == .x)
                    adjust_geo(maps[["county"]],
                               stfips = .x,
                               rotate = dat[["rotate"]],
                               scale = dat[["scale"]],
                               shift_x = dat[["shift_x"]],
                               shift_y = dat[["shift_y"]])
                  })

non_con <- list("state" = non_con_st,
                "county" = non_con_ct)

## -----------------------------------------------------------------------------
## bind together
## -----------------------------------------------------------------------------

map_adj <- map(geolevel,
               ~ rbind(maps[[.x]][!maps[[.x]][["statefp"]] %in% pull(non_con_us, stfips),],
                       do.call("rbind", non_con[[.x]])) |>
                 st_as_sf()) |>
  set_names(geolevel)

## -----------------------------------------------------------------------------
## save
## -----------------------------------------------------------------------------

walk(c("state","county"),
     ~ st_write(map_adj[[.x]],
                dsn = file.path(map_dir, paste0(.x, "_5m.geojson")),
                layer = paste0(.x, "_5m.geojson"),
                driver = "geojson",
                delete_dsn = TRUE,
                delete_layer = TRUE))

## -----------------------------------------------------------------------------
## end script
################################################################################
