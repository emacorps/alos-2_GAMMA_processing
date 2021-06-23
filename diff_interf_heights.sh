#! /bin/bash
## For error in /bin/bash^M in Ubuntu: sed -i -e 's/\r$//' diff_interf_heights.sh
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
echo "offset_pwr $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off offs snr 512 512 offsets 2"
      offset_pwr $ref.cslc $slv.cslc $ref.cslc.par $slv.cslc.par $pair.off offs snr 512 512 offsets 2
echo "offset_fit offs snr $pair.off coffs coffsets"
      offset_fit offs snr $pair.off coffs coffsets

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
echo " Calculate Simulated Topographic Phase "
echo " The simulated topo phase $pair.ph_sim is unwrapped "
echo " ########################################################### "

echo "phase_sim $ref.cslc.par $pair.off $pair.base_orbit $pair.rdc.dem $pair.ph_sim 0 0"
      phase_sim $ref.cslc.par $pair.off $pair.base_orbit $pair.rdc.dem $pair.ph_sim 0 0

## Display the simulated unwrapped unflattened phase using:
# disrmg $pair.ph_sim $ref.cmli $width

echo " ########################################################### "
echo " Substraction of the simulated topographic phase "
echo " ########################################################### "

echo "create_diff_par $pair.off - $pair.diff_par 0"
      create_diff_par $pair.off - $pair.diff_par 0

echo "sub_phase $pair.int $pair.ph_sim $pair.diff_par $pair.diff0 1 0"
      sub_phase $pair.int $pair.ph_sim $pair.diff_par $pair.diff0 1 0

## Display wrapped differential interferogram (with topographic phase removed) using
# dismph_pwr24 $pair.diff0 $ref.cmli $width

echo " ########################################################### "
echo " Removal of residual fringes from differential interferogram "
echo " ########################################################### "

# 1. estimate residual baseline from the fringe rate
echo "base_init $ref.cslc.par $slv.rcslc.par $pair.off $pair.diff0 $pair.base 4 512 512"
      base_init $ref.cslc.par $slv.rcslc.par $pair.off $pair.diff0 $pair.base 4 512 512

# 2. correct initial baseline with estimate of residual baseline
echo "base_add $pair.base_orbit $pair.base $pair.base1 1"
      base_add $pair.base_orbit $pair.base $pair.base1 1

# 3. simulate the topgraphic phase with the new baseline values
echo "phase_sim $ref.cslc.par $pair.off $pair.base1 $pair.rdc.dem $pair.ph_sim 0 0"
      phase_sim $ref.cslc.par $pair.off $pair.base1 $pair.rdc.dem $pair.ph_sim 0 0

# 4. Substract the new topographic phase from original interferogram --> generates new differential interferogram $pair.diff
echo "sub_phase $pair.int $pair.ph_sim $pair.diff_par $pair.diff 1 0"
      sub_phase $pair.int $pair.ph_sim $pair.diff_par $pair.diff 1 0

echo " ########################################################### "
echo " Generation of coherence image "
echo " ########################################################### "

echo "cc_wave $pair.diff $ref.cmli $slv.rcmli $pair.cc $width 5 5 1"
      cc_wave $pair.diff $ref.cmli $slv.rcmli $pair.cc $width 5 5 1

echo " ########################################################### "
echo "                      Phase Unwrapping "
echo " ########################################################### "

# 1. Multi-look the differential interferogram
echo "multi_cpx $pair.diff $pair.off $pair.diff10 $pair.off10 10 10 0 0"
      multi_cpx $pair.diff $pair.off $pair.diff10 $pair.off10 10 10 0 0

echo "multi_real $ref.cmli $pair.off $ref.cmli10 $pair.off10 10 10 0 0"
      multi_real $ref.cmli $pair.off $ref.cmli10 $pair.off10 10 10 0 0

grep "interferogram_width" $pair.off10 > tmp
width10=`awk '(NR==1){{print $2}}' tmp`
grep "interferogram_azimuth_lines" $pair.off10 > tmp
nlines10=`awk '(NR==1){{print $2}}' tmp`
rm tmp

# 2. Generate multi_look coherence image
echo "cc_wave $pair.diff10 - - $pair.diff10.cc $width10 7 7 1"
      cc_wave $pair.diff10 - - $pair.diff10.cc $width10 7 7 1

# 3. Generate phase unwrapping mask
echo "rascc_mask $pair.diff10.cc - $width10 1 1 0 1 1 0.7 - 0.1 0.9 1.0 0.35 1 $pair.cc_mask.ras"
      rascc_mask $pair.diff10.cc - $width10 1 1 0 1 1 0.7 - 0.1 0.9 1.0 0.35 1 $pair.cc_mask.ras

