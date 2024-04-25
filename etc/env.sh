#export PATH=$PATH:/opt/cactus/bin/
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cactus/lib/

## environments for ALCOR DAQ
export DRICH_OUT=${HOME}/DATA
export ALCOR_DIR=${HOME}/alcor/alcor-utils
export ALCOR_LIB=${ALCOR_DIR}/lib
export ALCOR_CONF=${ALCOR_DIR}/conf
export ALCOR_ETC=${ALCOR_DIR}/etc
export PYTHONPATH=${ALCOR_LIB}
export PCR_DIR=${ALCOR_CONF}/pcr
export BCR_DIR=${ALCOR_CONF}/bcr

alias alcgui="${ALCOR_LIB}/alcorGUI.sh"
