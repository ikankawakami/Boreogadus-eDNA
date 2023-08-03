# activate required packages

library(tidyverse)
library(cowplot)
theme_set(theme_cowplot(12))

# eDNA results and environmental data can be downloaded from the Arctic Data archive System (ADS) managed by the National Institute of Polar Research, Japan, under the accession number A20230323-002 (https://ads.nipr.ac.jp/dataset/A20230323-002).

# import result file

result <- read_csv("./Boreogadus_eDNA_data.csv")

# make a tibble for eDNA analysis

eDNA_result <- result %>% 
  select(site = Site_name, 
         latitude = `Latitude_(degree)`, 
         longitude = `Longitude_(degree)`, 
         wt = `Water_temperature_(°C)`, 
         sal = Salinity, 
         chl = `Chlorophyll_a_flurescence_(RFU)`, 
         topo = Topology, 
         sampling_depth = `Sampling_depth_(m)`,
         cluster = Water_mass_classification,
         bottom_depth = `Bottom_depth_(m)`, 
         distance_to_ice = `Distance_to_sea_ice_edge_(km)`,
         quantity = `Quantity_of_polar_cod_eDNA_(copies/reaction)`,
         concentration = `Concentration_of_polar_cod_eDNA_in_seawater_(copies/L)`
  ) %>% 
  mutate(longitude = if_else(longitude < 0, longitude + 360, longitude)) %>% 
  mutate(presence = if_else(quantity > 0, 1, 0))

# summarise eDNA result

eDNA_result_summary <- eDNA_result %>% 
  filter(!is.na(cluster)) %>% 
  group_by(cluster) %>% 
  summarise(n_site = length(concentration), 
            n_detected = sum(presence), 
            detection = round(n_detected/n_site*100, 1), 
            mean = mean(concentration), 
            sd = sd(concentration), 
            wt_mean = mean(wt),
            wt_sd = sd(wt),
            sal_mean = mean(sal),
            sal_sd = sd(sal),
            chl_mean = mean(chl),
            chl_sd = sd(chl),
            depth_mean = mean(bottom_depth),
            depth_sd = sd(bottom_depth),
            dist_mean = mean(distance_to_ice),
            dist_sd = sd(distance_to_ice)
  )

write_csv(eDNA_result_summary, "./eDNA_result_summary.csv")

# compare environmental condition between sites where polar cod eDNA was detected and not detected

tmp <- eDNA_result %>% 
  filter(sampling_depth == 4.5) %>% 
  mutate(presence = if_else(presence == 1, "detected", "not_detected")) %>% 
  mutate(presence = factor(presence))

# wilcoxon rank sum test
sink("./Comparison_between_pa.txt")
print("water temperature")
bartlett.test(tmp$wt, tmp$presence)
wilcox.test(data = tmp, wt~presence)
print("salinity")
bartlett.test(tmp$sal, tmp$presence)
wilcox.test(data = tmp, sal~presence)
sink()

# make boxplot

p_wt <- tmp %>% 
  ggplot(aes(x = factor(presence), y = wt)) +
  geom_boxplot() +
  scale_y_continuous(limits = c(-2,12.5), name = "Water temperature (°C)", breaks = seq(-2,12,2))+
  geom_segment(x = 1, y = 10.5, xend = 2, yend = 10.5, linewidth = 0.5) +
  geom_segment(x = 1, y = 10.5, xend = 1, yend = 10, linewidth = 0.5) +
  geom_segment(x = 2, y = 10.5, xend = 2, yend = 10, linewidth = 0.5) +
  annotate("text", x = 1.5, y = 11.5, label = "*", size = 8) +
  scale_x_discrete(name = "", labels = c("Detected", "Not detected"))

p_sal <- tmp %>% 
  ggplot(aes(x = factor(presence), y = sal)) +
  geom_boxplot() +
  scale_y_continuous(limits = c(25,36.5), name = "Salinity", breaks = seq(25,37,5))+
  geom_segment(x = 1, y = 35, xend = 2, yend =  35, linewidth = 0.5) +
  geom_segment(x = 1, y = 35, xend = 1, yend = 34.5, linewidth = 0.5) +
  geom_segment(x = 2, y = 35, xend = 2, yend = 34.5, linewidth = 0.5) +
  annotate("text", x = 1.5, y = 35.8, label = "*", size = 8) +
  scale_x_discrete(name = "", labels = c("Detected", "Not detected"))

p <- plot_grid(p_wt, p_sal, nrow = 2, align = "hv", byrow = FALSE)
save_plot("./Comparison_between_pa.pdf", p, base_height = 6, base_width = 3.5)