# 4. MCF Unwrapping using mask
echo "mcf $pair.diff10 $pair.diff10.cc $pair.cc_mask.ras $pair.diff10.unw $width10 1 0 0 - - 1 1 - 60 70"
      mcf $pair.diff10 $pair.diff10.cc $pair.cc_mask.ras $pair.diff10.unw $width10 1 0 0 - - 1 1 - 60 70

# Display unwrapped multi-look interferogram using
# disdt_pwr24 $pair.diff10.unw $ref.cmli10 $width10

# 5. Unwrapped differential interferogram oversampled with factors 10 to obtain initial resolution
echo "multi_real $pair.diff10.unw $pair.off10 $pair.diff.unw $pair.off -10 -10 0 0"
      multi_real $pair.diff10.unw $pair.off10 $pair.diff.unw $pair.off -10 -10 0 0
      
echo " ########################################################### "
echo " First Refinement of differential interferogram using baseline model "
echo " ########################################################### "

# The differential interferogram might still have some phase trends related to an imperfect estimate of the baseline
# Estimation of the baseline based on GCPs requires unwrapped interferogram and a DEM in radar geometry
# The unwrapped interferogram can be obtained by adding the unwrapped differential phase ($pair.diff.unw) to the unwrapped simulated phase ($pair.ph_sim)
# This way we generate an unwrapped version of the original interferogram ($pair.int.unw)

echo "sub_phase $pair.diff.unw $pair.ph_sim $pair.diff_par $pair.int.unw 0 1"
      sub_phase $pair.diff.unw $pair.ph_sim $pair.diff_par $pair.int.unw 0 1

# We generate a coherence mask for threshold on where to select GCPs
echo "cc_wave $pair.diff - - $pair.diff.cc $width 7 7 1"
      cc_wave $pair.diff - - $pair.diff.cc $width 7 7 1

echo "rascc_mask $pair.diff.cc - $width 1 1 0 1 1 0.7 - - - - - - $pair.diff.cc_mask.ras"
      rascc_mask $pair.diff.cc - $width 1 1 0 1 1 0.7 - - - - - - $pair.diff.cc_mask.ras
      
echo "extract_gcp $pair.rdc.dem $pair.off $pair.gcp 100 100 $pair.diff.cc_mask.ras"
      extract_gcp $pair.rdc.dem $pair.off $pair.gcp 100 100 $pair.diff.cc_mask.ras

# Extract phase values for the selected GCPs
echo "gcp_phase $pair.int.unw $pair.off $pair.gcp $pair.gcp_ph 3"
      gcp_phase $pair.int.unw $pair.off $pair.gcp $pair.gcp_ph 3

# Using phase estimates and height values at the GCPs, determine new baseline estimate

cp $pair.base1 $pair.base.orig

echo "base_ls $ref.cslc.par $pair.off $pair.gcp_ph $pair.base1 0 1 1 1 1 1."
      base_ls $ref.cslc.par $pair.off $pair.gcp_ph $pair.base1 0 1 1 1 1 1.

# Generate a new simulated phase image of the curved Earth and topographic components (unwrapped)
# using the new version of the baseline and subtract from the original interferogram

echo "phase_sim $ref.cslc.par $pair.off $pair.base1 $pair.rdc.dem $pair.ph_sim 0 1 - -"
      phase_sim $ref.cslc.par $pair.off $pair.base1 $pair.rdc.dem $pair.ph_sim 0 1 - -
      
echo "sub_phase $pair.int $pair.ph_sim $pair.diff_par $pair.diff 1 0"
      sub_phase $pair.int $pair.ph_sim $pair.diff_par $pair.diff 1 0
      
echo " ########################################################### "
echo " Phase unwrapping of refined differential interferogram "
echo " ########################################################### "

# Generation of 10x10 multi-looked images of the interferogram and the reference MLI

echo "multi_cpx $pair.diff $pair.off $pair.diff10 $pair.off10 10 10 0 0"
      multi_cpx $pair.diff $pair.off $pair.diff10 $pair.off10 10 10 0 0
      
echo "multi_real $ref.cmli $pair.off $ref.cmli10 $pair.off10 10 10 0 0"
      multi_real $ref.cmli $pair.off $ref.cmli10 $pair.off10 10 10 0 0
      
# Generation of phase unwrapping mask

echo "cc_wave $pair.diff10 - - $pair.diff10.cc $width10 7 7 1"
      cc_wave $pair.diff10 - - $pair.diff10.cc $width10 7 7 1
      
