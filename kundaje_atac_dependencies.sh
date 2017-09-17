#!/bin/bash
# Stop on error
set -e

## /mnt/anaconda3/bin/conda environment name

ENV_NAME=bds_atac
ENV_NAME_PY3=bds_atac_py3

## install wiggler or not

INSTALL_WIGGLER_AND_MCR=0
INSTALL_GEM=0
INSTALL_PEAKSEQ=0

## install packages from official channels (bio/mnt/anaconda3/bin/conda and r)

/mnt/anaconda3/bin/conda create -n ${ENV_NAME} --file requirements.txt -y -c defaults -c bio/mnt/anaconda3/bin/conda -c r -c bcbio -c daler -c asmeurer
/mnt/anaconda3/bin/conda create -n ${ENV_NAME_PY3} --file requirements_py3.txt -y -c defaults -c bio/mnt/anaconda3/bin/conda -c r -c bcbio -c daler -c asmeurer

### bash function definition

function add_to_activate {
  if [ ! -f $/mnt/anaconda3/bin/conda_INIT ]; then
    echo > $/mnt/anaconda3/bin/conda_INIT
  fi
  for i in "${CONTENTS[@]}"; do
    if [ $(grep "$i" "$/mnt/anaconda3/bin/conda_INIT" | wc -l ) == 0 ]; then
      echo $i >> "$/mnt/anaconda3/bin/conda_INIT"
    fi
  done
}

## install useful tools for BigDataScript

mkdir -p $HOME/.bds
cp --remove-destination ./utils/bds_scr ./utils/bds_scr_5min ./utils/kill_scr bds.config $HOME/.bds/
cp --remove-destination -rf ./utils/clusterGeneric/ $HOME/.bds/

## install additional packages

source activate ${ENV_NAME}

/mnt/anaconda3/bin/conda uninstall graphviz -y # graphviz in bio/mnt/anaconda3/bin/conda has segmentation fault bug
/mnt/anaconda3/bin/conda install graphviz -c ana/mnt/anaconda3/bin/conda -y

/mnt/anaconda3/bin/conda install ucsc-bedgraphtobigwig -c bio/mnt/anaconda3/bin/conda -y
/mnt/anaconda3/bin/conda install ucsc-bedtobigbed -c bio/mnt/anaconda3/bin/conda -y

/mnt/anaconda3/bin/conda_BIN=$(dirname $(which activate))
/mnt/anaconda3/bin/conda_EXTRA="$/mnt/anaconda3/bin/conda_BIN/../extra"
/mnt/anaconda3/bin/conda_ACTIVATE_D="$/mnt/anaconda3/bin/conda_BIN/../etc//mnt/anaconda3/bin/conda/activate.d"
/mnt/anaconda3/bin/conda_INIT="$/mnt/anaconda3/bin/conda_ACTIVATE_D/init.sh"
/mnt/anaconda3/bin/conda_LIB="$/mnt/anaconda3/bin/conda_BIN/../lib"
if [[ $(find $/mnt/anaconda3/bin/conda_LIB -name '*egg-info*' -not -perm -o+r | wc -l ) > 0 ]]; then
  find $/mnt/anaconda3/bin/conda_LIB -name '*egg-info*' -not -perm -o+r -exec dirname {} \; | xargs chmod o+r -R
fi

mkdir -p $/mnt/anaconda3/bin/conda_EXTRA $/mnt/anaconda3/bin/conda_ACTIVATE_D

### install Anshul's phantompeakqualtool
cd $/mnt/anaconda3/bin/conda_EXTRA
git clone https://github.com/kundajelab/phantompeakqualtools
chmod 755 -R phantompeakqualtools
CONTENTS=("export PATH=$/mnt/anaconda3/bin/conda_EXTRA/phantompeakqualtools:\$PATH")
add_to_activate

### disable locally installed python package lookup
CONTENTS=("export PYTHONNOUSERSITE=True")
add_to_activate

