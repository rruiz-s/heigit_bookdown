lapply(c("tidyverse","DT","leaflet","sf","DBI", "RPostgres","dplyr", "mapview","leafpop","leaflet","leafsync","terra","raster","stars", "lwgeom","leaflet.extras2","RColorBrewer","tidygeocoder"),
       require,
       character.only =T)


## Pre-flooding
centrality_post <- st_read(eisenberg_connection,centrality_post_data )
centrality_post_data <- DBI::Id(schema= "rs",table="centrality_weighted_100_bidirect_cleaned_post")
## Post-looding
centrality_pre_data <- DBI::Id(schema= "rs",table="centrality_weighted_100_bidirect_cleaned")
centrality_pre <- st_read(eisenberg_connection, centrality_pre_data)
flooding <- sf::st_read("~/heigit_bookdown/data/flooding_porto.geojson") 
## weightings points
weighting_destination_data <- DBI::Id(schema="rs",table="weight_sampling_100_destination")
weighting_origin_data <- DBI::Id(schema="rs",table="weight_sampling_100_origin")
regular_point_data <- DBI::Id(schema="rs", table="regular_point_od")
## hospitals
poi_hospital <- st_read(eisenberg_connection,"hospital_rs_node_v2")

weighting_destination <-  st_read(eisenberg_connection, weighting_destination_data)
weighting_origin <- st_read(eisenberg_connection, weighting_origin_data)
weighting_destination$sample <- "destination"
weighting_origin$sample <- "origin"
regular_point <- st_read(eisenberg_connection, regular_point_data)
weighted_sampling <-  bind_rows(weighting_origin,weighting_destination)
## Visualization
pal <- mapview::mapviewPalette("mapviewTopoColors")
mapview(ghs_build[[1]],
        layer.name ="Built-up volume",
        col.regions = pal(100),
        alpha.regions= 0.45,
        hide=TRUE) +
  mapview(ghs_smod[[1]],
          layer.name = "Settlement classification",
          col.regions = pal(100),
          alpha.regions= 0.35,
          legend= FALSE,
          hide=TRUE) +
  mapview(weighted_sampling,
          layer.name="Weighted samples",
          zcol="sample",
          col.regions=c("#2D5CA4","#00A3A0"),
          hide=FALSE,
          cex= 3) +
  mapview(regular_point,
          color = "darkgray",
          col.regions="darkgray",
          cex= 3,
          legend= FALSE,
          hide=TRUE) +
  mapview(subset(poi_hospital,
                 select=c("cd_cnes",
                          "ds_cnes",
                          "id",
                          "geom_hospital")),
          layer.name = "POI - Hospitals",
          color= "darkred",
          legend = FALSE,
          col.regions="#CA2334",
          popup=popupTable(poi_hospital, zcol=c("cd_cnes","ds_cnes","id"))) +
  mapview(flooding,
          color="darkblue",
          alpha.regions= 0.5,
          hide =TRUE,
          legend =FALSE,
          layer.name="Flooding layer") +
  mapview::mapview(centrality_post,
                   lwd = 0.2,
                   color="#cb2a32",
                   hide = TRUE,
                   legend = FALSE,
                   layer.name ="Post-flooding centrality network") +
  mapview::mapview(centrality_pre,
                   color = "#00a4a4",
                   lwd= 0.2,
                   hide=TRUE,
                   layer.name ="Pre-flooding centrality network") 
### natural breaks
#### For pre-event: 1644, 468, 142
centrality_pre$centrality_fct <- cut(centrality_pre$centrality,
                                     breaks=c(0,142,468,1644),
                                     labels =c("low","medium","high"),
                                     include.lowest= TRUE,
                                     right =FALSE)
#### natural breaks:  81, 230, 582
centrality_post$centrality_fct <- cut(centrality_post$centrality,
                                      breaks=c(0,142,468,1644),
                                      labels =c("low","medium","high"),
                                      include.lowest= TRUE,
                                      right =FALSE)
### 
centrality_pre_map <- mapview::mapview(centrality_pre,
                                       zcol="centrality_fct",
                                       map.type="OpenStreetMap",
                                       lwd ="centrality",
                                       layer.name ="Centrality Pre-Event",
                                       popup=popupTable(centrality_pre, 
                                                        zcol=c("id","centrality","bidirectid"))) 
centrality_post_map <- mapview::mapview(centrality_post,
                                        zcol="centrality_fct",
                                        map.type="OpenStreetMap",
                                        lwd = "centrality",
                                        layer.name ="Centrality Post-Event",
                                        popup=popupTable(centrality_post, 
                                                         zcol=c("id","centrality","bidirectid"))) 
ghs_build <- stack("/home/ricardo/heigit_bookdown/data/GHS_BUILT_V_E2020_GLOBE_R2023A_4326_100_V1_0_RioGrandeDoSul.tif")
ghs_smod <- stack("/home/ricardo/heigit_bookdown/data/GHS_SMOD_E2020_GLOBE_R2023A_4326_1000_V2_0_RioGrandeDoSul.tif")

centrality_pre_map | centrality_post_map + mapview(flooding,
                                                   color="darkblue",
                                                   alpha.regions= 0.5,
                                                   layer.name="Flooding layer") 
###