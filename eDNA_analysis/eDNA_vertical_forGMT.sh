#! usr/bin/bash env

region=0/7/-180/20
proj=X10c/8c
psfile=./eDNA_vertical.eps
xyfile=./eDNA_vertical_for_gmt.txt
legendfile1=./eDNA_vertical_legend_1.txt
legendfile2=./eDNA_vertical_legend_2.txt
legendfile3=./eDNA_vertical_legend_3.txt

gmt psbasemap -R$region -J$proj -Bxa5f1+l"Station" -Bya+l"Depth (m)" -BWs -X5 -Y15 -P -K > $psfile

echo "0 0" > tmp.txt
echo "7 0" >> tmp.txt
gmt psxy tmp.txt -R -JX -W1p,gray,- -K -O >> $psfile

echo "0 -50" > tmp.txt
echo "7 -50" >> tmp.txt
gmt psxy tmp.txt -R -JX -W1p,gray,- -K -O >> $psfile

echo "0 -100" > tmp.txt
echo "7 -100" >> tmp.txt
gmt psxy tmp.txt -R -JX -W1p,gray,- -K -O >> $psfile

echo "0 -150" > tmp.txt
echo "7 -150" >> tmp.txt
gmt psxy tmp.txt -R -JX -W1p,gray,- -K -O >> $psfile

awk '($4==1) {print $10, $5}' $xyfile | # draw bottom lines
gmt psxy -i0,1 -R -JX -S-2 -Gblack -W3,gray10 -K -O >> $psfile
awk '($8==1) {print $10, $6, $7}' $xyfile | # plot positive data
gmt psxy -i0,1,2 -R -JX -Sc -Ggray10 -W1p,white -K -O >> $psfile
awk '($8==0) {print $10, $6}' $xyfile | # plot negative data
gmt psxy -i0,1 -R -JX -Sx0.3 -Gwhite -W1p,gray10 -K -O >> $psfile

awk '$9==2 {print $10, $11}' $xyfile | 
gmt psxy -i0,1 -R -JX -St0.42 -G#0072B5FF -Wthin,white -K -O >> $psfile
awk '$9==3 {print $10, $11}' $xyfile |
gmt psxy -i0,1 -R -JX -Ss0.4 -G#E18727FF -Wthin,white -K -O >> $psfile
awk '$9==4 {print $10, $11}' $xyfile |
gmt psxy -i0,1 -R -JX -S+0.35 -Gwhite -Wthick,#20854EFF -K -O >> $psfile
awk '$9==5 {print $10, $11}' $xyfile |
gmt psxy -i0,1 -R -JX -Ss0.35 -Gwhite -Wthick,#7876B1FF -K -O >> $psfile
awk '$9==5 {print $10, $11}' $xyfile |
gmt psxy -i0,1 -R -JX -Sx0.35 -Gwhite -Wthick,#7876B1FF -K -O >> $psfile

gmt pslegend $legendfile1 -R -JX -Dn0/-0.15+w1/1+jBL -O -K >> $psfile
gmt pslegend $legendfile2 -R -JX -Dn1.3/0.02+w4.2c/3.4c+jBR -F+pblack+gwhite -K -O >> $psfile
gmt pslegend $legendfile3 -R -JX -Dn1.3/0.5+w2.7c/3.2c+jBR -F+pblack+gwhite -O >> $psfile

rm -f ./tmp.txt
rm -f ./gmt.conf
rm -f ./gmt.history