# make a map of eDNA concentration
# This map was plotted by GMT5.4.5 using following script.

## make a data file

eDNA_conc_for_gmt <- eDNA_result %>% 
  filter(sampling_depth == 4.5) %>% 
  mutate(format = "TC 0.0 6p,Helvetica,0/0/0") %>% 
  mutate(diameter = sqrt(concentration/pi)) %>% # adjust circle diameter
  mutate(diameter = if_else(concentration < 10, sqrt(10/pi), diameter)) %>% 
  mutate(diameter = paste0(diameter/9,"c")) %>% 
  mutate(diameter = if_else(presence == 0, "0.17c", diameter)) %>% 
  arrange(desc(concentration)) %>% 
  select(longitude, latitude, format, site, bottom_depth, sampling_depth, diameter, presence)

write_tsv(eDNA_conc_for_gmt, "./eDNA_conc_for_gmt.txt", col_names = FALSE)

## make a legend

l <- c("N 1",
       "S 1.2c c 0c 0/0/0 0p 2.3c Negative",
       "G -0.45",
       "S 1.2c x 0.22c white thin,gray10 2.3c",
       "S 1.2c c 0.223015514519096c gray10 0p 2.3c < 10",
       "S 1.2c c 0.705237c gray10 1p,white 2.3c 100",
       "G 0.1c",
       "S 1.2c c 0.9973557c gray10 1p,white 2.3c 200",
       "G 0.2c",
       "S 1.2c c 1.410474c gray10 1p,white 2.3c 400",
       "G 0.4c",
       "S 1.2c c 1.994711c gray10 1p,white 2.3c 800",
       "G 0.15c",
       "S 1.2c c 0c 0/0/0 0p 2.3c (copies/L)"
)

write(l, "./Map_eDNA_conc_legend.txt")

## execute following script in GMT5.4.5
## netCDF data of bathymetry can be downloaded from GEBCO Gridded Bathymetry Data Download (https://download.gebco.net/)

# #!/usr/bin/env bash
# 
# region=169/47/-125/76r
# proj=S-170/90/11c
# grdfile=./gebco.nc
# psfile=./Map_eDNA_conc.eps
# cptfile=./topocol.cpt
# xyfile=./eDNA_conc_for_gmt.txt
# legendfile=./Map_eDNA_conc_legend.txt
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
# awk '($10==1) {print $1, $2, $9}' $xyfile |
# gmt psxy -i0,1,2 -R -JS -Sc -Ggray10 -Wthin,white -K -O >> $psfile
# awk '($10==0) {print $1, $2, $9}' $xyfile |
# gmt psxy -i0,1 -R -JS -Sx0.2 -Gwhite -Wthin,gray10 -K -O >> $psfile
# gmt pslegend $legendfile -R -JS -Dn1.28/0.017+w4.6c/4.6c+jBR -F+pblack+gwhite -K -O >> $psfile
# gmt psscale -R -JS -Dn1.08/0.4+w6c/0.4c+jBR+v -C$cptfile -L -K -O >> $psfile
# echo "S 0c c 0c 0/0/0 0p 0c Depth (m)" | gmt pslegend -R -JS -Dn1.21/0.88+w2c/0.5c+jBR -F+pwhite+gwhite -O >> $psfile

# rm -f ./gmt.conf
# rm -f ./gmt.history

# plot eDNA concentration on TS diagram
# This figuer was plotted by GMT5.4.5 using following script.

## make a data file

eDNA_TS_for_gmt <- eDNA_result %>% 
  mutate(format = "TC 0.0 6p,Helvetica,0/0/0") %>% 
  mutate(diameter = sqrt(concentration/pi)) %>% # 円のサイズの調整
  mutate(diameter = if_else(concentration < 10, sqrt(10/pi), diameter)) %>% 
  mutate(diameter = if_else(presence == 0, sqrt(10/pi), diameter)) %>% 
  mutate(diameter = paste0(diameter/7,"c")) %>% 
  arrange(desc(concentration)) %>% 
  mutate(surface = if_else(sampling_depth == 4.5, 1, 0)) %>% 
  select(longitude, latitude, format, site, diameter, presence, surface, wt, sal, chl) %>% 
  mutate(site = str_remove(site, " \\(.*")) %>% 
  mutate(site = str_remove(site, "\\."))

write_tsv(eDNA_TS_for_gmt, "./eDNA_TS_for_gmt.txt", col_names = FALSE)

## make legend files