if [ ${INSTALL_WIGGLER_AND_MCR} == 1 ]; then
  /mnt/anaconda3/bin/conda install -y -c /mnt/anaconda3/bin/conda-forge bc
  ### install Wiggler (for generating signal tracks)
  cd $/mnt/anaconda3/bin/conda_EXTRA
  wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/align2rawsignal/align2rawsignal.2.0.tgz -N --no-check-certificate
  tar zxvf align2rawsignal.2.0.tgz
  rm -f align2rawsignal.2.0.tgz
  CONTENTS=("export PATH=\$PATH:$/mnt/anaconda3/bin/conda_EXTRA/align2rawsignal/bin")
  add_to_activate

  ### install MCR (560MB)
  cd $/mnt/anaconda3/bin/conda_EXTRA
  wget http://mitra.stanford.edu/kundaje/software/MCR2010b.bin -N --no-check-certificate
  #wget https://personal.broadinstitute.org/anshul/softwareRepo/MCR2010b.bin -N --no-check-certificate
  chmod 755 MCR2010b.bin
  echo '-P installLocation="'${/mnt/anaconda3/bin/conda_EXTRA}'/MATLAB_Compiler_Runtime"' > tmp.stdin
  ./MCR2010b.bin -silent -options "tmp.stdin"
  rm -f tmp.stdin
  rm -f MCR2010b.bin
  CONTENTS=(
  "MCRROOT=${/mnt/anaconda3/bin/conda_EXTRA}/MATLAB_Compiler_Runtime/v714" 
  "LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${MCRROOT}/runtime/glnxa64" 
  "LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${MCRROOT}/bin/glnxa64" 
  "MCRJRE=\${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64" 
  "LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${MCRJRE}/native_threads" 
  "LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${MCRJRE}/server" 
  "LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${MCRJRE}" 
  "XAPPLRESDIR=\${MCRROOT}/X11/app-defaults" 
  "export LD_LIBRARY_PATH" 
  "export XAPPLRESDIR")
  add_to_activate
fi

# install PeakSeq
if [ ${INSTALL_PEAKSEQ} == 1 ]; then
  cd $/mnt/anaconda3/bin/conda_EXTRA
  wget http://archive.gersteinlab.org/proj/PeakSeq/Scoring_ChIPSeq/Code/C/PeakSeq_1.31.zip -N --no-check-certificate
  unzip PeakSeq_1.31.zip
  rm -f PeakSeq_1.31.zip
  cd PeakSeq
  make
  chmod 755 bin/PeakSeq
  cd $/mnt/anaconda3/bin/conda_BIN
  ln -s $/mnt/anaconda3/bin/conda_EXTRA/PeakSeq/bin/PeakSeq
fi

source deactivate


source activate ${ENV_NAME_PY3}

/mnt/anaconda3/bin/conda_BIN=$(dirname $(which activate))
/mnt/anaconda3/bin/conda_EXTRA="$/mnt/anaconda3/bin/conda_BIN/../extra"
mkdir -p $/mnt/anaconda3/bin/conda_EXTRA

### uninstall IDR 2.0.3 and install the latest one
/mnt/anaconda3/bin/conda uninstall idr -y
cd $/mnt/anaconda3/bin/conda_EXTRA
git clone https://github.com/kundajelab/idr
cd idr
python3 setup.py install
cd $/mnt/anaconda3/bin/conda_EXTRA
rm -rf idr

# install GEM
if [ ${INSTALL_GEM} == 1 ]; then
  cd $/mnt/anaconda3/bin/conda_EXTRA
  wget http://groups.csail.mit.edu/cgs/gem/download/gem.v3.0.tar.gz -N --no-check-certificate
  tar zxvf gem.v3.0.tar.gz  
  rm -f gem.v3.0.tar.gz  
  cd gem
  chmod 755 gem.jar
  cd $/mnt/anaconda3/bin/conda_BIN
  ln -s $/mnt/anaconda3/bin/conda_EXTRA/gem/gem.jar
fi

source deactivate


echo == Installing dependencies has been successfully done. ==