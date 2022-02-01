suppressPackageStartupMessages({
library("argparser")
library("tidyverse")
library("readxl")
})

# Parse command line arguments
p <- arg_parser(hide.opts = TRUE, 
                paste0("Takes the table produced by bgcs_table.R ",
                       "and a GTDB-Tk classify output directory ", 
                       "a supplementary file from Singleton et al, 2021, ", 
                       "and the Assembly detail from the Bioproject ",
                       "to produce a csv table where each observation is a MAG"))

p <- add_argument(p, "--bgcs_table",
                  short = "-b",
                  help = "csv table with bgcs produced by bgcs_table.R", 
                  default = "../tables/bgcs.csv")
p <- add_argument(p, "--gtdbtk_dir",
                  short = "-g",
                  help = "Directory with GTDB-Tk summary.tsv files", 
                  default = "../data/")
p <- add_argument(p, "--supplementary_file", 
                  short = "-s", 
                  help = "Filepath with supplementary info from Singleton et al 2021", 
                  default = "../data/41467_2021_22203_MOESM5_ESM.xlsx")
p <- add_argument(p, "--assembly_details", 
                  short = "-a", 
                  help = "Assembly details file from the bioproject", 
                  default = "../data/PRJNA629478_AssemblyDetails.txt")
p <- add_argument(p, "--output", 
                  short = "-o", 
                  help = "Filepath for output csv table", 
                  default = "../tables/mags.csv")

argv <- parse_args(p)


# Import supplementary data, and select variables

supp <- read_xlsx(
  argv$supplementary_file, 
  skip = 1, 
  col_names = TRUE)  %>%
  mutate(
    isolate = str_replace(MAG, ".fa", ""),
    n_contigs = NumContigs, 
    total_bp = TotBP, 
    longest_contig_bp = MaxContigBP, 
    mean_contig_bp = AvContigBP, 
    completeness = Comp, 
    contamination = Cont, 
    circular = is.na(Circ) == FALSE,
    strain_heter0geneity = StrHet,
    drep_95_cluster = HQdRep, 
    drep_95_representative = is.na(HQSpRep) == FALSE, 
    drep_99_cluster = HQdRep99ANI, 
    .keep = "none")

# Import gtdb summaries

gtdbtk_files <- list.files(argv$gtdbtk_dir, 
           pattern = ".summary.tsv", 
           recursive = TRUE, 
           full.names = TRUE)

gtdb_tax <- distinct(
  bind_rows(
    lapply(
      gtdbtk_files, 
      read_tsv,  
      col_select = 1:2, 
      col_types = "cc")))

colnames(gtdb_tax) <- c("genome_id", "gtdb202_tax")

# Import bgc count

bgc_count <- read_csv(argv$bgcs_table, 
                      col_types = "cccccddcl") %>%
  group_by(genome_id) %>%
  summarise(n_bgcs = n())

details <- read_tsv(argv$assembly_details, 
                    skip = 1, 
                    col_select = c(1,6), 
                    col_types = "cc")

colnames(details) <- c("genome_id", "isolate")

# Merge dataframes

mags <- details %>%
  left_join(gtdb_tax, by = "genome_id") %>%
  left_join(bgcs, by = "genome_id") %>%
  left_join(supp, by = "isolate")
  
# Write file

write_csv(mags, file = argv$output)

