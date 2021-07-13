################################################################################
#
# Makefile for main EPIBIOS processing pipeline
#
# Author: Ryan Cabeen
#
################################################################################

ifndef STATS 
$(error STATS is required)
endif

BIN   := $(dir $(abspath $(word $(words $(MAKEFILE_LIST)), $(MAKEFILE_LIST))))
ROOT  ?= $(abspath $(BIN)/..)

default: all

QIT_THREADS ?= 2
QIT_MEMORY  ?= -Xmx2G
GPU         ?= # enable GPU multi-fiber fitting (any value)
NO_BEDPOST  ?= # use the QIT version of multi-fiber fitting 
          
FIBERS_FIT  ?= $(if $(NO_BEDPOST), \
                 VolumeFibersFit --threads $(QIT_THREADS), \
                 $(if $(GPU), VolumeFibersFitFslGpu, \
                   VolumeFibersFitFsl)) 

QIT_CMD     := qit $(QIT_MEMORY) --verbose --debug
TMP         := tmp.$(shell date +%s)
BCK         := bck.$(shell date +%s)

SITE        := $(shell basename $(dir $(dir $(shell pwd))))

$(info using pwd: $(shell pwd))
$(info using input: $(INPUT))
$(info using stats: $(STATS))
$(info using site: $(SITE))

include $(ROOT)/params/$(SITE)/Makefile

################################################################################
# Parameters 
################################################################################

LESION_ERODE      ?= 3          # erode the lesion brain mask by this much 
LESION_MINVOX     ?= 5          # the minimum num of contiguous lesion voxels
HEME_S0_ZSCORE    ?= -3         # the DTI baseline abnormality of heme 
CAVITY_MD_ZSCORE  ?= 5          # the DTI MD abnormality of cavity 
HEME_T2S_ZSCORE   ?= -2         # the T2-star abnormality of heme
CAVITY_T2S_ZSCORE ?= 3          # the T2-star abnormality of cavity
PERILESION_LEVELS ?= 3,5,7,9    # the levels for perilesional analysis

ROI_ERODE         ?= 1          # the erosion count for restricted ROI analysis
ROI_THRESH        ?= 0.15       # the FA threshold for restricted ROI analysis

VIS_CROP          ?= 25:81      # the window for cropping atlas data vis
VIS_CROP_SMALL    ?= 47:2:71    # the smaller window for cropping atlas data vis

BUNDLE_MIN        ?= 0.025      # the minimum volume fraction for tracking
BUNDLE_ANGLE      ?= 65         # the maximum turning angle
BUNDLE_FACTOR     ?= 1          # the seed count multiplier
BUNDLE_HYBFAC     ?= 5          # the seed count multiplier for prior tracking
BUNDLE_HYBSUM     ?= 0.01       # the minimum total fiber volume fraction 
BUNDLE_HYBDISP    ?= 0.1        # the dispersion used in hybrid tracking 
BUNDLE_STEP       ?= 1.0        # the tracking stepsize
BUNDLE_INTERP     ?= Trilinear  # the interpolation mode
BUNDLE_SMOOTH     ?= -0.75      # the smoothing (compute from voxel dimension)
BUNDLE_DISPERSE   ?= 0.05       # the amount of tracking dispersion
BUNDLE_MAXLEN     ?= 10000      # the maximum track length
BUNDLE_LIMIT      ?= 1000000    # the maximum number of tracks
BUNDLE_METHOD     ?= Hybrid     # the type of tracking (e.g. Prior Determ Prob)

PROJECT_SIGMA     ?= 0          # compute from the voxel dimension
PROJECT_ANGLE     ?= 45         # the minimum angle for hybrid projection
PROJECT_NORM      ?= 0.01       # the minimum norm for inclusion
PROJECT_FRAC      ?= 0.01       # the minimum single fraction for inclusion
PROJECT_FSUM      ?= 0.05       # the minimum total fraction for inclusion

SIMPLE_COUNT      ?= 10000      # the maximum number in a simplified bundle
SIMPLE_DIST       ?= 1          # the distance threshold for simplification

ALONG_FLAGS       ?=            # the along tract parameters, e.g. --outlier 
ALONG_ITERS       ?= 5          # the number of along tract smoothing iters

################################################################################
# Targets 
################################################################################

NT_SOURCE          := native.source

NT_DWI             := native.dwi
NT_MGE             := native.mge
NT_MTR             := native.mtr
AT_DWI             := atlas.dwi
AT_MGE             := atlas.mge
AT_MTR             := atlas.mtr

NT_RAW_BVECS       := native.dwi/source/raw.bvecs.txt
NT_RAW_BVALS       := native.dwi/source/raw.bvals.txt
NT_DWI_BVECS       := native.dwi/source/dwi.bvecs.txt
NT_DWI_BVALS       := native.dwi/source/dwi.bvals.txt

NT_DWI_XFM         := native.dwi/source/xfm.txt
NT_DWI_INVXFM      := native.dwi/source/invxfm.txt
AT_DWI_WARP        := atlas.dwi/warp
AT_TO_NT_DWI       := atlas.dwi/warp/xfm.nii.gz
NT_TO_AT_DWI       := atlas.dwi/warp/invxfm.nii.gz
AT_DWI_JAC         := atlas.dwi/warp/logjacdet.nii.gz
NT_DWI_JAC         := native.dwi/warp/logjacdet.nii.gz

NT_DWI_RAW         := native.dwi/source/raw.nii.gz
NT_DWI_NLM         := native.dwi/source/nlm.nii.gz
NT_DWI_EDDY        := native.dwi/source/eddy
NT_DWI_INPUT       := native.dwi/source/dwi.nii.gz
NT_DWI_QA          := native.dwi/source/qa.csv
AT_DWI_VIS         := atlas.dwi/vis

NT_DWI_ALL_DTI     := native.dwi/model/all.dti
NT_DWI_DTI         := native.dwi/model/fit.dti
NT_DWI_FWDTI       := native.dwi/model/fit.fwdti
NT_DWI_NODDI       := native.dwi/model/fit.noddi
NT_DWI_XFIB        := native.dwi/model/fit.xfib
AT_DWI_DTI         := atlas.dwi/model/fit.dti
AT_DWI_FWDTI       := atlas.dwi/model/fit.fwdti
AT_DWI_NODDI       := atlas.dwi/model/fit.noddi
AT_DWI_XFIB        := atlas.dwi/model/fit.xfib
NT_DWI_RESIDUAL    := native.dwi/model/residual

NT_DWI_FIT         := native.dwi/param/fit
NT_DWI_FITZ        := native.dwi/param/fitz
NT_DWI_HARM        := native.dwi/param/harm
NT_DWI_HARMZ       := native.dwi/param/harmz
AT_DWI_FIT         := atlas.dwi/param/fit
AT_DWI_FITZ        := atlas.dwi/param/fitz
AT_DWI_HARM        := atlas.dwi/param/harm
AT_DWI_HARMZ       := atlas.dwi/param/harmz
AT_DWI_FIT_TBSS    := atlas.dwi/param/fit.tbss
AT_DWI_FITZ_TBSS   := atlas.dwi/param/fitz.tbss
AT_DWI_HARM_TBSS   := atlas.dwi/param/harm.tbss
AT_DWI_HARMZ_TBSS  := atlas.dwi/param/harmz.tbss

NT_DWI_BRAIN_MASK  := native.dwi/mask/brain.nii.gz
AT_DWI_BRAIN_MASK  := atlas.dwi/mask/brain.nii.gz
AT_DWI_TBSS_MASK   := atlas.dwi/mask/tbss.nii.gz
NT_DWI_PRIOR       := native.dwi/mask/prior.nii.gz
NT_DWI_LESION      := native.dwi/lesion
AT_DWI_LESION      := atlas.dwi/lesion
AT_DWI_TISSUE_MASK := atlas.dwi/lesion/tissue.nii.gz
NT_DWI_TISSUE_MASK := native.dwi/lesion/tissue.nii.gz
AT_DWI_LESION_MASK := atlas.dwi/lesion/lesion.nii.gz
NT_DWI_LESION_MASK := native.dwi/lesion/lesion.nii.gz
NT_DWI_ATLAS_MASK  := native.dwi/mask/atlas.nii.gz

NT_MGE_RAW         := native.mge/source/raw.nii.gz
NT_MGE_NLM         := native.mge/source/nlm.nii.gz
NT_MGE_QA          := native.mge/source/qa.csv
AT_MGE_VIS         := atlas.mge/vis

NT_MGE_MODEL       := native.mge/model
NT_MGE_PARAMS      := native.mge/model/mge_fit.nii.gz
NT_MGE_BASE        := native.mge/model/mge_base.nii.gz
NT_MGE_R2STAR      := native.mge/model/mge_r2star.nii.gz
NT_MGE_T2STAR      := native.mge/model/mge_t2star.nii.gz
NT_MGE_BIASED      := native.mge/model/mge_biased.nii.gz
NT_MGE_MEAN        := native.mge/model/mge_mean.nii.gz
NT_MGE_RESIDUAL    := native.mge/model/residual

NT_MGE_FIT         := native.mge/param/fit
NT_MGE_FITZ        := native.mge/param/fitz
NT_MGE_HARM        := native.mge/param/harm
NT_MGE_HARMZ       := native.mge/param/harmz
AT_MGE_FIT         := atlas.mge/param/fit
AT_MGE_FITZ        := atlas.mge/param/fitz
AT_MGE_HARM        := atlas.mge/param/harm
AT_MGE_HARMZ       := atlas.mge/param/harmz
AT_MGE_FIT_TBSS    := atlas.mge/param/fit.tbss
AT_MGE_FITZ_TBSS   := atlas.mge/param/fitz.tbss
AT_MGE_HARM_TBSS   := atlas.mge/param/harm.tbss
AT_MGE_HARMZ_TBSS  := atlas.mge/param/harmz.tbss

