#! /bin/bash

## author: E. Macorps

if [ "$#" -lt 8 ]
then
    echo ""
    echo "Usage: $0  <master_ID> <LED_master> <IMG_master> <slave_ID> <LED_slave> <IMG_slave>"
    echo ""
    echo "  master_ID      YYYYMMDD of master SAR image"
    echo "  LED_master     LED_ filename for the master image"
    echo "  IMG_master     IMG_ filename for the master image"
    echo "  slave_ID       YYYYMMDD of the slave SAR image"
    echo "  LED_slave      LED_ filename for the slave image"
    echo "  IMG_slave      IMG_ filename for the slave image"
    echo "  DEM_PAR        DEM Parameter File"
    echo "  DEM            DEM Image File"
    echo ""
    exit -1
fi

ref=$1 # YYYYMMDD of MASTER image
ref_LED=$2 # LED_ file for master image
ref_IMG=$3 # IMG_HH file for master image
slv=$4 # YYYYMMDD of SLAVE image
slv_LED=$5 # LED_ file for slave image
slv_IMG=$6 # IMG_HH file for slave image

pair="${ref}_${slv}"
echo $pair

dem_par=$7 # DEM parameter File
dem_img=$8 # DEM image File

no_terms="4"

echo " ########################################################## "
echo " Generate Single Look Complex SLC image and parameter files "
echo " ########################################################## "

echo "par_EORC_PALSAR $ref_LED $ref.slc.par $ref_IMG $ref.slc"
      par_EORC_PALSAR $ref_LED $ref.slc.par $ref_IMG $ref.slc

echo "par_EORC_PALSAR $slv_LED $slv.slc.par $slv_IMG $slv.slc"
      par_EORC_PALSAR $slv_LED $slv.slc.par $slv_IMG $slv.slc

echo " ########################################################### "
echo " 			SLC image Calibration "
echo " ########################################################### "

echo "radcal_SLC $ref.slc $ref.slc.par $ref.cslc $ref.cslc.par 1 - 0 0 1 0 -115.0"
      radcal_SLC $ref.slc $ref.slc.par $ref.cslc $ref.cslc.par 1 - 0 0 1 0 -115.0

echo "radcal_SLC $slv.slc $slv.slc.par $slv.cslc $slv.cslc.par 1 - 0 0 1 0 -115.0"
      radcal_SLC $slv.slc $slv.slc.par $slv.cslc $slv.cslc.par 1 - 0 0 1 0 -115.0

echo " ########################################################### "
echo " Compute Perpendicular Baseline "
echo " ########################################################### "

echo "base_orbit $ref.cslc.par $slv.cslc.par $pair.base_orbit"
      base_orbit $ref.cslc.par $slv.cslc.par $pair.base_orbit

echo " ########################################################### "
echo " Multi-Look images from Calibrated SLCs "
echo " ########################################################### "

echo "multi_look $ref.cslc $ref.cslc.par $ref.cmli $ref.cmli.par 2 4"
      multi_look $ref.cslc $ref.cslc.par $ref.cmli $ref.cmli.par 2 4

echo "multi_look $slv.cslc $slv.cslc.par $slv.cmli $slv.cmli.par 2 4"
      multi_look $slv.cslc $slv.cslc.par $slv.cmli $slv.cmli.par 2 4

echo " ########################################################### "
echo " Co-Registration of the Calibrated SLCs "
echo " ########################################################### "

# Use SLC_copy to get subsets if image too big

echo "create_offset $ref.cslc.par $slv.cslc.par $pair.off 1"
      create_offset $ref.cslc.par $slv.cslc.par $pair.off 1
echo "init_offset_orbit $ref.cslc.par $slv.cslc.par $pair.off"
      init_offset_orbit $ref.cslc.par $slv.cslc.par $pair.off
echo "init_offset $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off 2 4"
      init_offset $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off 2 4
echo "init_offset $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off 1 1"
      init_offset $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off 1 1
echo "offset_pwr $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off offs snr 1024 1024 offsets 2"
      offset_pwr $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off offs snr 1024 1024 offsets 2
echo "offset_fit offs snr $pair.off coffs coffsets"
      offset_fit offs snr $pair.off coffs coffsets
#echo "offset_pwr $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off offs snr 512 512 offsets 2"
#      offset_pwr $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off offs snr 512 512 offsets 2
#echo "offset_fit offs snr $pair.off coffs coffsets"
#      offset_fit offs snr $pair.off coffs coffsets

echo " ########################################################### "
echo " Precise Estimation of Offsets "
echo " ########################################################### "

echo "offset_pwr_tracking $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off offsN snrN 64 128 offsetsN 2 5.0 12 24"
      offset_pwr_tracking $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off offsN snrN 64 128 offsetsN 2 5.0 12 24
echo "offset_tracking offsN snrN $ref.cslc.par $pair.off coffsN coffsetsN 2 5.0 1"
      offset_tracking offsN snrN $ref.cslc.par $pair.off coffsN coffsetsN 2 5.0 1

