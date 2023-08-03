#!/usr/bin/env bash

region=169/47/-125/76r
proj=S-170/90/11c
grdfile=gebco.nc # netCDF file downloaded from GEBCO Gridded Bathymetry Data Download (https://download.gebco.net/).
psfile=./Map_clustered_sites.eps
xyfile=./Coordinates_clustered_for_gmt.txt
legendfile=./Map_clustered_legend.txt
cptfile=./topocol.cpt

gmt set MAP_ANNOT_OBLIQUE 30
gmt set FORMAT_GEO_MAP F
gmt set MAP_DEGREE_SYMBOL degree
gmt set MAP_GRID_PEN_PRIMARY thinnest,gray20

gmt makecpt -Cgebco > $cptfile

gmt psbasemap -R$region -J$proj -Ba0f0g0 -X5c -Y10c -P -K > $psfile
gmt grdimage $grdfile -R -JS -E100 -C$cptfile -K -O >> $psfile
gmt pscoast -R -JS -Di -A250/0/1 -Ba10f10g10 -BWSne -Ggrey80 -W1 -K -O >> $psfile
awk '$7==1 {print $0}' $xyfile |
gmt psxy -i0,1 -R -JS -Sc0.3 -G#BC3C29FF -Wthin,white -K -O >> $psfile
awk '$7==2 {print $0}' $xyfile |
gmt psxy -i0,1 -R -JS -St0.42 -G#0072B5FF -Wthin,white -K -O >> $psfile
awk '$7==3 {print $0}' $xyfile |
gmt psxy -i0,1 -R -JS -Ss0.4 -G#E18727FF -Wthin,white -K -O >> $psfile
awk '$7==4 {print $0}' $xyfile |
gmt psxy -i0,1 -R -JS -S+0.35 -Gwhite -Wthick,#20854EFF -K -O >> $psfile
awk '$7==5 {print $0}' $xyfile |
gmt psxy -i0,1 -R -JS -Ss0.35 -Gwhite -Wthick,#7876B1FF -K -O >> $psfile
awk '$7==5 {print $0}' $xyfile |
gmt psxy -i0,1 -R -JS -Sx0.35 -Gwhite -Wthick,#7876B1FF -K -O >> $psfile
gmt pslegend $legendfile -R -JS -Dn1.28/0+w2.6c/3.2c+jBR -F+pblack+gwhite -K -O >> $psfile
gmt psscale -R -JS -Dn1.08/0.5+w6c/0.4c+jBR+v -C$cptfile -L -O >> $psfile

rm -f ./gmt.conf
rm -f ./gmt.history