AT_MGE_WARP        := atlas.mge/warp
AT_TO_NT_MGE       := atlas.mge/warp/xfm.nii.gz
NT_TO_AT_MGE       := atlas.mge/warp/invxfm.nii.gz
AT_MGE_JAC         := atlas.mge/warp/logjacdet.nii.gz
NT_MGE_JAC         := native.mge/warp/logjacdet.nii.gz

NT_MGE_MASK        := native.mge/mask/brain.nii.gz
AT_MGE_MASK        := atlas.mge/mask/brain.nii.gz
AT_MGE_TBSS_MASK   := atlas.mge/mask/tbss.nii.gz
NT_MGE_PRIOR       := native.mge/mask/prior.nii.gz
AT_MGE_LESION      := atlas.mge/lesion
NT_MGE_LESION      := native.mge/lesion
AT_MGE_TISSUE_MASK := atlas.mge/lesion/tissue.nii.gz
NT_MGE_TISSUE_MASK := native.mge/lesion/tissue.nii.gz
AT_MGE_LESION_MASK := atlas.mge/lesion/lesion.nii.gz
NT_MGE_LESION_MASK := native.mge/lesion/lesion.nii.gz
NT_MGE_ATLAS_MASK  := native.mge/mask/atlas.nii.gz

NT_MTR_LOW_RAW     := native.mtr/source/mt.low.raw.nii.gz
NT_MTR_HIGH_RAW    := native.mtr/source/mt.high.raw.nii.gz
NT_MTR_LOW_NLM     := native.mtr/source/mt.low.nlm.nii.gz
NT_MTR_HIGH_NLM    := native.mtr/source/mt.high.nlm.nii.gz

NT_MTR_RATIO_RAW   := native.mtr/model/mtr.raw.nii.gz
NT_MTR_RATIO       := native.mtr/model/mtr.nii.gz
NT_MTR_RESIDUAL    := native.mtr/model/residual

NT_MTR_FIT         := native.mtr/param/fit
NT_MTR_FITZ        := native.mtr/param/fitz
NT_MTR_HARM        := native.mtr/param/harm
NT_MTR_HARMZ       := native.mtr/param/harmz
AT_MTR_FIT         := atlas.mtr/param/fit
AT_MTR_FITZ        := atlas.mtr/param/fitz
AT_MTR_HARM        := atlas.mtr/param/harm
AT_MTR_HARMZ       := atlas.mtr/param/harmz
AT_MTR_FIT_TBSS    := atlas.mtr/param/fit.tbss
AT_MTR_FITZ_TBSS   := atlas.mtr/param/fitz.tbss
AT_MTR_HARM_TBSS   := atlas.mtr/param/harm.tbss
AT_MTR_HARMZ_TBSS  := atlas.mtr/param/harmz.tbss

AT_MTR_WARP        := atlas.mtr/warp
AT_TO_NT_MTR       := atlas.mtr/warp/xfm.nii.gz
NT_TO_AT_MTR       := atlas.mtr/warp/invxfm.nii.gz
AT_MTR_JAC         := atlas.mtr/warp/logjacdet.nii.gz
NT_MTR_JAC         := native.mtr/warp/logjacdet.nii.gz

NT_MTR_MASK        := native.mtr/mask/brain.nii.gz
AT_MTR_MASK        := atlas.mtr/mask/brain.nii.gz
AT_MTR_TBSS_MASK   := atlas.mtr/mask/tbss.nii.gz

##############################################################################
# Constants 
##############################################################################

AT_REGIONS         :=
AT_REGIONS         += harris.gray
AT_REGIONS         += tissue.hemi

AT_PRIOR           := $(STATS)/Lesion/mask.nii.gz
AT_LESION_LUT      := $(STATS)/Lesion/rois.csv
AT_BRAIN_MASK      := $(ROOT)/data/masks/brain.nii.gz
AT_BRAIN_MGE       := $(ROOT)/data/reference/mge_mean.nii.gz
AT_BRAIN_DTI       := $(ROOT)/data/models.dti/dti_S0.nii.gz

BUNDLE_LIST        ?= $(ROOT)/data/tract/bundles.txt

##############################################################################
# Helper Functions 
##############################################################################

vol.mask  = $(QIT_CMD) VolumeMask \
              --input $(1) \
              --mask $(2) \
              --output $(3);

vol.xfm   = $(QIT_CMD) VolumeTransform \
              --interp Tricubic \
              --input $(1) \
              --reference $(2) \
              --deform $(3) \
              --output $(4);

param.xfm = $(QIT_CMD) VolumeTransform \
              --interp Tricubic \
              --input $(1)/$(5).nii.gz \
              --reference $(2) \
              --deform $(3) \
              --output $(4)/$(5).nii.gz; 

mask.xfm  = $(QIT_CMD) MaskTransform \
              --input $(1) \
              --reference $(2) \
              --deform $(3) \
              --output $(4);

harmonize = $(QIT_CMD) VolumeHarmonize \
              --input $(1)/$(2).nii.gz \
              --inputMask $(3) \
              --output $(4)/$(2).nii.gz;

zscore    = $(QIT_CMD) VolumeVoxelMathScalar \
              --a $(2)/$(3).nii.gz \
              --b $(STATS)/$(SITE)/control/$(3).$(1).mean.nii.gz \
              --c $(STATS)/$(SITE)/control/$(3).$(1).std.nii.gz \
              --mask $(ROOT)/data/masks/brain.nii.gz \
              --expression "(a - b) / c" \
              --output $(4)/$(3).nii.gz;

tbss      = $(FSLDIR)/bin/tbss_skeleton \
              -i $(ROOT)/data/models.dti/dti_FA.nii.gz \
              -p $(shell cat $(ROOT)/data/skeleton/thresh.txt) \
              $(ROOT)/data/skeleton/mean_FA_skeleton_mask_dst.nii.gz \
              $(ROOT)/data/masks/empty.nii.gz \
              $(AT_DWI_DTI)/dti_FA.nii.gz $2 -a $1;

mask.ms   = $(QIT_CMD) MaskRegionsMeasure --basic \
              --regions $(1)/rois.nii.gz \
              --lookup $(1)/rois.csv \
              --volume $(3)=$(2)/$(3).nii.gz \
              --mask $(4) \
              --output $(5);

whole.vertex.ms = $(QIT_CMD) CurvesMeasureBatch \
               --attrs $(5) \
               --names $(2) \
               --input $(1)/%s/$(7).vtk.gz \
               --volume $(5)=$(3)/$(4).nii.gz \
               --output $(6);

whole.voxel.ms = $(QIT_CMD) CurvesMeasureBatch \
               --voxel \
               --attrs $(5) \
               --names $(2) \
               --input $(1)/%s/$(7).vtk.gz \
               --volume $(5)=$(3)/$(4).nii.gz \
               --output $(6);

along.vertex.ms = $(QIT_CMD) CurvesMeasureAlongBatch \
               --iters $(ALONG_ITERS) \
               --attrs $(5) \
               --names $(2) \
               --input $(1)/%s/$(7).vtk.gz \
               --volume $(5)=$(3)/$(4).nii.gz \
               --output $(6);

along.voxel.ms = $(QIT_CMD) CurvesMeasureAlongBatch \
               --voxel \
               --attrs $(5) \
               --names $(2) \
               --input $(1)/%s/$(7).vtk.gz \
               --volume $(5)=$(3)/$(4).nii.gz \
               --output $(6);

##############################################################################
# Parameter Estimation - DWI 
##############################################################################

$(NT_SOURCE)/common/dwi.bvecs.txt: $(NT_SOURCE)
$(NT_SOURCE)/common/dwi.bvals.txt: $(NT_SOURCE)
$(NT_SOURCE)/common/dwi.nii.gz: $(NT_SOURCE)
$(NT_SOURCE)/common/mge.te.txt: $(NT_SOURCE)
$(NT_SOURCE)/common/mge.nii.gz: $(NT_SOURCE)
$(NT_SOURCE)/common/mt.low.nii.gz: $(NT_SOURCE)
$(NT_SOURCE)/common/mt.high.nii.gz: $(NT_SOURCE)

$(NT_RAW_BVECS): $(NT_SOURCE)/common/dwi.bvecs.txt
	-mkdir -p $(dir $@)
	cp $(word 1, $+) $@

$(NT_RAW_BVALS): $(NT_SOURCE)/common/dwi.bvals.txt
	-mkdir -p $(dir $@)
	cp $(word 1, $+) $@

$(NT_DWI_RAW): $(NT_SOURCE)/common/dwi.nii.gz $(NT_RAW_BVECS) $(NT_RAW_BVALS)
	$(QIT_CMD) VolumeStandardize \
    --input $(word 1, $+) \
    --xfm $(NT_DWI_XFM) \
    --invxfm $(NT_DWI_INVXFM) \
    --output $@
	$(QIT_CMD) VolumeDwiNormalize \
    --input $@ \
    --gradients $(word 2, $+) \
    --mean 1 \
    --output $@

$(NT_DWI_NLM): $(NT_DWI_RAW)
	bash $(ROOT)/bin/EpibiosAuxDenoise.sh $(word 1, $+) $@

$(NT_DWI_EDDY): $(NT_DWI_NLM) $(NT_RAW_BVECS) $(NT_RAW_BVALS)
	bash $(ROOT)/bin/EpibiosAuxDwiCorrect.sh $+ $@

$(NT_DWI_QA): $(NT_DWI_RAW) $(NT_DWI_NLM) $(NT_DWI_EDDY)
	$(QIT_CMD) VolumeDifferenceMap \
    --left $(word 1, $+) --right $(word 2, $+) \
    --prefix "dwi_" --output $@.noise.csv
	$(QIT_CMD) MapEddy \
    --input $(word 3, $+)/out.eddy_movement_rms \
    --output $@.motion.csv
	$(QIT_CMD) MapCatBatch --input $@.noise.csv $@.motion.csv --output $@
	rm $@.noise.csv $@.motion.csv

