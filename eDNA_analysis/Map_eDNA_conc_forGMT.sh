#!/usr/bin/env bash

region=169/47/-125/76r
proj=S-170/90/11c
grdfile=./gebco.nc # netCDF data downloaded from GEBCO Gridded Bathymetry Data Download (https://download.gebco.net/).
psfile=./Map_eDNA_conc.eps
cptfile=./topocol.cpt
xyfile=./eDNA_conc_for_gmt.txt
legendfile=./Map_eDNA_conc_legend.txt

gmt set MAP_ANNOT_OBLIQUE 30
gmt set FORMAT_GEO_MAP F
gmt set MAP_DEGREE_SYMBOL degree
gmt set MAP_GRID_PEN_PRIMARY thinnest,gray20

gmt makecpt -Cgebco > $cptfile

gmt psbasemap -R$region -J$proj -Ba0f0g0 -X5c -Y10c -P -K > $psfile
gmt grdimage $grdfile -R -JS -E100 -C$cptfile -K -O >> $psfile
gmt pscoast -R -JS -Di -A250/0/1 -Ba10f10g10 -BWSne -Ggrey80 -W1 -K -O >> $psfile
awk '($10==1) {print $1, $2, $9}' $xyfile |
gmt psxy -i0,1,2 -R -JS -Sc -Ggray10 -Wthin,white -K -O >> $psfile
awk '($10==0) {print $1, $2, $9}' $xyfile |
gmt psxy -i0,1 -R -JS -Sx0.2 -Gwhite -Wthin,gray10 -K -O >> $psfile
gmt pslegend $legendfile -R -JS -Dn1.28/0.017+w4.6c/4.6c+jBR -F+pblack+gwhite -K -O >> $psfile
gmt psscale -R -JS -Dn1.08/0.4+w6c/0.4c+jBR+v -C$cptfile -L -K -O >> $psfile
echo "S 0c c 0c 0/0/0 0p 0c Depth (m)" | gmt pslegend -R -JS -Dn1.21/0.88+w2c/0.5c+jBR -F+pwhite+gwhite -O >> $psfile

rm -f ./gmt.conf
rm -f ./gmt.history
