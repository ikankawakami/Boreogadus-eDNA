# activate required packages

library(tidyverse)
library(vegan)
library(clustsig)
library(factoextra)
library(ggsci)
library(cowplot)
theme_set(theme_cowplot(12))

# eDNA results and environmental data can be downloaded from the Arctic Data archive System (ADS) managed by the National Institute of Polar Research, Japan, under the accession number A20230323-002 (https://ads.nipr.ac.jp/dataset/A20230323-002).

# import result file

result <- read_csv("./Boreogadus_eDNA_data.csv")

# make a tibble for clustering and PCA

Env <- result %>% 
  select(site = Site_name, 
         latitude = `Latitude_(degree)`, 
         longitude = `Longitude_(degree)`, 
         wt = `Water_temperature_(°C)`, 
         sal = Salinity, 
         chl = `Chlorophyll_a_flurescence_(RFU)`, 
         topo = Topology, 
         sampling_depth = `Sampling_depth_(m)`,
         bottom_depth = `Bottom_depth_(m)`, 
         distance_to_ice = `Distance_to_sea_ice_edge_(km)`
  ) %>% 
  mutate(longitude = if_else(longitude < 0, longitude + 360, longitude))

# perform simprof

tmp <- Env %>% 
  filter(sampling_depth == 4.5) %>% 
  mutate(log_chl = log(chl)) %>%
  select(site, wt, sal, log_chl) %>% 
  data.frame(row.names = "site") %>% 
  decostand(method = "standardize")

res <- simprof(data = tmp,
               method.cluster = "ward.D2", 
               method.distance = function(x){vegdist(x, method = "euclidean")}, 
               method.transform = "identity")

# see simprof result

simprof.plot(res)

# edit dendrogram

lat <- Env %>% 
  select(site, latitude)

hc <- res$hclust
hc_reordered <- with(lat, reorder(hc, latitude))

res$hclust <- hc_reordered
simprof.plot(res)

res$significantclusters <- res$significantclusters[c(1,2,5,4,3)]

# export dendrogram

pdf(file = "./Env_clustered.pdf", width = 7, height = 5)
simprof.plot(res, leafcolors = pal_nejm(palette = c("default"), alpha = 1)(5))
dev.off()

# plot simprof result

sitename <- cbind(unlist(res$significantclusters)) # クラスタリング結果を抽出
clustername <- rep(1:length(res$significantclusters), unlist(lapply(res$significantclusters, length)))
cluster_res <- bind_cols(site = sitename, cluster = clustername)    

Env_clustered <- Env %>% 
  inner_join(cluster_res, by = "site") %>% 
  arrange(latitude)

n_clusters <- max(Env_clustered$cluster)

shapes <- c(16, 17, 15, 3, 7)

p <- Env_clustered %>%
  mutate(cluster = as_factor(cluster)) %>% 
  ggplot(aes(x = longitude, y = latitude, color = cluster, shape = cluster)) +
  geom_point(size = 3) +
  scale_shape_manual(values = shapes) +
  scale_color_nejm()

ggsave(file = "./Env_clustered_plot.pdf", p)

# summarize environmental data for each cluster

Env_clustered_summary <- Env_clustered %>% 
  group_by(cluster) %>% 
  summarise(n = length(cluster),
            wt_mean = mean(wt), wt_sd = sd(wt),
            sal_mean = mean(sal), sal_sd = sd(sal),
            chl_mean = mean(chl), chl_sd = sd(chl),
            depth_mean = mean(bottom_depth), depth_sd = sd(bottom_depth),
            distance_to_ice_mean = mean(distance_to_ice), distance_to_ice_sd = sd(distance_to_ice)
  )

write_csv(Env_clustered_summary, "./Env_clustered_summary.csv")

# plot PCA ordination

tmp <- Env_clustered %>% 
  mutate(log_chl = log(chl)) %>%  # log-transformed chl a is used for classification
  select(site, wt, sal, log_chl) %>% 
  data.frame(row.names = "site") %>% 
  decostand(method = "standardize")

pr_res <- prcomp(tmp)

