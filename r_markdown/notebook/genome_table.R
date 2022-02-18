suppressPackageStartupMessages({
  library(argparser)
  library(tidyverse)
  library(readxl)
})


p <- arg_parser(hide.opts = TRUE, 
                paste0("Creates a csv table with GTDB taxonomy and quality info, ", 
                       "and antismash BGC count and BGC contig_edge info, ", 
                       "for each genome (both internal MAGs and refernce) ", 
                       "to be used in the case studies"))

p <- add_argument(p, "--bgcs_table",
                  short = "-b",
                  help = "csv table with bgcs produced by bgcs_table.R", 
                  default = "~/AS_hqMAGs/r_markdown/tables/wwtphqmags_bgcs.csv")

p <- add_argument(p, "--gtdbtk_summary",
                  short = "-g",
                  help = "GTDB-Tk summary.tsv file for the MAGs", 
                  default = "~/AS_hqMAGs/r_markdown/data/gtdbtk.bac120.summary.tsv")

p <- add_argument(p, "--supplementary_file", 
                  short = "-s", 
                  help = "Filepath with supplementary table 3 from Singleton et al 2021", 
                  default = "~/AS_hqMAGs/r_markdown/data/singleton_2021_table3.xlsx")

p <- add_argument(p, "--assembly_details", 
                  short = "-a", 
                  help = "Assembly details file from the bioproject", 
                  default = "~/AS_hqMAGs/r_markdown/data/assembly_details.txt")

p <- add_argument(p, "--output", 
                  short = "-o", 
                  help = "Filepath for output csv table", 
                  default = "~/AS_hqMAGs/r_markdown/tables/wwtphqmags_genomes.csv")

p <- add_argument(p, "--gtdb_metadata", 
                  short = "-m", 
                  help = "GTDB metadata table", 
                  default = "~/AS_hqMAGs/r_markdown/data/bac120_metadata_r202.tsv")

argv <- parse_args(p)

bgcs <- read_csv(argv$bgcs_table , 
                 col_select = c(3,8), 
                 col_types = "cl") %>%
  group_by(genome_id) %>%
  summarise(total_bgcs = n(), 
            bgcs_on_contig_edge = sum(contig_edge))

assembly_details <- read_tsv(
  argv$assembly_details, 
  skip = 1,
  col_select = c(1,6), 
  col_types = "cc") %>%
setNames(c("genome_id", "isolate"))

gtdbtk_summary <- read_tsv(
  argv$gtdbtk_summary, 
  col_select = 1:2, 
  col_types = "cc") %>%
  setNames((c("genome_id", "gtdb_taxonomy")))
  
mags <- read_xlsx(
  argv$supplementary_file, 
  skip = 1) %>%
  mutate(isolate = str_replace(MAG, '.fa', ""), 
         assembly_level = if_else(Circ == "CIRCULAR",
                                  "Complete/Chromosome",
                                  "Contig/Scaffold"),
         checkm_completeness = Comp, 
         checkm_contamination = Cont, 
         genome_size = TotBP, 
         ncbi_bioproject = "PRJNA629478",
         mimag_quality = "HQ",
         source = "genbank",
         .keep = "none") %>%
  left_join(assembly_details, by = "isolate") %>%
  left_join(gtdbtk_summary, by = "genome_id") %>%
  select(-isolate)
  
metadata <- read_tsv(
  argv$gtdb_metadata, 
  col_select = c(1,  4, 14, 17, 41:43, 46, 49), 
  show_col_types = FALSE) %>%
  mutate(genome_id = str_sub(accession, start = 4), 
         source = if_else(str_detect(accession, "^RS_"), "refseq", "genbank"), 
         mimag_quality = case_when(
           mimag_high_quality ~ "HQ", 
           mimag_medium_quality ~ "MQ", 
           mimag_low_quality ~ "LQ"), 
         assembly_level = case_when(
           ncbi_assembly_level == "Contig" ~ "Contig/Scaffold", 
           ncbi_assembly_level == "Scaffold" ~ "Contig/Scaffold", 
           ncbi_assembly_level == "Complete Genome" ~ "Complete/Chromosome",
           ncbi_assembly_level == "Chromosome" ~ "Complete/Chromosome"),
         .keep = "unused") %>%
  filter(genome_id %in% bgcs$genome_id) 
  
genomes <- bind_rows(mags, metadata) %>%
  left_join(bgcs, by = "genome_id") %>%
  filter(is.na(gtdb_taxonomy) == FALSE) %>%
  relocate(genome_id, 
           total_bgcs,
           bgcs_on_contig_edge,
           gtdb_taxonomy) %>%
  mutate(total_bgcs = replace_na(total_bgcs, 0))

write_csv(genomes, 
          argv$output)
  




  