l1 <- c("N 1",
        "S 0.3c c 0.3c royalblue 0p,white 0.8c Surface",
        "S 0.3c c 0.3c chocolate 0p,white 0.8c Niskin"
)

write(l1, "./eDNA_TS_legend_1.txt")

l2 <- c("N 1",
        "S 1.2c c 0c 0/0/0 0p 2.3c Negative",
        "G -0.45",
        "S 1.2c x 0.25c white 1p,gray60 2.5c",
        "S 1.2c c 0.2548749c gray 1p,white 2.5c <10",
        "G 0.05c",
        "S 1.2c c 0.8059851c gray 1p,white 2.5c 100",
        "G 0.1c",
        "S 1.2c c 1.139835c gray 1p,white 2.5c 200",
        "G 0.25c",
        "S 1.2c c 1.61197c gray 1p,white 2.5c 400",
        "G 0.5c",
        "S 1.2c c 2.27967c gray 1p,white 2.5c 800",
        "G 0.2c",
        "S 1.2c c 0c 0/0/0 0p 2.5c (copies/L)"
)

write(l2, "./eDNA_TS_legend_2.txt")

## execute following script in GMT5.4.5

# #! usr/bin/bash env
# 
# region=24/35/-2/10
# proj=X13c/10c
# psfile=./eDNA_TS.eps
# xyfile=./eDNA_TS_for_gmt.txt
# legendfile1=./eDNA_TS_legend_1.txt
# legendfile2=./eDNA_TS_legend_2.txt
# 
# gmt psbasemap -R$region -J$proj -Bxa5f1+l"Salinity" -Bya5f1+l"Water temperature (°C)" -BWS -X5 -Y15 -P -K > $psfile
# awk '($8==1&&$9==1) {print $11, $10, $7}' $xyfile |
# gmt psxy -i0,1,2 -R -JX -Sc -Groyalblue -W1p,white -K -O >> $psfile
# awk '($8==1&&$9==0) {print $11, $10, $7}' $xyfile |
# gmt psxy -i0,1,2 -R -JX -Sc -Gchocolate -W1p,white -K -O >> $psfile
# awk '($8==0) {print $11, $10, $7}' $xyfile |
# gmt psxy -i0,1 -R -JX -Sx0.25 -Gwhite -W1p,royalblue -K -O >> $psfile
# gmt pslegend $legendfile1 -R -JX -Dn0.02/1+w2.8c/1.2c+jTL -F+pblack+gwhite -O -K >> $psfile
# gmt pslegend $legendfile2 -R -JX -Dn0.02/0.86+w4.8c/5c+jTL -F+pblack+gwhite -O >> $psfile
# 
# rm -f ./gmt.conf
# rm -f ./gmt.history


# vertical comparison od eDNA concentration

# extract CTD site
niskin_st <- eDNA_result %>% 
  filter(sampling_depth != 4.5) %>% 
  distinct(site) %>% 
  mutate(site = str_extract(site, "AO\\d{2}")) %>% 
  pull(site)

# クラスタ情報の抽出
cluster <- eDNA_result %>% 
  filter(site %in% niskin_st) %>% 
  select(site, cluster) %>% 
  arrange(cluster) %>% 
  filter(!is.na(cluster))

eDNA_vertical <- eDNA_result %>% 
  mutate(site = str_extract(site, "AO\\d{2}")) %>% 
  select(-cluster) %>% 
  inner_join(cluster, by = "site")

eDNA_vertical_for_gmt <- eDNA_vertical %>% 
  mutate(diameter = sqrt(concentration/pi)) %>% 
  mutate(diameter = if_else(concentration < 10, sqrt(10/pi), diameter)) %>% 
  mutate(diameter = if_else(presence == 0, sqrt(10/pi), diameter)) %>% 
  mutate(diameter = paste0(diameter/4.5,"c")) %>%
  mutate(surface = if_else(sampling_depth == 4.5, 1, 0)) %>% 
  mutate(bottom_depth = -(bottom_depth)) %>% 
  mutate(sampling_depth = -(sampling_depth)) %>% 
  select(longitude, latitude, site, surface, bottom_depth, sampling_depth, diameter, presence, cluster) %>% 
  arrange(cluster, latitude) %>% 
  mutate(x = as.numeric(as_factor(paste0(site, cluster)))) %>% 
  mutate(y = 15)

write_tsv(eDNA_vertical_for_gmt, "./eDNA_vertical_for_gmt.txt", col_names = FALSE)

# legend

