#! usr/bin/bash env

region=24/35/-2/10
proj=X13c/10c
psfile=./eDNA_TS.eps
xyfile=./eDNA_TS_for_gmt.txt
legendfile1=./eDNA_TS_legend_1.txt
legendfile2=./eDNA_TS_legend_2.txt

gmt psbasemap -R$region -J$proj -Bxa5f1+l"Salinity" -Bya5f1+l"Water temperature (°C)" -BWS -X5 -Y15 -P -K > $psfile
awk '($8==1&&$9==1) {print $11, $10, $7}' $xyfile |
gmt psxy -i0,1,2 -R -JX -Sc -Groyalblue -W1p,white -K -O >> $psfile
awk '($8==1&&$9==0) {print $11, $10, $7}' $xyfile |
gmt psxy -i0,1,2 -R -JX -Sc -Gchocolate -W1p,white -K -O >> $psfile
awk '($8==0) {print $11, $10, $7}' $xyfile |
gmt psxy -i0,1 -R -JX -Sx0.25 -Gwhite -W1p,royalblue -K -O >> $psfile
gmt pslegend $legendfile1 -R -JX -Dn0.02/1+w2.8c/1.2c+jTL -F+pblack+gwhite -O -K >> $psfile
gmt pslegend $legendfile2 -R -JX -Dn0.02/0.86+w4.8c/5c+jTL -F+pblack+gwhite -O >> $psfile

rm -f ./gmt.conf
rm -f ./gmt.history