$(NT_DWI_INPUT): $(NT_DWI_EDDY)
	cp $(word 1, $+)/out.nii.gz $@

$(NT_DWI_BVALS): $(NT_DWI_EDDY)
	$(QIT_CMD) VectsTransform --rows --input $(word 1, $+)/bvals --output $@

$(NT_DWI_BVECS): $(NT_DWI_EDDY)
	$(QIT_CMD) VectsTransform --rows \
    --input $(word 1, $+)/out.eddy_rotated_bvecs --output $@

$(NT_DWI_ALL_DTI): $(NT_DWI_INPUT) $(NT_DWI_BVECS) $(NT_DWI_BVALS) 
	$(QIT_CMD) VolumeTensorFit \
    --method LLS \
    --input $(word 1, $+) \
    --gradients $(word 2, $+) \
    --output $@

$(NT_DWI_DTI): $(NT_DWI_INPUT) $(NT_DWI_BVECS) $(NT_DWI_BVALS) $(NT_DWI_BRAIN_MASK)
	$(QIT_CMD) VolumeTensorFit \
    --method WLLS \
    --input $(word 1, $+) \
    --gradients $(word 2, $+) \
    --mask $(word 4, $+) \
    --output $@

$(NT_DWI_FWDTI): $(NT_DWI_INPUT) $(NT_DWI_BVECS) $(NT_DWI_BVALS) $(NT_DWI_BRAIN_MASK)
	$(QIT_CMD) VolumeTensorFit \
    --method FWWLLS \
    --input $(word 1, $+) \
    --gradients $(word 2, $+) \
    --mask $(word 4, $+) \
    --output $@

$(NT_DWI_NODDI): $(NT_DWI_INPUT) $(NT_DWI_BVECS) $(NT_DWI_BVALS) $(NT_DWI_BRAIN_MASK)
	$(QIT_CMD) VolumeNoddiFit \
    --input $(word 1, $+) \
    --gradients $(word 2, $+) \
    --mask $(word 4, $+) \
    --output $@

$(NT_DWI_XFIB): $(NT_DWI_INPUT) $(NT_DWI_BVECS) $(NT_DWI_BVALS) $(NT_DWI_BRAIN_MASK)
	$(QIT_CMD) $(FIBERS_FIT) \
    --input $(word 1, $+) \
    --gradients $(word 2, $+) \
    --mask $(word 4, $+) \
    --output $@

$(NT_DWI_BRAIN_MASK): $(NT_DWI_ALL_DTI)
	$(QIT_CMD) VolumeBrainExtract \
    --input $(word 1, $+) \
    --output $@.tmp.nii.gz
	$(QIT_CMD) VolumeThreshold \
    --input $(word 1, $+)/dti_MD.nii.gz \
    --mask $@.tmp.nii.gz \
    --threshold 0.0003 \
    --output $@.tmp.nii.gz
	$(QIT_CMD) MaskFill \
    --input $@.tmp.nii.gz \
    --output $@.tmp.nii.gz
	mv $@.tmp.nii.gz $@

##############################################################################
# Parameter Estimation - MGE  
##############################################################################

$(NT_MGE_RAW): $(NT_SOURCE)/common/mge.nii.gz
	-mkdir -p $(dir $@)
	$(QIT_CMD) --fresh VolumeStandardize \
    --input $(word 1, $+) \
    --xfm $@.xfm.txt \
    --output $@.tmp.nii.gz
	$(QIT_CMD) VolumeCrop \
    --range $(MGE_CROP) \
    --input $@.tmp.nii.gz \
    --output $@
	rm $@.tmp.nii.gz

$(NT_MGE_MEAN_RAW): $(NT_MGE_RAW)
	$(QIT_CMD) VolumeReduce \
    --input $(word 1, $+) \
    --method Mean \
    --output $@

$(NT_MGE_NLM): $(NT_MGE_RAW)
	bash $(ROOT)/bin/EpibiosAuxDenoise.sh $(word 1, $+) $@

$(NT_MGE_QA): $(NT_MGE_RAW) $(NT_MGE_NLM)
	$(QIT_CMD) VolumeDifferenceMap \
    --left $(word 1, $+) --right $(word 2, $+) \
    --prefix "mge_" --output $@

$(NT_MGE_MEAN): $(NT_MGE_NLM)
	mkdir -p $(NT_MGE_MODEL)
	$(QIT_CMD) VolumeExpDecayFit \
    --start 2.73 --step 3.1 \
    --minBeta 0.00333 \
    --input $(NT_MGE_NLM) \
    --output $(NT_MGE_PARAMS)
	$(QIT_CMD) VolumeReduce \
    --input $(NT_MGE_PARAMS) \
    --which 0 \
    --output $(NT_MGE_BASE)
	$(QIT_CMD) VolumeReduce \
    --input $(NT_MGE_PARAMS) \
    --which 1 \
    --output $(NT_MGE_R2STAR)
	$(QIT_CMD) VolumeVoxelMathScalar \
    --a $(NT_MGE_R2STAR) \
    --expression "1.0 / a" \
    --output $(NT_MGE_T2STAR)
	$(QIT_CMD) VolumeReduce \
    --input $(NT_MGE_NLM) \
    --method Mean \
    --output $(NT_MGE_BIASED)
	$(QIT_CMD) VolumeVoxelMathScalar \
    --a $(NT_MGE_BIASED) --expression "a*5000" --output $(NT_MGE_BIASED)
	N4BiasFieldCorrection -i $(NT_MGE_BIASED) -o $@
	$(QIT_CMD) VolumeConvert --input $@ --output $@
$(NT_MGE_BIASED): $(NT_MGE_MEAN)

$(NT_MGE_MASK): $(NT_MGE_BIASED)
	$(ROOT)/bin/EpibiosAuxSkullStrip.sh $(word 1, $+) $@

##############################################################################
# Parameter Estimation - MTR
##############################################################################

$(NT_MTR_LOW_RAW): $(NT_SOURCE)/common/mt.low.nii.gz
	-mkdir -p $(dir $@)
	$(QIT_CMD) --fresh VolumeStandardize \
    --input $(word 1, $+) \
    --xfm $@.xfm.txt \
    --output $@.tmp.nii.gz
	$(QIT_CMD) VolumeCrop \
    --range $(MT_CROP) \
    --input $@.tmp.nii.gz \
    --output $@
	rm $@.tmp.nii.gz

$(NT_MTR_HIGH_RAW): $(NT_SOURCE)/common/mt.low.nii.gz
	-mkdir -p $(dir $@)
	$(QIT_CMD) --fresh VolumeStandardize \
    --input $(word 1, $+) \
    --xfm $@.xfm.txt \
    --output $@.tmp.nii.gz
	$(QIT_CMD) VolumeCrop \
    --range $(MT_CROP) \
    --input $@.tmp.nii.gz \
    --output $@
	rm $@.tmp.nii.gz

$(NT_MTR_LOW_NLM): $(NT_MTR_LOW_RAW)
	-mkdir -p $(dir $@)
	bash $(ROOT)/bin/EpibiosAuxDenoise.sh $(word 1, $+) $@

$(NT_MTR_HIGH_NLM): $(NT_MTR_HIGH_RAW)
	-mkdir -p $(dir $@)
	bash $(ROOT)/bin/EpibiosAuxDenoise.sh $(word 1, $+) $@

$(NT_MTR_MASK): $(NT_MTR_HIGH_NLM)
	-mkdir -p $(dir $@)
	$(ROOT)/bin/EpibiosAuxSkullStrip.sh $(word 1, $+) $@

$(NT_MTR_RATIO): $(NT_MTR_LOW_NLM) $(NT_MTR_HIGH_NLM)
	-mkdir -p $(dir $@)
	$(QIT_CMD) VolumeVoxelMathScalar \
    --a $(word 1, $+) \
    --b $(word 2, $+) \
    --expression "min(1.0, max(0.0, 1.0 - a/b))" \
    --output $@

$(NT_MTR_RATIO_RAW): $(NT_MTR_LOW_RAW) $(NT_MTR_HIGH_RAW)
	-mkdir -p $(dir $@)
	$(QIT_CMD) VolumeVoxelMathScalar \
    --a $(word 1, $+) \
    --b $(word 2, $+) \
    --expression "min(1.0, max(0.0, 1.0 - a/b))" \
    --output $@

##############################################################################
# Parameter Harmonization
##############################################################################

$(NT_DWI_FIT): $(NT_DWI_BRAIN_MASK) $(NT_DWI_DTI) $(if $(MULTI), $(NT_DWI_FWDTI) $(NT_DWI_NODDI))
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD, \
    $(call vol.mask, $(word 2, $+)/$(p).nii.gz, $(word 1, $+), $@.$(TMP)/$(p).nii.gz))
ifneq ($(MULTI),)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD dti_FW, \
    $(call vol.mask, $(word 3, $+)/$(p).nii.gz, $(word 1, $+), $@.$(TMP)/fw$(p).nii.gz))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
    $(call vol.mask, $(word 4, $+)/$(p).nii.gz, $(word 1, $+), $@.$(TMP)/$(p).nii.gz))
endif
	mv $@.$(TMP) $@

$(NT_MGE_FIT): $(NT_MGE_MASK) $(NT_MGE_MEAN)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
    $(call vol.mask, $(NT_MGE_MODEL)/$(p).nii.gz, $(word 1, $+), $@.$(TMP)/$(p).nii.gz))
	mv $@.$(TMP) $@

$(NT_MTR_FIT): $(NT_MTR_RATIO) $(NT_MTR_MASK)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(call vol.mask, $(word 1, $+), $(word 2, $+), $@.$(TMP)/mtr_ratio.nii.gz)
	mv $@.$(TMP) $@