echo " ########################################################### "
echo " Resample Slave image using offset model "
echo " ########################################################### "

echo "SLC_interp $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off $slv.rcslc $slv.rcslc.par"
      SLC_interp $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off $slv.rcslc $slv.rcslc.par

echo " ########################################################### "
echo " Multi-look resampled Slave image "
echo " ########################################################### "

echo "multi_look $slv.rcslc $slv.rcslc.par $slv.rcmli $slv.rcmli.par 2 4"
      multi_look $slv.rcslc $slv.rcslc.par $slv.rcmli $slv.rcmli.par 2 4

echo " ########################################################### "
echo " Re-Compute Perpendicular Baseline with resampled slave image "
echo " ########################################################### "

echo "base_orbit $ref.cslc.par $slv.rcslc.par $pair.base_orbit"
      base_orbit $ref.cslc.par $slv.rcslc.par $pair.base_orbit

echo " ########################################################### "
echo " Generation of the Interferogram "
echo " ########################################################### "

echo "SLC_intf $ref.cslc $slv.rcslc $ref.cslc.par $slv.rcslc.par $pair.off $pair.int 2 4"
      SLC_intf $ref.cslc $slv.rcslc $ref.cslc.par $slv.rcslc.par $pair.off $pair.int 2 4

echo " ########################################################### "
echo " Generation of initial geocoding lookup table: $pair.utm_to_rdc_rough "
echo " ########################################################### "

dem_proj=`awk '$1=="DEM_projection:" {print $2}' $dem_par`
insar_cellsizex=`awk '$1=="interferogram_range_pixel_spacing:" {print $2}' $pair.off`
insar_cellsizey=`awk '$1=="interferogram_azimuth_pixel_spacing:" {print $2}' $pair.off`

if [ "$dem_proj" = "EQA" ]
then
	degree2meter="108000"
	dem_cellsizey=`awk '$1 == "post_lat:" {print sqrt($2*$2)*'$degree2meter'}' $dem_par`
	dem_cellsizex=`awk '$1 == "post_lon:" {print sqrt($2*$2)*'$degree2meter'}' $dem_par`
else
	dem_cellsizey=`awk '$1 == "post_north:" {print sqrt($2*$2)}' $dem_par`
	dem_cellsizex=`awk '$1 == "post_east:" {print sqrt($2*$2)}' $dem_par`
fi

#lat_ovr=`printf "%.0f\n" $(echo "scale=3;$dem_cellsizey/$insar_cellsizey"|bc)`
#lon_ovr=`printf "%.0f\n" $(echo "scale=3;$dem_cellsizex/$insar_cellsizex"|bc)`

#if [ "$lat_ovr" = "0" ]
#then
#lat_ovr="1"
#fi
#if [ "$lon_ovr" = "0" ]
#then
#lon_ovr="1"
#fi

#oversampling for square pixels
lat_ovr=3
lon_ovr=3

echo "lat_ovr=$lat_ovr"
echo "lon_ovr=$lon_ovr"

echo "$dem_proj $dem_cellsizex $dem_cellsizey $insar_cellsizex $insar_cellsizey"

echo "gc_map $ref.cmli.par - $dem_par $dem_img $pair.utm.dem_par $pair.utm.dem $pair.utm_to_rdc_rough $lat_ovr $lon_ovr $pair.pwr_sim.utm - - - - - - 8 3 6.0"
      gc_map $ref.cmli.par - $dem_par $dem_img $pair.utm.dem_par $pair.utm.dem $pair.utm_to_rdc_rough $lat_ovr $lon_ovr $pair.pwr_sim.utm - - - - - - 8 3 6.0

## copy the file widths and number of lines from the parameter files to
## the paramters $width $nlines $dem_width $dem_nlines:

grep "interferogram_width" $pair.off > tmp
width=`awk '(NR==1){{print $2}}' tmp`
grep "interferogram_azimuth_lines" $pair.off > tmp
nlines=`awk '(NR==1){{print $2}}' tmp`
grep "width" $pair.utm.dem_par > tmp
dem_width=`awk '(NR==1){{print $2}}' tmp`
grep "nlines" $pair.utm.dem_par > tmp
dem_nlines=`awk '(NR==1){{print $2}}' tmp`
echo "width, nlines, dem_width, dem_nlines: $width $nlines $dem_width $dem_nlines"
rm tmp

echo " ########################################################### "
echo " SAR backscatter intensity image simulation for registration refinement "
echo " ########################################################### "

echo "geocode $pair.utm_to_rdc_rough $pair.pwr_sim.utm $dem_width $pair.pwr_sim $width 0 3 0"
      geocode $pair.utm_to_rdc_rough $pair.pwr_sim.utm $dem_width $pair.pwr_sim $width 0 3 0

echo " ########################################################### "
echo " SAR backscatter intensity image simulation for registration refinement "
echo " ########################################################### "
## Interactive input is required
echo "rm -f $ref.diff_par"
      rm -f $ref.diff_par

