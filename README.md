[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/robertosanchezn/AS_hqMAGs/main)
# bgcflow_AS_hqMAGs
- This repository contains the code required to reproduce the analysis from the manuscript **_Sánchez-Navarro et al. 2022. Long-Read Metagenome-Assembled Genomes Improve Identification of Novel Complete Biosynthetic Gene Clusters in a AQ: A Complex Microbial-Activated Sludge Ecosystem_**.

# Preview analyses notebooks
- [AS_hqMAGs](https://htmlpreview.github.io/?https://github.com/robertosanchezn/AS_hqMAGs/blob/main/r_markdown/AS_hqMAGs.html)
- [p__Myxococcota](https://htmlpreview.github.io/?https://github.com/robertosanchezn/AS_hqMAGs/blob/main/r_markdown/Myxo.html)
- [p__Nitrospirota](https://htmlpreview.github.io/?https://github.com/robertosanchezn/AS_hqMAGs/blob/main/r_markdown/Nitro.html)

# Correspondence
robertosan97@gmail.com

# Usage
Follow these steps to reproduce the analysis and data generated in this study.

## Clone this repository
Clone this repository to your local machine by:
```bash
git clone git@github.com:robertosanchezn/AS_hqMAGs.git
cd AS_hqMAGs
```

## Run the analysis
To generate the figures in the manuscript, run the analysis inside the `r_markdown` folder or `jupyter_notebook` folder. Each folder has its own `README.md` to with instructions to run the analysis.

## Reproduce the data
### 1. Install Conda Environments & BGCFlow
- This analysis was done in Microsoft Azure Virtual Machine running on Linux (ubuntu 20.04).
- Get a clone of BGCflow, following the instructions at https://github.com/NBChub/bgcflow:
```bash
git clone git@github.com:NBChub/bgcflow.git
cd bgcflow
```
- Switch to branch v0.3.3-alpha (where this study was conducted)
```bash
git checkout v0.3.3-alpha
```
- Installing Snakemake using [Mamba](https://github.com/mamba-org/mamba) is advised. In case you don’t use [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge) you can always install [Mamba](https://github.com/mamba-org/mamba) into any other Conda-based Python distribution with:
```bash
conda install -n base -c conda-forge mamba
```
- Install conda environments
```bash
# snakemake environment
mamba create -c conda-forge -c bioconda -n snakemake snakemake=7.6.1

# environment to run notebooks
mamba env create -n workflow/envs/bgc_analytics.yaml
```
### 2. Snakemake configuration set up
- Set up the configuration files by copying the content in `/bgcflow_configuration` folder (replacing the original `config.yaml` in BGCflow)
```shell
cp ../bgcflow_config/* config/. -r
```
### 3. Download and prepare data from other studies
- Not all of the genomes are hosted in NCBI, and some fasta files needs cleaning. Run the notebook to grab all custom fasta files to `data/raw/fasta`.
```shell
# run notebook to download genomes from other studies to bgcflow/data/external, will take a while to finish
conda activate bgc_analytics
(cd ../jupyter_notebook/notebook2/ && jupyter nbconvert --to html --execute 01_other_MAG_dataset_table.ipynb)
conda deactivate

# generate symlink
ext_dir="data/external"
for directory in Bickhart_et_al Chen_et_al_sanitized Liu_et_al Sharrar_et_al_sanitized;
do
    for fna in $ext_dir/$directory/*.fna
    do
        (cd data/raw/fasta && ln -s ../../external/$directory/$(basename $fna) $(basename $fna) --verbose)
    done
done
```
### 4. Run the workflow for each individual study
This will generate antiSMASH results and other downstream processes.
```bash
conda activate snakemake
snakemake --use-conda --cores 8 --keep-going -n
conda deactivate
```
- **PS**: remove the args `-n` to do a real run

### 5. Run the workflow for all study comparison
This will generate antiSMASH results and other downstream processes.
```bash
conda activate snakemake
snakemake --configfile config/config_all_studies.yaml --use-conda --cores 8 --keep-going -n
conda deactivate
```
- **PS**: remove the args `-n` to do a real run

### 6. Run the workflow for in depth study in Phylum Nitrospirota and Myxococcota
This will generate antiSMASH results and other downstream processes.
```bash
conda activate snakemake
snakemake --configfile config/config_in_depth.yaml --use-conda --cores 8 --keep-going -n
conda deactivate
```
- **PS**: remove the args `-n` to do a real run