p <- fviz_pca_biplot(pr_res,
                     geom = "point",
                     habillage = Env_clustered$cluster,
                     addEllipses = TRUE,
                     ellipse.type = "norm",
                     ellipse.level = 0.95,
                     palette = pal_nejm(palette = c("default"), alpha = 1)(n_clusters),
                     invisible = "quali", 
                     pointsize = 2,
                     col.var = "grey60",
                     title = "PCA-Biplot for Env_clustered"
)

save_plot("./Env_clustered_pca_biplot.pdf", p, base_height = 4, base_width = 5)

# make a map of eDNA sampling sites based on water mass classification
# This map was plotted by GMT5.4.5 using following script.

## make a data file

Coordinates_clustered_for_gmt <- Env_clustered %>% 
  filter(!is.na(cluster)) %>% 
  mutate(format = "TC 0.0 6p,Helvetica,0/0/0") %>% 
  mutate(site = as.character(site)) %>% # avoid unknown error
  select(longitude, latitude, format, site, cluster)

write_tsv(Coordinates_clustered_for_gmt, "./Coordinates_clustered_for_gmt.txt", col_names = FALSE)

## make figure legend

l <- c("N 1",
       "S 0.5c c 0c 0/0/0 0p 0.1c Water mass",
       "G 0.1",
       "S 0.5c c 0.3 #BC3C29FF thin,white 1.2c 1",
       "S 0.5c t 0.42 #0072B5FF thin,white 1.2c 2",
       "S 0.5c s 0.4 #E18727FF thin,white 1.2c 3",
       "S 0.5c + 0.35 white thick,#20854EFF 1.2c 4",
       "S 0.5c s 0.35 white thick,#7876B1FF 1.2c 5",
       "G -0.46",
       "S 0.5c x 0.35 white thick,#7876B1FF 1.2c"
)
write(l, "./Map_clustered_sites_legend.txt")

## execute following script in GMT5.4.5

# #!/usr/bin/env bash
#
# region=169/47/-125/76r
# proj=S-170/90/11c
# grdfile=gebco.nc # netCDF file
# psfile=./Map_clustered_sites.eps
# xyfile=./Coordinates_clustered_for_gmt.txt
# legendfile=./Map_clustered_legend.txt
# cptfile=./topocol.cpt
# 
# gmt set MAP_ANNOT_OBLIQUE 30
# gmt set FORMAT_GEO_MAP F
# gmt set MAP_DEGREE_SYMBOL degree
# gmt set MAP_GRID_PEN_PRIMARY thinnest,gray20
# 
# gmt makecpt -Cgebco > $cptfile
# 
# gmt psbasemap -R$region -J$proj -Ba0f0g0 -X5c -Y10c -P -K > $psfile
# gmt grdimage $grdfile -R -JS -E100 -C$cptfile -K -O >> $psfile
# gmt pscoast -R -JS -Di -A250/0/1 -Ba10f10g10 -BWSne -Ggrey80 -W1 -K -O >> $psfile
# awk '$7==1 {print $0}' $xyfile |
# gmt psxy -i0,1 -R -JS -Sc0.3 -G#BC3C29FF -Wthin,white -K -O >> $psfile
# awk '$7==2 {print $0}' $xyfile |
# gmt psxy -i0,1 -R -JS -St0.42 -G#0072B5FF -Wthin,white -K -O >> $psfile
# awk '$7==3 {print $0}' $xyfile |
# gmt psxy -i0,1 -R -JS -Ss0.4 -G#E18727FF -Wthin,white -K -O >> $psfile
# awk '$7==4 {print $0}' $xyfile |
# gmt psxy -i0,1 -R -JS -S+0.35 -Gwhite -Wthick,#20854EFF -K -O >> $psfile
# awk '$7==5 {print $0}' $xyfile |
# gmt psxy -i0,1 -R -JS -Ss0.35 -Gwhite -Wthick,#7876B1FF -K -O >> $psfile
# awk '$7==5 {print $0}' $xyfile |
# gmt psxy -i0,1 -R -JS -Sx0.35 -Gwhite -Wthick,#7876B1FF -K -O >> $psfile
# gmt pslegend $legendfile -R -JS -Dn1.28/0+w2.6c/3.2c+jBR -F+pblack+gwhite -K -O >> $psfile
# gmt psscale -R -JS -Dn1.08/0.5+w6c/0.4c+jBR+v -C$cptfile -L -O >> $psfile
# 
# rm -f ./gmt.conf
# rm -f ./gmt.history