echo "create_diff_par $ref.cmli.par - $ref.diff_par 1"
      create_diff_par $ref.cmli.par - $ref.diff_par 1

echo "init_offsetm $ref.cmli $pair.pwr_sim $ref.diff_par"
      init_offsetm $ref.cmli $pair.pwr_sim $ref.diff_par

echo " ########################################################### "
echo "Registration of the simulated SAR intensity image and real SAR intensity image"
echo "The real SAR intensity image is used as the reference geometry"
echo " ########################################################### "

if [ "$width" -ge 1024 -a "$nlines" -ge 1024 ]
then
    echo "offset_pwrm $ref.cmli $pair.pwr_sim $ref.diff_par diff.offs diff.snr 1024 1024 diff.offsets 2 10 10"
          offset_pwrm $ref.cmli $pair.pwr_sim $ref.diff_par diff.offs diff.snr 1024 1024 diff.offsets 2 10 10
else
    if [ "$width" -ge 512 -a "$nlines" -ge 512 ]
    then
        echo "offset_pwrm $ref.cmli $pair.pwr_sim $ref.diff_par diff.offs diff.snr 512 512 diff.offsets 2 10 10"
              offset_pwrm $ref.cmli $pair.pwr_sim $ref.diff_par diff.offs diff.snr 512 512 diff.offsets 2 10 10
    else
        echo "offset_pwrm $ref.cmli $pair.pwr_sim $ref.diff_par diff.offs diff.snr 256 256 diff.offsets 2 10 10"
              offset_pwrm $ref.cmli $pair.pwr_sim $ref.diff_par diff.offs diff.snr 256 256 diff.offsets 2 10 10
    fi
fi

echo "offset_fitm diff.offs diff.snr $ref.diff_par diff.coffs diff.coffsets - $no_terms"
      offset_fitm diff.offs diff.snr $ref.diff_par diff.coffs diff.coffsets - $no_terms

echo "############################################################"
echo " Refinement of Geocoding Lookup Table "
echo "############################################################"

echo "gc_map_fine $pair.utm_to_rdc_rough $dem_width $ref.diff_par $pair.UTM_to_RDC 0"
      gc_map_fine $pair.utm_to_rdc_rough $dem_width $ref.diff_par $pair.UTM_to_RDC 0

mv $pair.pwr_sim $pair.pwr_sim1

echo "interp_real $pair.pwr_sim1 $ref.diff_par $pair.pwr_sim - - 1"
      interp_real $pair.pwr_sim1 $ref.diff_par $pair.pwr_sim - - 1

rm $pair.pwr_sim1
rm $pair.utm_to_rdc_rough

echo " ########################################################### "
echo " Transformation of DEM to SAR coordinates:  $pair.rdc.dem"
echo " Forward Geocoding from UTM map to SAR geometry"
echo " ########################################################### "

echo "geocode $pair.UTM_to_RDC $pair.utm.dem $dem_width $pair.rdc.dem $width $nlines 0 0 "
      geocode $pair.UTM_to_RDC $pair.utm.dem $dem_width $pair.rdc.dem $width $nlines 0 0

## Display DEM in SAR coordinates using:
# dishgt $pair.rdc.dem $ref.cmli $width

echo " ########################################################### "
echo " Generation of coherence image "
echo " ########################################################### "

echo "cc_wave $pair.int $ref.cmli $slv.rcmli $pair.cc $width 5 5 1"
      cc_wave $pair.int $ref.cmli $slv.rcmli $pair.cc $width 5 5 1

echo " ########################################################### "
echo " Backward Geocoding from Radar to Map Coordinates "
echo " ########################################################### "

# Intensity images
echo "geocode_back $ref.cmli $width $pair.UTM_to_RDC $ref.cmli_utm $dem_width - 1 0"
      geocode_back $ref.cmli $width $pair.UTM_to_RDC $ref.cmli_utm $dem_width - 1 0

echo "geocode_back $slc.rcmli $width $pair.UTM_to_RDC $slv.rcmli_utm $dem_width - 1 0"
      geocode_back $slv.rcmli $width $pair.UTM_to_RDC $slv.rcmli_utm $dem_width - 1 0
      
# Coherence images
echo "geocode_back $pair.cc $width $pair.UTM_to_RDC $pair.cc_utm $dem_width - 1 0"
      geocode_back $pair.cc $width $pair.UTM_to_RDC $pair.cc_utm $dem_width - 1 0

echo " ########################################################### "
echo " Conversion to GeoTiff products "
echo " ########################################################### "

data2geotiff $pair.utm.dem_par $ref.cmli_utm 2 $ref.cmliHV_utm.tif 0.0

data2geotiff $pair.utm.dem_par $slv.rcmli_utm 2 $slv.rcmliHV_utm.tif 0.0

data2geotiff $pair.utm.dem_par $pair.cc_utm 2 $pair.ccHV_utm.tif 0.0