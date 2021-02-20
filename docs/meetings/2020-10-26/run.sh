#! /bin/bash

cd $(dirname $0)

cp geom/bundles.vtk.gz geom/bundles.stats.vtk.gz

function project
{
  qit --verbose CurvesSetAttributeLookupTable \
    --curves geom/bundles.stats.vtk.gz \
    --lookup geom/bundles.csv \
    --table stats/${1}.csv \
    --value $2 \
    --cvalue $3 \
    --mergeTable metric \
    --mergeLookup along_name \
    --index along_index \
    --output geom/bundles.stats.vtk.gz
}


prefix=param.native.tract.bundles.along.dwi
for site in Finland Melbourne UCLA Combined; do
  for stat in pval; do
    project ${prefix}.raw.map.dti_FA_mean.site.${site}.tp.9d         ${stat} ${site}_raw_${stat}
    project ${prefix}.harm.zscore.map.dti_FA_mean.site.${site}.tp.9d ${stat} ${site}_zsc_${stat}
  done
done
