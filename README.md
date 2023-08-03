# Boreogadus-eDNA
This repository contains R and GMT scripts and its relevant files for reproducing the results of "Distribution and habitat preference of polar cod (Boreogadus saida) in the Bering and Chukchi Seas inferred from species-specific detection of environmental DNA," which is currently under review.

eDNA results and environmental data (Boreogadus_eDNA_data.csv) is available for download from the Arctic Data archive System (ADS) managed by the National Institute of Polar Research, Japan, with the accession number A20230323-002 (https://ads.nipr.ac.jp/dataset/A20230323-002).
Bathymetry data in netCDF format can be downloaded from GEBCO Gridded Bathymetry Data Download (https://download.gebco.net/).
The scripts were run using R version 4.1.2 and GMT version 5.4.5.

Map_eDNA_sites:  
Create a map for eDNA collection sites with bathymetry.

Water_mass_classification:  
Classify water masses based on environmental data using the SIMPROF test and principal component analysis (PCA).  
Summarize the environmental characteristics of each cluster.

eDNA_analysis:  
Summarize the eDNA results.  
Plot the polar cod eDNA concentration on a map.  
Plot the polar cod eDNA concentration on a TS diagram.  
Perform a logistic regression analysis to relate the eDNA concentration to environmental conditions.  
