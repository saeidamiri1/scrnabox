#/bin/bash

unset RUN_NAME LIBRARY FEATURE_REF EXPECT_CELLS SLURM_TEMPLATE failure REF_DIR

############
# FUNCTION TO PRINT HELP MESSAGE
############
Usage() {
        echo
        echo -e "Usage:\t$0 [arguments]"
        echo -e "\tmandatory arguments:\n" \
          "\t\t-r  (--run_name)         run name, serves as prefix for output files\n"
        echo -e "\toptional arguments:\n" \
          "\t\t-l  (--library_csv)      /path/to/library.csv file       (default: ./library.csv)\n" \
          "\t\t-f  (--feature_ref_csv)  /path/to/feature_ref.csv file   (default: ./feature_ref.csv)\n" \
          "\t\t-c  (--expect_cells)     expected # of cells             (default: 6000)\n" \
          "\t\t-t  (--slurm_template)   /path/to/slurm.template file    (default: ./slurm.template)\n" \
          "\t\t-h  (--help)             run this help message and exit\n"
        echo
}

############
# PARSE ARGUMENTS
############
if ! options=$(getopt --name $(basename $0) --alternative --unquoted --options hr:l:f:c:t: --longoptions run_name:,library_csv:,feature_ref_csv:,expect_cells:,slurm_template:,help -- "$@")
then
    # something went wrong, getopt will put out an error message for us
    echo "Error processing options."
    exit 42
fi

set -- $options
while [ $# -gt 0 ]
do
    case $1 in
    -h| --help) Usage; exit 0;;
    -r| --run_name) RUN_NAME="$2"; shift ;;
    -l| --library_csv) LIBRARY="$2"; shift ;;
    -f| --feature_ref_csv) FEATURE_REF="$2"; shift ;;
    -c| --expect_cells) EXPECT_CELLS="$2"; shift ;;
    -t| --slurm_template) SLURM_TEMPLATE="$2"; shift ;;
    (--) shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; failure=1;;
    (*) break;;
    esac
    shift
done

############
# CHECK INPUTS FOR ERRORS
############
[[ -z ${RUN_NAME} ]] && echo "error: run name must be specified with -r or --run_name" && failure=1
[[ $failure -eq 1 ]] && echo "ERRORS FOUND. Exiting" && exit 42

############
# SET DEFAULT AND OTHER VARIABLES
############
LIBRARY=${LIBRARY:-./library.csv}
FEATURE_REF=${FEATURE_REF:-./feature_ref.csv}
EXPECT_CELLS=${EXPECT_CELLS:-6000}
SLURM_TEMPLATE=${SLURM_TEMPLATE:-./slurm.template}
REF_DIR=/cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh38/genome/10xGenomics/refdata-cellranger-GRCh38-3.0.0

############
# RUN CELLRANGER
############
module use /cvmfs/soft.mugqic/CentOS6/modulefiles
module load mugqic/cellranger/5.0.1

cellranger count  \
    --id=${RUN_NAME} \
    --libraries=${LIBRARY} \
    --feature-ref=${FEATURE_REF} \
    --transcriptome=${REF_DIR} \
    --mempercore=30\
    --expect-cells=${EXPECT_CELLS} \
    --jobmode=${SLURM_TEMPLATE} \
2>&1|tee -a ${RUN_NAME}.$(date +%Y%m%d_%H%M).log