$(NT_DWI_HARM): $(NT_DWI_BRAIN_MASK) $(NT_DWI_FIT)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD, \
    $(call harmonize,$(word 2, $+),$(p),$(word 1, $+),$@.$(TMP)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD fwdti_FW, \
    $(call harmonize,$(word 2, $+),$(p),$(word 1, $+),$@.$(TMP)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
    $(call harmonize,$(word 2, $+),$(p),$(word 1, $+),$@.$(TMP)))
endif
	mv $@.$(TMP) $@

$(NT_MGE_HARM): $(NT_MGE_MODEL) $(NT_MGE_MASK)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
    $(call harmonize,$(word 1, $+),$(p),$(word 2, $+),$@.$(TMP)))
	mv $@.$(TMP) $@

$(NT_MTR_HARM): $(NT_MTR_FIT) $(NT_MTR_MASK)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(call harmonize,$(word 1, $+),mtr_ratio,$(word 2, $+),$@.$(TMP))
	mv $@.$(TMP) $@

##############################################################################
# Registration
##############################################################################

$(AT_MGE_WARP): $(NT_MGE_MEAN)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(QIT_CMD) VolumeRegisterDeformAnts $(ANTS_FLAGS) \
    --input $(word 1, $+) \
    --ref $(ROOT)/data/reference/head.nii.gz \
    --output $(AT_MGE_WARP)
	mv $@.$(TMP) $@
$(AT_TO_NT_MGE): $(AT_MGE_WARP)
$(NT_TO_AT_MGE): $(AT_MGE_WARP)
$(AT_MGE_JAC): $(AT_MGE_WARP)

$(AT_MTR_WARP): $(NT_MTR_RATIO)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(QIT_CMD) VolumeRegisterDeformAnts $(ANTS_FLAGS) \
    --input $(word 1, $+) \
    --ref $(ROOT)/data/reference/head.nii.gz \
    --output $(AT_MTR_WARP)
	mv $@.$(TMP) $@
$(AT_TO_NT_MTR): $(AT_MTR_WARP)
$(NT_TO_AT_MTR): $(AT_MTR_WARP)
$(AT_MTR_JAC): $(AT_MTR_WARP)

$(AT_DWI_WARP): $(NT_DWI_DTI)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(QIT_CMD) VolumeRegisterDeformAnts $(ANTS_FLAGS) \
    --input $(word 1, $+)/dti_FA.nii.gz \
    --ref $(ROOT)/data/models.dti/dti_FA.nii.gz \
    --inputSecondary $(word 1, $+)/dti_MD.nii.gz \
    --refSecondary $(ROOT)/data/models.dti/dti_MD.nii.gz \
    --output $(AT_DWI_WARP)
	mv $@.$(TMP) $@
$(AT_TO_NT_DWI): $(AT_DWI_WARP)
$(NT_TO_AT_DWI): $(AT_DWI_WARP)
$(AT_DWI_JAC): $(AT_DWI_WARP)

$(AT_DWI_XFIB): $(NT_DWI_XFIB) $(NT_DWI_BRAIN_MASK) $(AT_TO_NT_DWI)
	$(QIT_CMD) VolumeFibersTransform \
    --input $(word 1, $+) \
    --inputMask $(word 2, $+) \
    --reference $(ROOT)/data/reference/brain.nii.gz \
    --mask $(ROOT)/data/masks/brain.nii.gz \
    --deform $(word 3, $+) \
    --output $@

$(NT_DWI_JAC): $(AT_DWI_JAC) $(NT_DWI_BRAIN_MASK) $(NT_TO_AT_DWI)
	$(call vol.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@)

$(NT_MGE_JAC): $(AT_MGE_JAC) $(NT_MGE_MASK) $(NT_TO_AT_MGE)
	$(call vol.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@)

$(NT_MTR_JAC): $(AT_MTR_JAC) $(NT_MTR_MASK) $(NT_TO_AT_MTR)
	$(call vol.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@)

$(AT_DWI_BRAIN_MASK): $(NT_DWI_BRAIN_MASK) $(AT_BRAIN_MASK) $(AT_TO_NT_DWI)
	$(call mask.xfm,$(word 1, $+), $(word 2, $+), $(word 3, $+),$@)

$(AT_MGE_MASK): $(NT_MGE_MASK) $(AT_BRAIN_MASK) $(AT_TO_NT_MGE)
	$(call mask.xfm,$(word 1, $+), $(word 2, $+), $(word 3, $+),$@)

$(AT_MTR_MASK): $(NT_MTR_MASK) $(AT_BRAIN_MASK) $(AT_TO_NT_MTR)
	$(call mask.xfm,$(word 1, $+), $(word 2, $+), $(word 3, $+),$@)

$(AT_DWI_FIT): $(NT_DWI_FIT) $(AT_BRAIN_MASK) $(AT_TO_NT_DWI)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
endif
	mv $@.$(TMP) $@

$(AT_MGE_FIT): $(NT_MGE_FIT) $(AT_BRAIN_MASK) $(AT_TO_NT_MGE)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
	mv $@.$(TMP) $@

$(AT_MTR_FIT): $(NT_MTR_FIT) $(AT_BRAIN_MASK) $(AT_TO_NT_MTR)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@,mtr_ratio)
	mv $@.$(TMP) $@

$(AT_DWI_HARM): $(NT_DWI_HARM) $(AT_BRAIN_MASK) $(AT_TO_NT_DWI)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD, \
  	$(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
endif
	mv $@.$(TMP) $@

$(AT_MGE_HARM): $(NT_MGE_HARM) $(AT_BRAIN_MASK) $(AT_TO_NT_MGE)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
  	$(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
	mv $@.$(TMP) $@

$(AT_MTR_HARM): $(NT_MTR_HARM) $(AT_BRAIN_MASK) $(AT_TO_NT_MTR)
	-rm -rf $@
	-mkdir -p $@.$(TMP)
	$(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@,mtr_ratio)
	mv $@.$(TMP) $@

##############################################################################
# Z-Scoring 
##############################################################################

$(AT_DWI_FITZ): $(AT_DWI_FIT)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD, \
    $(call zscore,raw,$(word 1, $+),$(p),$@.$(TMP)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
    $(call zscore,raw,$(word 1, $+),$(p),$@.$(TMP)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
    $(call zscore,raw,$(word 1, $+),$(p),$@.$(TMP)))
endif
	mv $@.$(TMP) $@

$(AT_MGE_FITZ): $(AT_MGE_FIT)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
    $(call zscore,raw,$(word 1, $+),$(p),$@.$(TMP)))
	mv $@.$(TMP) $@

$(AT_MTR_FITZ): $(AT_MTR_FIT)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(call zscore,raw,$(word 1, $+),mtr_ratio,$@.$(TMP))
	mv $@.$(TMP) $@

$(NT_DWI_FITZ): $(AT_DWI_FITZ) $(NT_DWI_BRAIN_MASK) $(NT_TO_AT_DWI)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
endif
	mv $@.$(TMP) $@

$(NT_MGE_FITZ): $(AT_MGE_FITZ) $(NT_MGE_MASK) $(NT_TO_AT_MGE)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
	mv $@.$(TMP) $@

$(NT_MTR_FITZ): $(AT_MTR_FITZ) $(NT_MTR_MASK) $(NT_TO_AT_MTR)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),mtr_ratio)
	mv $@.$(TMP) $@

$(AT_DWI_HARMZ): $(AT_DWI_HARM)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD, \
    $(call zscore,harm,$(word 1, $+),$(p),$@.$(TMP)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
    $(call zscore,harm,$(word 1, $+),$(p),$@.$(TMP)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
    $(call zscore,harm,$(word 1, $+),$(p),$@.$(TMP)))
endif
	mv $@.$(TMP) $@

$(AT_MGE_HARMZ): $(AT_MGE_HARM)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
    $(call zscore,harm,$(word 1, $+),$(p),$@.$(TMP)))
	mv $@.$(TMP) $@

$(AT_MTR_HARMZ): $(AT_MTR_HARM)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(call zscore,harm,$(word 1, $+),mtr_ratio,$@.$(TMP))
	mv $@.$(TMP) $@

$(NT_DWI_HARMZ): $(AT_DWI_HARMZ) $(NT_DWI_BRAIN_MASK) $(NT_TO_AT_DWI)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(foreach p,dti_S0 dti_FA dti_MD dti_AD dti_RD, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
endif
	mv $@.$(TMP) $@

$(NT_MGE_HARMZ): $(AT_MGE_HARMZ) $(NT_MGE_MASK) $(NT_TO_AT_MGE)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
    $(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),$(p)))
	mv $@.$(TMP) $@

$(NT_MTR_HARMZ): $(AT_MTR_HARMZ) $(NT_MTR_MASK) $(NT_TO_AT_MTR)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	$(call param.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@.$(TMP),mtr_ratio)
	mv $@.$(TMP) $@

##############################################################################
# Skeleton-based Segmentation
##############################################################################