echo "rascc_mask $pair.diff10.cc - $width10 1 1 0 1 1 0.7 - - - - - - $pair.diff10.cc_mask.ras"
      rascc_mask $pair.diff10.cc - $width10 1 1 0 1 1 0.7 - - - - - - $pair.diff10.cc_mask.ras
      
# Phase Unwrapping of multi-looked interferogram using MCF algorithm

echo "mcf $pair.diff10 $pair.diff10.cc $pair.diff10.cc_mask.ras $pair.diff10.unw $width10 1 0 0 - - 1 1 - 60 70"
      mcf $pair.diff10 $pair.diff10.cc $pair.diff10.cc_mask.ras $pair.diff10.unw $width10 1 0 0 - - 1 1 - 60 70

# Oversampling of unwrapped differential interferogram to original pixel size

echo "multi_real $pair.diff10.unw $pair.off10 $pair.diff.unw $pair.off -10 -10 0 0"
      multi_real $pair.diff10.unw $pair.off10 $pair.diff.unw $pair.off -10 -10 0 0

echo " ########################################################### "
echo " Compensation of unwrapped interferogram for residual quadratic phase "
echo " ########################################################### "

# It is possible that the differential interferogram still presents some residual phase components 
# not yet compensated for after baseline improvement

# Generate coherence image from the differential interferogram and mask
echo "cc_wave $pair.diff - - $pair.diff.cc2 $width 15 15 2"
      cc_wave $pair.diff - - $pair.diff.cc2 $width 15 15 2
      
echo "rascc_mask $pair.diff.cc2 - $width 1 1 0 1 1 0.7 - - - - - - $pair.diff.cc_mask2.ras"
      rascc_mask $pair.diff.cc2 - $width 1 1 0 1 1 0.7 - - - - - - $pair.diff.cc_mask2.ras
  
# Mask is then applied to determine the model phase function
echo "quad_fit $pair.diff.unw $pair.diff_par 32 32 $pair.diff.cc_mask2.ras quad_fit.plot 0"
      quad_fit $pair.diff.unw $pair.diff_par 32 32 $pair.diff.cc_mask2.ras quad_fit.plot 0
      
# Apply model fit to the differential interferogram
echo "quad_sub $pair.diff.unw $pair.diff_par $pair.diff2.unw 0 0"
      quad_sub $pair.diff.unw $pair.diff_par $pair.diff2.unw 0 0

echo " ########################################################### "
echo " Refinement of the differential interferogram with improved quadratic phase model "
echo " ########################################################### "

#rename $pair.diff in $pair.diff0 to avoid complication with filenames further down in the processing
mv $pair.diff $pair.diff0

# The estimate of the quadratic phase trend obtained earlier is subtracted from the differential interferogram
# to obtain a new version of the wrapped diffential interferogram

echo "quad_sub $pair.diff0 $pair.diff_par $pair.diff 1 0"
      quad_sub $pair.diff0 $pair.diff_par $pair.diff 1 0
      
# Then unwrap the corrected differential interferogram

echo "multi_cpx $pair.diff $pair.off $pair.diff10 $pair.off10 10 10 0 0"
      multi_cpx $pair.diff $pair.off $pair.diff10 $pair.off10 10 10 0 0

# smooth the multi_looked interferogram with adaptive filter
echo "adf $pair.diff10 $pair.diff10.sm1 $pair.diff10.smcc $width10 0.25 8 7 1 0 0 0.2" 
      adf $pair.diff10 $pair.diff10.sm1 $pair.diff10.smcc $width10 0.25 8 7 1 0 0 0.2

echo "adf $pair.diff10.sm1 $pair.diff10.sm2 $pair.diff10.smcc $width10 0.25 8 7 1 0 0 0.2" 
      adf $pair.diff10.sm1 $pair.diff10.sm2 $pair.diff10.smcc $width10 0.25 8 7 1 0 0 0.2

# Display smoothed multi-looked interferogram using
# dismph_pwr24 $pair.diff10.sm2 $ref.cmli10 $width10

# Generate mask of low coherence - we can lower the threshold
echo "rascc_mask $pair.diff10.cc - $width10 1 1 0 1 1 0.5 - - - - - - $pair.diff10.cc_mask.ras"
      rascc_mask $pair.diff10.cc - $width10 1 1 0 1 1 0.5 - - - - - - $pair.diff10.cc_mask.ras
      