l1 <- c("N 6",
        "S 0c c 0c gray 1p,gray20 0.75c AO02",
        "S 0c c 0c gray 1p,white 2.01c AO26",
        "S 0c c 0c gray 1p,white 3.27c AO25",
        "S 0c c 0c gray 1p,white 4.53c AO15",
        "S 0c c 0c gray 1p,white 5.80c AO21",
        "S 0c c 0c gray 1p,white 7.07c AO10"
)

write(l1, "./eDNA_vertical_legend_1.txt")

l2 <- c("N 1",
        "S 1c c 0c 0/0/0 0p 2c Negative",
        "G -0.45",
        "S 1c x 0.3c gray10 1p,gray30 2c",
        "G 0.05c",
        "S 1c c 0.396472c gray10 1p,white 2c 10",
        "G 0.25c",
        "S 1c c 1.253755c gray10 1p,white 2c 100",
        "G 0.3c",
        "S 1c c 1.773077c gray10 1p,white 2c 200",
        "S 1c c 0c 0/0/0 0p 2c (copies/L)"
)

write(l2, "./eDNA_vertical_legend_2.txt")


l3 <- c("N 1",
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

write(l3, "./eDNA_vertical_legend_3.txt")

# #! usr/bin/bash env
# 
# region=0/7/-180/20
# proj=X10c/8c
# psfile=./eDNA_vertical.eps
# xyfile=./eDNA_vertical_for_gmt.txt
# legendfile1=./eDNA_vertical_legend_1.txt
# legendfile2=./eDNA_vertical_legend_2.txt
# legendfile3=./eDNA_vertical_legend_3.txt
# 
# gmt psbasemap -R$region -J$proj -Bxa5f1+l"Station" -Bya+l"Depth (m)" -BWs -X5 -Y15 -P -K > $psfile
# 
# echo "0 0" > tmp.txt
# echo "7 0" >> tmp.txt
# gmt psxy tmp.txt -R -JX -W1p,gray,- -K -O >> $psfile
# 
# echo "0 -50" > tmp.txt
# echo "7 -50" >> tmp.txt
# gmt psxy tmp.txt -R -JX -W1p,gray,- -K -O >> $psfile
# 
# echo "0 -100" > tmp.txt
# echo "7 -100" >> tmp.txt
# gmt psxy tmp.txt -R -JX -W1p,gray,- -K -O >> $psfile
# 
# echo "0 -150" > tmp.txt
# echo "7 -150" >> tmp.txt
# gmt psxy tmp.txt -R -JX -W1p,gray,- -K -O >> $psfile
# 
# awk '($4==1) {print $10, $5}' $xyfile | # draw bottom lines
# gmt psxy -i0,1 -R -JX -S-2 -Gblack -W3,gray10 -K -O >> $psfile
# awk '($8==1) {print $10, $6, $7}' $xyfile | # plot positive data
# gmt psxy -i0,1,2 -R -JX -Sc -Ggray10 -W1p,white -K -O >> $psfile
# awk '($8==0) {print $10, $6}' $xyfile | # plot negative data
# gmt psxy -i0,1 -R -JX -Sx0.3 -Gwhite -W1p,gray10 -K -O >> $psfile
# 
# awk '$9==2 {print $10, $11}' $xyfile | 
# gmt psxy -i0,1 -R -JX -St0.42 -G#0072B5FF -Wthin,white -K -O >> $psfile
# awk '$9==3 {print $10, $11}' $xyfile |
# gmt psxy -i0,1 -R -JX -Ss0.4 -G#E18727FF -Wthin,white -K -O >> $psfile
# awk '$9==4 {print $10, $11}' $xyfile |
# gmt psxy -i0,1 -R -JX -S+0.35 -Gwhite -Wthick,#20854EFF -K -O >> $psfile
# awk '$9==5 {print $10, $11}' $xyfile |
# gmt psxy -i0,1 -R -JX -Ss0.35 -Gwhite -Wthick,#7876B1FF -K -O >> $psfile
# awk '$9==5 {print $10, $11}' $xyfile |
# gmt psxy -i0,1 -R -JX -Sx0.35 -Gwhite -Wthick,#7876B1FF -K -O >> $psfile
# 
# gmt pslegend $legendfile1 -R -JX -Dn0/-0.15+w1/1+jBL -O -K >> $psfile
# gmt pslegend $legendfile2 -R -JX -Dn1.3/0.02+w4.2c/3.4c+jBR -F+pblack+gwhite -K -O >> $psfile
# gmt pslegend $legendfile3 -R -JX -Dn1.3/0.5+w2.7c/3.2c+jBR -F+pblack+gwhite -O >> $psfile
# 
# rm -f ./tmp.txt
# rm -f ./gmt.conf
# rm -f ./gmt.history

