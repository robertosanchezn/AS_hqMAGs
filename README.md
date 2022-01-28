# bgcflow_AS_hqMAGs
This repository contains the code required to reproduce the analysis of BGCs diversity in 1000 MAGs from waste water treatment plant in Denmark. The genomes are publicly available from https://www.ncbi.nlm.nih.gov/bioproject/prjna629478.

# Correspondence
robertosan97@gmail.com

# Usage
## 1. Generate the data required for Analysis
- Install snakemake and get a clone of BGCflow, following the instructions in https://github.com/NBChub/bgcflow:
```shell
git clone git@github.com:NBChub/bgcflow.git
```
- Set up the configuration files by copying the content in `/bgcflow_configuration` folder (replacing the original `config.yaml` in BGCflow)
- Run the analysis as instructed in BGCflow. Might be a good idea to do a dry run first by:
```shell
snakemake --use-conda --cores 64 --keep-going -n
```
- remove the `-n` to do a real run

## 2. Analyse the data
To generate the figures, run the analysis inside the `r_markdown` folder or `jupyter_notebook` folder. Each folder has its own `README.md` to with instructions to run the analysis.