# Phase unwrapping of the smoothed multi-looked interferogram
echo "mcf $pair.diff10.sm2 $pair.diff10.cc $pair.diff10.cc_mask.ras $pair.diff10.unw $width10 1 0 0 - - 1 1 - 60 70"
      mcf $pair.diff10.sm2 $pair.diff10.cc $pair.diff10.cc_mask.ras $pair.diff10.unw $width10 1 0 0 - - 1 1 - 60 70

# Further improvement consists of interpolating the phase values over small areas
echo "interp_ad $pair.diff10.unw $pair.diff10.unw1 $width10 1 4 128 2 2 0"
      interp_ad $pair.diff10.unw $pair.diff10.unw1 $width10 1 4 128 2 2 0
      
# Resample the interpolated unwrapped multi-looked interferogram to the original size
echo "multi_real $pair.diff10.unw1 $pair.off10 $pair.diff.unw $pair.off -10 -10 0 0"
      multi_real $pair.diff10.unw1 $pair.off10 $pair.diff.unw $pair.off -10 -10 0 0
      
# Now add the quadratic phase model to the unwrapped differential interferogram
echo "quad_sub $pair.diff.unw $pair.diff_par $pair.diff3.unw 0 1"
      quad_sub $pair.diff.unw $pair.diff_par $pair.diff3.unw 0 1
      
echo "quad_fit $pair.diff3.unw $pair.diff_par 32 32 $pair.diff.cc_mask2.ras quad_fit.plot 0"
      quad_fit $pair.diff3.unw $pair.diff_par 32 32 $pair.diff.cc_mask2.ras quad_fit.plot 0
      
echo "quad_sub $pair.diff3.unw $pair.diff_par $pair.diff.unw 0 0"
      quad_sub $pair.diff3.unw $pair.diff_par $pair.diff.unw 0 0

# echo " ########################################################### "
# echo " Further possible refinements and final phase unwrapping "
# echo " ########################################################### "

# Using modeling and location $rg and $az where phase value is 0.0
#echo "unw_mode $pair.diff $pair.diff.unw $pair.diff.unw2 $width $rg $az"
#      unw_mode $pair.diff $pair.diff.unw $pair.diff.unw2 $width $rg $az

# Can also mask areas on DEM that are known errors

echo " ########################################################### "
echo " Conversion of unwrapped phase to elevation "
echo " ########################################################### "

# add the unwrapped phase to the simulated phase and get heights      
echo "Adding the unwrapped differential interferogram to the simulated phase"
echo "sub_phase $pair.diff.unw $pair.ph_sim $pair.diff_par $pair.int.unw2 0 1"
      sub_phase $pair.diff.unw $pair.ph_sim $pair.diff_par $pair.int.unw2 0 1
echo "Converting to heights"      
echo "hgt_map $pair.int.unw2 $ref.cslc.par $pair.off $pair.base1 $pair.int.hgt $pair.int.gr 0 0"
      hgt_map $pair.int.unw2 $ref.cslc.par $pair.off $pair.base1 $pair.int.hgt $pair.int.gr 0 0

echo " ########################################################### "
echo " Conversion of unwrapped differential interferogram to displacement map "
echo " ########################################################### "

echo "dispmap $pair.diff.unw $pair.rdc.dem $ref.cslc.par $pair.off $pair.diff.disp 1"
      dispmap $pair.diff.unw $pair.rdc.dem $ref.cslc.par $pair.off $pair.diff.disp 1
      
echo " ########################################################### "
echo " Backward Geocoding from Radar to Map Coordinates "
echo " ########################################################### "

# interferogram heigts
echo "geocode_back $pair.int.hgt $width $pair.UTM_to_RDC $pair.int.hgt_utm $dem_width - 2 0"
      geocode_back $pair.int.hgt $width $pair.UTM_to_RDC $pair.int.hgt_utm $dem_width - 2 0

# displacements
echo "geocode_back $pair.diff.disp $width $pair.UTM_to_RDC $pair.diff.disp_utm $dem_width - 2 0"
      geocode_back $pair.diff.disp $width $pair.UTM_to_RDC $pair.diff.disp_utm $dem_width - 2 0

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

data2geotiff $pair.utm.dem_par $pair.int.hgt_utm 2 $pair.int.hgt_utm.tif 0.0

data2geotiff $pair.utm.dem_par $pair.diff.disp_utm 2 $pair.diff.disp_utm.tif 0.0

data2geotiff $pair.utm.dem_par $ref.cmli_utm 2 $ref.cmli_utm.tif 0.0

data2geotiff $pair.utm.dem_par $slv.rcmli_utm 2 $slv.rcmli_utm.tif 0.0

data2geotiff $pair.utm.dem_par $pair.cc_utm 2 $pair.cc_utm.tif 0.0
