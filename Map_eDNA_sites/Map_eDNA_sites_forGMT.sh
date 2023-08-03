#!/usr/bin/env bash

region=169/47/-125/76r
proj=S-170/90/11c
grdfile=gebco.nc # netCDF data downloaded from GEBCO Gridded Bathymetry Data Download (https://download.gebco.net/).
psfile=./Map_eDNA_sites.eps
cptfile=./topocol.cpt
xyfile=./Coordinates_for_gmt.txt
legendfile=./Map_eDNA_sites_legend.txt

gmt set MAP_ANNOT_OBLIQUE 30
gmt set FORMAT_GEO_MAP F
gmt set MAP_DEGREE_SYMBOL degree
gmt set MAP_GRID_PEN_PRIMARY thinnest,gray20

gmt makecpt -Cgebco > $cptfile

gmt psbasemap -R$region -J$proj -Ba0f0g0 -X5c -Y10c -P -K > $psfile
gmt grdimage $grdfile -R -JS -E100 -C$cptfile -K -O >> $psfile
gmt pscoast -R -JS -Di -A250/0/1 -Ba10f10g10 -BWSne -Ggrey80 -W1 -K -O >> $psfile
awk '$7==1 {print $0}' $xyfile |
gmt psxy -i0,1 -R -JS -Sc0.25 -Gwhite -Wthin -K -O >> $psfile
awk '$7==0 {print $0}' $xyfile |
gmt psxy -i0,1 -R -JS -Ss0.35 -Gblack -Wthin,white -K -O >> $psfile
gmt pslegend $legendfile -R -JS -Dn0.99/0.01+w5c/1.2c+jBR -F+pblack+gwhite -K -O >> $psfile
gmt psscale -R -JS -Dn1.08/0.01+w6c/0.4c+jBR+v -C$cptfile -L -K -O >> $psfile
echo "S 0c c 0c 0/0/0 0p 0c Depth (m)" | gmt pslegend -R -JS -Dn1.21/0.49+w2c/0.5c+jBR -F+pwhite+gwhite -O >> $psfile

rm -f ./gmt.conf
rm -f ./gmt.history