$(AT_DWI_FIT_TBSS): $(AT_DWI_FIT)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,dti_S0 dti_FA dti_MD dti_RD dti_AD,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
ifneq ($(MULTI),)
	$(foreach m,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	$(foreach m,noddi_ficvf noddi_odi noddi_fiso, \
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
endif
	mv $@.$(TMP) $@

$(AT_DWI_HARM_TBSS): $(AT_DWI_HARM)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,dti_S0 dti_FA dti_MD dti_RD dti_AD,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
ifneq ($(MULTI),)
	$(foreach m,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	$(foreach m,noddi_ficvf noddi_odi noddi_fiso, \
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
endif
	mv $@.$(TMP) $@

$(AT_DWI_FITZ_TBSS): $(AT_DWI_FITZ)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,dti_S0 dti_FA dti_MD dti_RD dti_AD,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
ifneq ($(MULTI),)
	$(foreach m,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	$(foreach m,noddi_ficvf noddi_odi noddi_fiso, \
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
endif
	mv $@.$(TMP) $@

$(AT_DWI_HARMZ_TBSS): $(AT_DWI_HARMZ)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,dti_S0 dti_FA dti_MD dti_RD dti_AD,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
ifneq ($(MULTI),)
	$(foreach m,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	$(foreach m,noddi_ficvf noddi_odi noddi_fiso, \
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
endif

	mv $@.$(TMP) $@

$(AT_MGE_FIT_TBSS): $(AT_MGE_FIT)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,mge_mean mge_r2star mge_t2star,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	mv $@.$(TMP) $@

$(AT_MGE_HARM_TBSS): $(AT_MGE_HARM)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,mge_mean mge_r2star mge_t2star,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	mv $@.$(TMP) $@

$(AT_MGE_FITZ_TBSS): $(AT_MGE_FITZ)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,mge_mean mge_r2star mge_t2star,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	mv $@.$(TMP) $@

$(AT_MGE_HARMZ_TBSS): $(AT_MGE_HARMZ)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,mge_mean mge_r2star mge_t2star,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	mv $@.$(TMP) $@

$(AT_MTR_FIT_TBSS): $(AT_MTR_FIT)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,mtr_ratio,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	mv $@.$(TMP) $@

$(AT_MTR_HARM_TBSS): $(AT_MTR_HARM)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,mtr_ratio,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	mv $@.$(TMP) $@

$(AT_MTR_FITZ_TBSS): $(AT_MTR_FITZ)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,mtr_ratio,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	mv $@.$(TMP) $@

$(AT_MTR_HARMZ_TBSS): $(AT_MTR_HARMZ)
	-rm -rf $@
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	mkdir -p $@.$(TMP)
	$(foreach m,mtr_ratio,\
  	$(call tbss, $(word 1,$+)/$(m).nii.gz, $@.$(TMP)/$(m).nii.gz))
	mv $@.$(TMP) $@

$(AT_DWI_TBSS_MASK): $(AT_DWI_TISSUE_MASK)
	$(QIT_CMD) MaskIntersection \
    --left $(ROOT)/data/skeleton/mean_FA_skeleton_mask.nii.gz \
    --right $(word 1, $+) \
    --output $@

$(AT_MGE_TBSS_MASK): $(AT_MGE_TISSUE_MASK)
	$(QIT_CMD) MaskIntersection \
    --left $(ROOT)/data/skeleton/mean_FA_skeleton_mask.nii.gz \
    --right $(word 1, $+) \
    --output $@

$(AT_MTR_TBSS_MASK): $(AT_MTR_TISSUE_MASK)
	$(QIT_CMD) MaskIntersection \
    --left $(ROOT)/data/skeleton/mean_FA_skeleton_mask.nii.gz \
    --right $(word 1, $+) \
    --output $@

##############################################################################
# Region-based Segmentation
##############################################################################

define region.copy
$(eval MY_INPUT  := $(1))
$(eval MY_OUTPUT := $(2))

$(MY_OUTPUT): $(MY_INPUT)
	-@[ -e $$@ ] && mv -f $$@ $$@.$$(BCK)
	mkdir -p $$@
	cp -r $$(word 1, $$+)/rois.nii.gz $$@
	cp -r $$(word 1, $$+)/rois.csv $$@
endef

define region.warp
$(eval INPUT  := $(1))
$(eval REF    := $(2))
$(eval DEFORM := $(3))
$(eval OUTPUT := $(4))

$(OUTPUT): $(INPUT) $(REF) $(DEFORM)
	-@[ -e $$@ ] && mv -f $$@ $$@.$$(BCK)
	mkdir -p $$@.$$(TMP) 
	$$(call mask.xfm, $$(word 1, $$+)/rois.nii.gz, $$(word 2, $$+), $$(word 3, $$+), $$@.$$(TMP)/rois.nii.gz)
	-cp $$(word 1, $$+)/rois.csv $$@.$$(TMP)/rois.csv
	mv $$@.$$(TMP) $$@
endef

$(foreach r, $(AT_REGIONS), \
  $(eval $(call region.copy, $(ROOT)/data/region/$(r), atlas/region/$(r))))

$(foreach i, $(AT_REGIONS), \
  $(eval $(call region.warp, \
    atlas/region/$(i), $(NT_DWI_BRAIN_MASK), $(AT_TO_NT_DWI), native.region/$(i))))

##############################################################################
# Tractography-based Segmentation
##############################################################################

define bundle.seg
$(eval MY_NAME     := $(1))

$(eval MY_MODELS   := $(NT_DWI_XFIB))
$(eval MY_XFM      := $(NT_TO_AT_DWI))
$(eval MY_INVXFM   := $(AT_TO_NT_DWI))
$(eval MY_REF      := $(NT_DWI_BRAIN_MASK))
$(eval MY_DATA     := $(ROOT)/data/tract/bundles/$(MY_NAME))
$(eval MY_OUT      := native.dwi/tract)
$(eval MY_SRC      := $(MY_OUT)/bundles/$(MY_NAME))

$(eval MY_SEED     := $(MY_SRC)/seed.nii.gz)
$(eval MY_END      := $(MY_SRC)/end.nii.gz)
$(eval MY_INC      := $(MY_SRC)/include.nii.gz)
$(eval MY_EXC      := $(MY_SRC)/exclude.nii.gz)
$(eval MY_SEEDS    := $(MY_SRC)/seeds.txt.gz)
$(eval MY_PROTO    := $(MY_SRC)/proto.vtk.gz)
$(eval MY_CORE     := $(MY_SRC)/core.vtk.gz)
$(eval MY_TOM      := $(MY_SRC)/tom.nii.gz)
$(eval MY_CURVES   := $(MY_SRC)/curves.vtk.gz)
$(eval MY_TISSUE   := $(MY_SRC)/tissue.vtk.gz)
$(eval MY_LESION   := $(MY_SRC)/lesion.vtk.gz)
$(eval MY_SIMPLE   := $(MY_SRC)/simple.vtk.gz)
$(eval MY_LIST     := $(MY_OUT)/bundles.txt)

$(MY_SEED): $(MY_REF) $(MY_XFM)
	-mkdir -p $$(dir $$@)
	$(QIT_CMD) MaskTransformBatch \
    --threads $(QIT_THREADS) \
    --input $(MY_DATA)/%s.nii.gz \
    --names seed,include,exclude,end \
    --reference $$(word 1, $$+) \
    --deform $$(word 2, $$+) \
    --output $(MY_OUT)/bundles/$(MY_NAME)/%s.nii.gz
$(MY_INC): $(MY_SEED)
$(MY_EXC): $(MY_SEED)
$(MY_END): $(MY_SEED)

$(MY_SEEDS): $(MY_DATA)/seeds.txt.gz $(MY_INVXFM)
	-mkdir -p $$(dir $$@)
	$(QIT_CMD) VectsTransform \
    --input $$(word 1, $$+) \
    --deform $$(word 2, $$+) \
    --output $$@

$(MY_PROTO): $(MY_DATA)/proto.vtk.gz $(MY_INVXFM)
	-mkdir -p $$(dir $$@)
	$(QIT_CMD) CurvesTransform \
    --input $$(word 1, $$+) \
    --deform $$(word 2, $$+) \
    --output $$@

$(MY_TOM): $(MY_DATA)/tom.nii.gz $(MY_MODELS) $(MY_SEED) $(MY_XFM)
	-mkdir -p $$(dir $$@)
	$(QIT_CMD) VolumeFibersProjectVector $(PROJECT_FLAGS) \
    --angle $(PROJECT_ANGLE) \
    --norm $(PROJECT_NORM) \
    --frac $(PROJECT_FRAC) \
    --fsum $(PROJECT_FSUM) \
    --sigma $(PROJECT_SIGMA) \
    --smooth --restrict \
    --reference $$(word 1, $$+) \
    --input $$(word 2, $$+) \
    --mask $$(word 3, $$+) \
    --deform $$(word 4, $$+) \
    --threads $(QIT_THREADS) \
    --output $$@

ifeq ($(BUNDLE_METHOD),Hybrid)
$(MY_CURVES): $(MY_MODELS) $(MY_SEEDS) $(MY_INC) $(MY_EXC) $(MY_END) $(NT_DWI_ATLAS_MASK) $(MY_PROTO)
	-mkdir -p $$(dir $$@)
	$(eval MY_CURVES_TMP := $(MY_CURVES).$(TMP).vtk.gz)
	$(QIT_CMD) VolumeModelTrackStreamline $(BUNDLE_FLAGS) \
    --angle 90  \
    --min $(BUNDLE_MIN) \
    --step $(BUNDLE_STEP) \
    --interp $(BUNDLE_INTERP)  \
    --maxlen $(BUNDLE_MAXLEN) \
    --disperse $(BUNDLE_DISPERSE)  \
    --samplesFactor $(BUNDLE_FACTOR)  \
    --threads $(QIT_THREADS)  \
    --hybrid \
    --hybridAngle $(BUNDLE_ANGLE)  \
    --hybridDisperse ${BUNDLE_HYBDISP} \
    --hybridSamplesFactor $(BUNDLE_HYBFAC)  \
    --hybridProjFsum $(BUNDLE_HYBSUM) \
    --hybridPresmooth $(BUNDLE_SMOOTH) \
    --hybridPostsmooth $(BUNDLE_SMOOTH) \
    --input $$(word 1, $$+) \
    --seedVects $$(word 2, $$+) \
    --includeMask $$(word 3, $$+) \
    --hybridStopMask $$(word 4, $$+) \
    --hybridConnectMask $$(word 5, $$+) \
    --hybridTrackMask $$(word 6, $$+) \
    --output $(MY_CURVES_TMP)
	$(QIT_CMD) CurvesSegmentAlong $(ALONG_FLAGS) \
    --input $(MY_CURVES_TMP) \
    --proto $$(word 7, $$+) \
    --outputCore $(MY_CORE) \
    --output $(MY_CURVES_TMP)
	mv $(MY_CURVES_TMP) $(MY_CURVES)
else ifeq ($(BUNDLE_METHOD),Prior)
$(MY_CURVES): $(MY_TOM) $(MY_SEED) $(MY_INC) $(MY_EXC) $(MY_END) $(NT_DWI_ATLAS_MASK) $(MY_PROTO)
	-mkdir -p $$(dir $$@)
	$(eval MY_CURVES_TMP := $(MY_CURVES).$(TMP).vtk.gz)
	$(QIT_CMD) VolumeModelTrackStreamline $(BUNDLE_FLAGS) \
    --vector \
    --angle 90  \
    --min $(BUNDLE_MIN) \
    --step $(BUNDLE_STEP) \
    --interp $(BUNDLE_INTERP)  \
    --maxlen $(BUNDLE_MAXLEN) \
    --disperse $(BUNDLE_DISPERSE)  \
    --threads $(QIT_THREADS)  \
    --samplesFactor $(BUNDLE_FACTOR) \
    --input $$(word 1, $$+) \
    --seedMask $$(word 2, $$+) \
    --includeMask $$(word 3, $$+) \
    --excludeMask $$(word 4, $$+) \
    --includeAddMask $$(word 5, $$+) \
    --trackMask $$(word 6, $$+) \
    --output $(MY_CURVES_TMP)
	$(QIT_CMD) CurvesSegmentAlong $(ALONG_FLAGS) \
    --input $(MY_CURVES_TMP) \
    --proto $$(word 7, $$+) \
    --outputCore $(MY_CORE) \
    --output $(MY_CURVES_TMP)
	mv $(MY_CURVES_TMP) $(MY_CURVES)
else ifeq ($(BUNDLE_METHOD),Determ)
$(MY_CURVES): $(MY_MODELS) $(MY_SEED) $(MY_INC) $(MY_EXC) $(MY_END) $(NT_DWI_ATLAS_MASK) $(MY_PROTO)
	-mkdir -p $$(dir $$@)
	$(eval MY_CURVES_TMP := $(MY_CURVES).$(TMP).vtk.gz)
	$(QIT_CMD) VolumeModelTrackStreamline $(BUNDLE_FLAGS) \
    --angle $(BUNDLE_ANGLE)  \
    --min $(BUNDLE_MIN) \
    --step $(BUNDLE_STEP) \
    --interp $(BUNDLE_INTERP)  \
    --maxlen $(BUNDLE_MAXLEN) \
    --threads $(QIT_THREADS)  \
    --samplesFactor $(BUNDLE_FACTOR) \
    --input $$(word 1, $$+) \
    --seedMask $$(word 2, $$+) \
    --includeMask $$(word 3, $$+) \
    --excludeMask $$(word 4, $$+) \
    --includeAddMask $$(word 5, $$+) \
    --stopMask $$(word 4, $$+) \
    --connectMask $$(word 5, $$+) \
    --trackMask $$(word 6, $$+) \
    --output $(MY_CURVES_TMP)
	$(QIT_CMD) CurvesSegmentAlong $(ALONG_FLAGS) \
    --input $(MY_CURVES_TMP) \
    --proto $$(word 7, $$+) \
    --outputCore $(MY_CORE) \
    --output $(MY_CURVES_TMP)
	mv $(MY_CURVES_TMP) $(MY_CURVES)
else ifeq ($(BUNDLE_METHOD),Prob)
$(MY_CURVES): $(MY_MODELS) $(MY_SEED) $(MY_INC) $(MY_EXC) $(MY_END) $(NT_DWI_ATLAS_MASK) $(MY_PROTO)
	-mkdir -p $$(dir $$@)
	$(eval MY_CURVES_TMP := $(MY_CURVES).$(TMP).vtk.gz)
	$(QIT_CMD) VolumeModelTrackStreamline $(BUNDLE_FLAGS) \
    --prob \
    --angle $(BUNDLE_ANGLE)  \
    --min $(BUNDLE_MIN) \
    --step $(BUNDLE_STEP) \
    --interp Nearest \
    --maxlen $(BUNDLE_MAXLEN) \
    --disperse $(BUNDLE_DISPERSE)  \
    --threads $(QIT_THREADS)  \
    --samplesFactor $(BUNDLE_FACTOR) \
    --input $$(word 1, $$+) \
    --seedMask $$(word 2, $$+) \
    --includeMask $$(word 3, $$+) \
    --excludeMask $$(word 4, $$+) \
    --stopMask $$(word 4, $$+) \
    --connectMask $$(word 5, $$+) \
    --trackMask $$(word 6, $$+) \
    --output $(MY_CURVES_TMP)
	$(QIT_CMD) CurvesSegmentAlong $(ALONG_FLAGS) \
    --input $(MY_CURVES_TMP) \
    --proto $$(word 7, $$+) \
    --outputCore $(MY_CORE) \
    --output $(MY_CURVES_TMP)
	mv $(MY_CURVES_TMP) $(MY_CURVES)
endif

$(MY_TISSUE): $(MY_CURVES) $(NT_DWI_TISSUE_MASK)
	$(QIT_CMD) CurvesCrop \
    --input $$(word 1, $$+) \
    --mask $$(word 2, $$+) \
    --output $$@

$(MY_LESION): $(MY_CURVES) $(NT_DWI_LESION_MASK)
	$(QIT_CMD) CurvesCrop \
    --input $$(word 1, $$+) \
    --mask $$(word 2, $$+) \
    --output $$@

$(MY_SIMPLE): $(MY_CURVES) $(MY_MODELS) $(MY_TISSUE) $(MY_LESION)
	$(eval MY_SIMPLE_TMP := $(MY_CURVES).$(TMP).vtk.gz)
	$(QIT_CMD) CurvesClusterSCPT \
    --input $$(word 1, $$+) \
    --subset $(SIMPLE_COUNT) \
    --thresh $(SIMPLE_DIST) \
    --protos $(MY_SIMPLE_TMP)
	$(QIT_CMD) CurvesAttributes \
    --retain coord \
    --input $(MY_SIMPLE_TMP) \
    --output $(MY_SIMPLE_TMP)
	mv $(MY_SIMPLE_TMP) $$@

$(MY_LIST): $(MY_SIMPLE)
endef

##############################################################################
# Lesion Segmentation
##############################################################################

$(AT_DWI_LESION): $(AT_DWI_BRAIN_MASK) $(AT_PRIOR) $(AT_DWI_HARMZ)
	-rm -rf $@
	$(ROOT)/bin/EpibiosAuxSegmentLesion.sh \
    --mask $(word 1, $+) \
    --prior $(word 2, $+) \
    --heme $(word 3, $+)/dti_S0.nii.gz \
    --cavity $(word 3, $+)/dti_MD.nii.gz \
    --erode $(LESION_ERODE) \
    --zheme $(HEME_S0_ZSCORE) \
    --zcavity $(CAVITY_MD_ZSCORE) \
    --minvox $(LESION_MINVOX) \
    --levels $(PERILESION_LEVELS) \
    --output $@
$(AT_DWI_TISSUE_MASK): $(AT_DWI_LESION)
$(AT_DWI_LESION_MASK): $(AT_DWI_LESION)

$(AT_MGE_LESION): $(AT_MGE_MASK) $(AT_PRIOR) $(AT_MGE_HARMZ)
	-rm -rf $@
	$(ROOT)/bin/EpibiosAuxSegmentLesion.sh \
    --mask $(word 1, $+) \
    --prior $(word 2, $+) \
    --heme $(word 3, $+)/mge_t2star.nii.gz \
    --cavity $(word 3, $+)/mge_t2star.nii.gz \
    --erode $(LESION_ERODE) \
    --zheme $(HEME_T2S_ZSCORE) \
    --zcavity $(CAVITY_T2S_ZSCORE) \
    --minvox $(LESION_MINVOX) \
    --levels $(PERILESION_LEVELS) \
    --output $@
$(AT_MGE_TISSUE_MASK): $(AT_MGE_LESION)
$(AT_MGE_LESION_MASK): $(AT_MGE_LESION)

$(NT_DWI_ATLAS_MASK): $(AT_BRAIN_MASK) $(NT_DWI_BRAIN_MASK) $(NT_TO_AT_DWI)
	$(call mask.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@)

$(NT_MGE_ATLAS_MASK): $(AT_BRAIN_MASK) $(NT_MGE_BRAIN_MASK) $(NT_TO_AT_MGE)
	$(call mask.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@)

$(NT_DWI_PRIOR): $(AT_PRIOR) $(NT_DWI_BRAIN_MASK) $(NT_TO_AT_DWI)
	$(call mask.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@)

$(NT_MGE_PRIOR): $(AT_PRIOR) $(NT_MGE_MASK) $(NT_TO_AT_MGE)
	$(call mask.xfm, $(word 1, $+), $(word 2, $+), $(word 3, $+), $@)

$(NT_DWI_LESION): $(NT_DWI_BRAIN_MASK) $(NT_DWI_PRIOR) $(NT_DWI_HARMZ)
	-rm -rf $@
	$(ROOT)/bin/EpibiosAuxSegmentLesion.sh \
    --mask $(word 1, $+) \
    --prior $(word 2, $+) \
    --heme $(word 3, $+)/dti_S0.nii.gz \
    --cavity $(word 3, $+)/dti_MD.nii.gz \
    --erode $(LESION_ERODE) \
    --zheme $(HEME_S0_ZSCORE) \
    --zcavity $(CAVITY_MD_ZSCORE) \
    --minvox $(LESION_MINVOX) \
    --levels $(PERILESION_LEVELS) \
    --output $@
$(NT_DWI_TISSUE_MASK): $(NT_DWI_LESION)
$(NT_DWI_LESION_MASK): $(NT_DWI_LESION)

$(NT_MGE_LESION): $(NT_MGE_MASK) $(NT_MGE_PRIOR) $(NT_MGE_HARMZ)
	-rm -rf $@
	$(ROOT)/bin/EpibiosAuxSegmentLesion.sh \
    --mask $(word 1, $+) \
    --prior $(word 2, $+) \
    --heme $(word 3, $+)/mge_mean.nii.gz \
    --cavity $(word 3, $+)/mge_mean.nii.gz \
    --erode $(LESION_ERODE) \
    --zheme $(HEME_T2S_ZSCORE) \
    --zcavity $(CAVITY_T2S_ZSCORE) \
    --minvox $(LESION_MINVOX) \
    --levels $(PERILESION_LEVELS) \
    --output $@
$(NT_MGE_TISSUE_MASK): $(NT_MGE_LESION)
$(NT_MGE_LESION_MASK): $(NT_MGE_LESION)

$(AT_DWI_PERILESION): $(AT_DWI_LESION)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	cp $(word 1, $+)/rings.nii.gz $@.$(TMP)/rois.nii.gz
	cp $(word 1, $+)/rings.csv $@.$(TMP)/rois.csv
	mv $@.$(TMP) $@

$(NT_DWI_PERILESION): $(NT_DWI_LESION)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	cp $(word 1, $+)/rings.nii.gz $@.$(TMP)/rois.nii.gz
	cp $(word 1, $+)/rings.csv $@.$(TMP)/rois.csv
	mv $@.$(TMP) $@

$(AT_MGE_PERILESION): $(AT_MGE_LESION)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	cp $(word 1, $+)/rings.nii.gz $@.$(TMP)/rois.nii.gz
	cp $(word 1, $+)/rings.csv $@.$(TMP)/rois.csv
	mv $@.$(TMP) $@

$(NT_MGE_PERILESION): $(NT_MGE_LESION)
	-rm -rf $@
	mkdir -p $@.$(TMP)
	cp $(word 1, $+)/rings.nii.gz $@.$(TMP)/rois.nii.gz
	cp $(word 1, $+)/rings.csv $@.$(TMP)/rois.csv
	mv $@.$(TMP) $@

$(foreach n, $(shell cat $(BUNDLE_LIST)), \
  $(eval $(call bundle.seg, $(n))))

##############################################################################
# Statistical Mapping
##############################################################################

define region.map
$(eval MY_NAME        := $(1))
$(eval MY_PARAM       := $(2))

$(eval MY_REGIONS     := atlas/region/$(MY_NAME))
$(eval MY_DWI_MASK    := atlas.dwi/lesion/tissue.nii.gz)
$(eval MY_DWI_PARAM   := atlas.dwi/param/$(MY_PARAM))
$(eval MY_MGE_MASK    := atlas.mge/lesion/tissue.nii.gz)
$(eval MY_MGE_PARAM   := atlas.mge/param/$(MY_PARAM))

$(MY_REGIONS).dwi.$(MY_PARAM).map: $(MY_REGIONS) $(MY_DWI_PARAM) $(MY_DWI_MASK)
	-@[ -e $$@ ] && mv -f $$@ $$@.$$(BCK)
	$(foreach p,dti_S0 dti_FA dti_MD dti_RD dti_AD, \
	  $$(call mask.ms,$(MY_REGIONS),$(MY_DWI_PARAM),$(p),$(MY_DWI_MASK),$$@.$$(TMP)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
	  $$(call mask.ms,$(MY_REGIONS),$(MY_DWI_PARAM),$(p),$(MY_DWI_MASK),$$@.$$(TMP)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
	  $$(call mask.ms,$(MY_REGIONS),$(MY_DWI_PARAM),$(p),$(MY_DWI_MASK),$$@.$$(TMP)))
endif
	mv $$@.$$(TMP) $$@

$(MY_REGIONS).mge.$(MY_PARAM).map: $(MY_REGIONS) $(MY_MGE_PARAM) $(MY_MGE_MASK)
	-@[ -e $$@ ] && mv -f $$@ $$@.$$(BCK)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
	  $$(call mask.ms,$(MY_REGIONS),$(MY_MGE_PARAM),$(p),$(MY_MGE_MASK),$$@.$$(TMP)))
	mv $$@.$$(TMP) $$@
endef

define region.tbss.map
$(eval MY_NAME       := $(1))
$(eval MY_PARAM      := $(2))

$(eval MY_REGIONS     := atlas/region/$(MY_NAME))
$(eval MY_DWI_MASK    := atlas.dwi/lesion/tissue.nii.gz)
$(eval MY_DWI_PARAM   := atlas.dwi/param/$(MY_PARAM))
$(eval MY_MGE_MASK    := atlas.dwi/lesion/tissue.nii.gz)
$(eval MY_MGE_PARAM   := atlas.mge/param/$(MY_PARAM))

$(MY_REGIONS).dwi.tbss.$(MY_PARAM).map: $(MY_REGIONS) $(MY_DWI_PARAM) $(MY_DWI_MASK)
	-@[ -e $$@ ] && mv -f $$@ $$@.$$(BCK)
	$(foreach p,dti_S0 dti_FA dti_MD dti_RD dti_AD, \
	  $$(call mask.ms,$(MY_REGIONS),$(MY_DWI_PARAM),$(p),$(MY_DWI_MASK),$$@.$$(TMP)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
	  $$(call mask.ms,$(MY_REGIONS),$(MY_DWI_PARAM),$(p),$(MY_DWI_MASK),$$@.$$(TMP)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
	  $$(call mask.ms,$(MY_REGIONS),$(MY_DWI_PARAM),$(p),$(MY_DWI_MASK),$$@.$$(TMP)))
endif
	mv $$@.$$(TMP) $$@

$(MY_REGIONS).mge.tbss.$(MY_PARAM).map: $(MY_REGIONS) $(MY_MGE_PARAM) $(MY_MGE_MASK)
	-@[ -e $$@ ] && mv -f $$@ $$@.$$(BCK)
	$(foreach p,mge_mean mge_r2star mge_t2star, \
	  $$(call mask.ms,$(MY_REGIONS),$(MY_MGE_PARAM),$(p),$(MY_DWI_MASK),$$@.$$(TMP)))
	mv $$@.$$(TMP) $$@
endef

native.dwi/tract/bundles.txt: $(BUNDLE_LIST)
	cp $(word 1, $+) $@	

native.dwi/tract/bundles.curves.map: native.dwi/tract/bundles.txt $(BUNDLE_LIST) 
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	$(QIT_CMD) CurvesMeasureBatch \
    --threads $(QIT_THREADS) \
    --attrs volume num_curves diff_mean \
            density_mean density_median density_sum \
            length_mean length_median length_sum \
            frac_mean frac_median frac_sum \
            mag_mean mag_median mag_sum \
    --names $(BUNDLE_LIST) \
    --input native.dwi/tract/bundles/%s/curves.vtk.gz \
    --output $@.$(TMP)
	mv $@.$(TMP) $@

native.dwi/tract/bundles.tissue.map: native.dwi/tract/bundles.txt $(BUNDLE_LIST) 
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	$(QIT_CMD) CurvesMeasureBatch \
    --threads $(QIT_THREADS) \
    --attrs volume num_curves diff_mean \
            density_mean density_median density_sum \
            length_mean length_median length_sum \
            frac_mean frac_median frac_sum \
            mag_mean mag_median mag_sum \
    --names $(BUNDLE_LIST) \
    --input native.dwi/tract/bundles/%s/tissue.vtk.gz \
    --output $@.$(TMP)
	mv $@.$(TMP) $@

native.dwi/tract/bundles.lesion.map: native.dwi/tract/bundles.txt $(BUNDLE_LIST) 
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	$(QIT_CMD) CurvesMeasureBatch \
    --threads $(QIT_THREADS) \
    --attrs volume num_curves diff_mean \
            density_mean density_median density_sum \
            length_mean length_median length_sum \
            frac_mean frac_median frac_sum \
            mag_mean mag_median mag_sum \
    --names $(BUNDLE_LIST) \
    --input native.dwi/tract/bundles/%s/lesion.vtk.gz \
    --output $@.$(TMP)
	mv $@.$(TMP) $@

native.dwi/tract/bundles.curves.along.map: native.dwi/tract/bundles.txt $(BUNDLE_LIST)
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	$(QIT_CMD) CurvesMeasureAlongBatch \
    --attrs diff_mean frac_mean \
    --names $(BUNDLE_LIST) \
    --input native.dwi/tract/bundles/%s/curves.vtk.gz \
    --output $@.$(TMP)
	mv $@.$(TMP) $@

native.dwi/tract/bundles.tissue.along.map: native.dwi/tract/bundles.txt $(BUNDLE_LIST)
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	$(QIT_CMD) CurvesMeasureAlongBatch \
    --attrs diff_mean frac_mean \
    --names $(BUNDLE_LIST) \
    --input native.dwi/tract/bundles/%s/tissue.vtk.gz \
    --output $@.$(TMP)
	mv $@.$(TMP) $@

native.dwi/tract/bundles.lesion.along.map: native.dwi/tract/bundles.txt $(BUNDLE_LIST)
	-@[ -e $@ ] && mv -f $@ $@.$(BCK)
	$(QIT_CMD) CurvesMeasureAlongBatch \
    --attrs diff_mean frac_mean \
    --names $(BUNDLE_LIST) \
    --input native.dwi/tract/bundles/%s/lesion.vtk.gz \
    --output $@.$(TMP)
	mv $@.$(TMP) $@

define bundles.param.map
$(eval MY_IN     := $(1))
$(eval MY_LIST   := $(2))
$(eval MY_TYPE   := $(3))
$(eval MY_PARAM  := $(4))
$(eval MY_BUNDLE := $(5))

$(eval MY_SOURCE := native.dwi/param/$(MY_PARAM))

$(MY_IN).$(MY_BUNDLE).$(MY_TYPE).$(MY_PARAM).map: $(MY_IN).txt $(MY_LIST) $(MY_SOURCE)
	-@[ -e $$@ ] && mv -f $$@ $$@.$$(BCK)
	$(foreach p,dti_S0 dti_FA dti_MD dti_RD dti_AD, \
	  $$(call $(MY_TYPE).ms,$(MY_IN),$(MY_LIST),$(MY_SOURCE),$(p),$(p),$$@.$$(TMP),$(MY_BUNDLE)))
ifneq ($(MULTI),)
	$(foreach p,fwdti_S0 fwdti_FA fwdti_MD fwdti_AD fwdti_RD, fwdti_FW, \
	  $$(call $(MY_TYPE).ms,$(MY_IN),$(MY_LIST),$(MY_SOURCE),$(p),$(p),$$@.$$(TMP),$(MY_BUNDLE)))
	$(foreach p,noddi_ficvf noddi_odi noddi_fiso, \
	  $$(call $(MY_TYPE).ms,$(MY_IN),$(MY_LIST),$(MY_SOURCE),$(p),$(p),$$@.$$(TMP),$(MY_BUNDLE)))
endif
	mv $$@.$$(TMP) $$@
endef

$(foreach t, $(AT_REGIONS), \
	$(foreach p, fit fitz harm harmz, \
		$(eval $(call region.tbss.map,$(t),$(p))) \
			$(eval $(call region.map,$(t),$(p)))))

$(foreach b, curves tissue lesion, \
	$(foreach t, whole.vertex whole.voxel whole.core along.vertex along.voxel along.core, \
		$(foreach p, fit fitz harm harmz, \
			$(eval $(call bundles.param.map, native.dwi/tract/bundles, $(BUNDLE_LIST), $(t), $(p), $(b))))))

##############################################################################
# Quality Control 
##############################################################################

VIS_ANAT_TARS   :=
VIS_LESION_TARS :=

define vis 
$(eval MY_INPUT   := $(1))
$(eval MY_PARAM   := $(2))
$(eval MY_MASK    := $(3))
$(eval MY_WINDOW  := $(4))
$(eval MY_OUTPUT  := $(5))

$(eval MY_ANAT    := $(MY_OUTPUT)_anatomy.png)
$(eval MY_LESION  := $(MY_OUTPUT)_lesion.png)

$(MY_ANAT): $(MY_INPUT) $(ROOT)/data/masks/empty.nii.gz
	$(QIT_CMD) VolumeRender \
    --bghigh threeup \
    --alpha 1.0 \
    --discrete pastel \
    --background $$(word 1, $$+)/$(MY_PARAM) \
    --bgmask $(ROOT)/data/masks/brain.nii.gz \
    --labels $$(word 2, $$+) \
    --output $$@.nii.gz
	$(QIT_CMD) VolumeMosaic \
    --crop :,:,$(MY_WINDOW) \
    --rgb --axis k \
    --input $$@.nii.gz \
    --output $$@
	rm $$@.nii.gz

$(MY_LESION): $(MY_INPUT) $(MY_MASK)
	$(QIT_CMD) VolumeRender \
    --bghigh threeup \
    --alpha 1.0 \
    --discrete pastel \
    --background $$(word 1, $$+)/$(MY_PARAM) \
    --bgmask $(ROOT)/data/masks/brain.nii.gz \
    --labels $$@.shell.nii.gz \
    --labels $$(word 2, $$+) \
    --output $$@.nii.gz
	$(QIT_CMD) VolumeMosaic \
    --crop :,:,$(MY_WINDOW) \
    --rgb --axis k \
    --input $$@.nii.gz \
    --output $$@
	rm $$@.nii.gz

VIS_ANAT_TARS   += $(MY_ANAT)
VIS_LESION_TARS += $(MY_LESION)
endef

$(foreach p,S0 FA MD, \
  $(eval $(call vis,$(AT_DWI_HARM),dti_$(p).nii.gz,$(AT_DWI_LESION_MASK),$(VIS_CROP),$(AT_DWI_VIS)/large_dti_$(p))) \
  $(eval $(call vis,$(AT_DWI_HARM),dti_$(p).nii.gz,$(AT_DWI_LESION_MASK),$(VIS_CROP_SMALL),$(AT_DWI_VIS)/small_dti_$(p))))

$(foreach p,mean r2star t2star, \
	$(eval $(call vis, $(AT_MGE_HARM),mge_$(p).nii.gz,$(AT_MGE_LESION_MASK),$(VIS_CROP),$(AT_MGE_VIS)/large_mge_$(p))) \
	$(eval $(call vis, $(AT_MGE_HARM),mge_$(p).nii.gz,$(AT_MGE_LESION_MASK),$(VIS_CROP_SMALL),$(AT_MGE_VIS)/small_mge_$(p))))

$(NT_DWI_RESIDUAL): $(NT_DWI_BRAIN_MASK) $(NT_DWI_INPUT) $(NT_DWI_BVECS) 
	$(eval TMP := tmp.$(shell date +%s))
	rm -rf $@
	mkdir -p $@.$(TMP)
	$(QIT_CMD) MaskErode --num 3 \
    --input $(word 1, $+) \
    --output $@.$(TMP)/mask.nii.gz
	$(QIT_CMD) VolumeDwiFeature \
    --feature NoiseStd \
    --input $(word 2, $+) \
    --gradients $(word 3, $+) \
    --output $@.$(TMP)/residual.std.nii.gz
	$(QIT_CMD) VolumeMeasure \
    --input $@.$(TMP)/residual.std.nii.gz \
    --mask $@.$(TMP)/mask.nii.gz \
    --output $@.$(TMP)/residual.std.csv
	$(QIT_CMD) VolumeDwiFeature \
    --feature NoiseCoeffVar \
    --input $(word 2, $+) \
    --gradients $(word 3, $+) \
    --output $@.$(TMP)/residual.cv.nii.gz
	$(QIT_CMD) VolumeMeasure \
    --input $@.$(TMP)/residual.cv.nii.gz \
    --mask $@.$(TMP)/mask.nii.gz \
    --output $@.$(TMP)/residual.cv.csv
	mv $@.$(TMP) $@

$(NT_MGE_RESIDUAL): $(NT_MGE_MASK) $(NT_MGE_MEAN) $(NT_MGE_MEAN_RAW)
	$(eval TMP := tmp.$(shell date +%s))
	rm -rf $@
	mkdir -p $@.$(TMP)
	$(QIT_CMD) MaskErode --num 3 \
    --input $(word 1, $+) \
    --output $@.$(TMP)/mask.nii.gz
	$(QIT_CMD) VolumeVoxelMathScalar \
    --a $(word 2, $+) \
    --b $(word 3, $+) \
    --expression "abs(a - b) / a" \
    --output $@.$(TMP)/residual.nii.gz
	$(QIT_CMD) VolumeMeasure \
    --input $@.$(TMP)/residual.nii.gz \
    --mask $@.$(TMP)/mask.nii.gz \
    --output $@.$(TMP)/residual.csv
	mv $@.$(TMP) $@

$(NT_MTR_RESIDUAL): $(NT_MTR_MASK) $(NT_MTR_RATIO) $(NT_MTR_RAW)
	$(eval TMP := tmp.$(shell date +%s))
	rm -rf $@
	mkdir -p $@.$(TMP)
	$(QIT_CMD) MaskErode --num 3 \
    --input $(word 1, $+) \
    --output $@.$(TMP)/mask.nii.gz
	$(QIT_CMD) VolumeVoxelMathScalar \
    --a $(word 2, $+) \
    --b $(word 3, $+) \
    --expression "abs(a - b) / a" \
    --output $@.$(TMP)/residual.nii.gz
	$(QIT_CMD) VolumeMeasure \
    --input $@.$(TMP)/residual.nii.gz \
    --mask $@.$(TMP)/mask.nii.gz \
    --output $@.$(TMP)/residual.csv
	mv $@.$(TMP) $@

##############################################################################
# Summary targets 
##############################################################################

all.vis: $(VIS_ANAT_TARS) $(VIS_LESION_TARS)

all.qa: $(AT_DWI_RESIDUAL) $(AT_MGE_RESIDUAL) $(NT_DWI_QA) $(NT_MGE_QA)

all.tract: \
	$(foreach t, curves tissue lesion, \
		native.dwi/tract/bundles.$(t).map) \
	$(foreach b, curves tissue lesion, \
  	$(foreach m, whole, \
			$(foreach t, vertex voxel, \
				$(foreach p, fit fitz harm harmz, \
					native.dwi/tract/bundles.$(b).$(m).$(t).$(p).map))))

all.region: \
	$(foreach t, $(AT_REGIONS), \
		$(foreach p, fit fitz harm harmz, \
      atlas/region/$(t).dwi.tbss.$(p).map \
      atlas/region/$(t).mge.tbss.$(p).map \
      atlas/region/$(t).dwi.$(p).map \
      atlas/region/$(t).mge.$(p).map))

all: all.vis all.qa all.region all.tract $(AT_DWI_XFIB)

params: $(VIS_ANAT_TARS) $(AT_DWI_HARM) $(AT_MGE_HARMZ) $(AT_DWI_FIT) $(AT_MGE_FITZ) 

zscores: params \
         $(AT_DWI_HARM) $(AT_MGE_HARMZ) $(AT_DWI_FITZ) $(AT_MGE_FITZ) \
         $(NT_DWI_HARMZ) $(NT_MGE_HARMZ) $(NT_DWI_FITZ) $(NT_MGE_FITZ)

lesion: zscores $(VIS_LESION_TARS) \
        $(AT_DWI_LESION) $(AT_MGE_LESION) $(NT_DWI_LESION) $(NT_MGE_LESION)

################################################################################
