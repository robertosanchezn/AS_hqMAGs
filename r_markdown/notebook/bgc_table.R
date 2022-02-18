suppressPackageStartupMessages({
  library("tidyverse")
  library("argparser") 
  library("parallel") 
  library("jsonlite") 
  library("pbapply")
  })

# Parse command line arguments
p <- arg_parser(hide.opts = TRUE, 
  paste0("Takes an antiSMASH and BiG-SCAPE output directories, ",
         "and searches recursively in them ", 
         "to produce a csv table where each observation is a BGCc. ",  
         "Columns include the location of the bgc, its product, ", 
         "a logical indicating if it sits on a contig edge," ,
         "its class and the GCF it belongs to, based on BiG-SCAPE) "))

p <- add_argument(p, "--antismash_dir",
                  short = "-a",
                  help = "Directory containing antiSMASH-generated json files", 
                  default = "~/wwtphqmags/antismash/6.0.1/")
p <- add_argument(p, "--bigscape_dir",
                  short = "-b",
                  default = "~/wwtphqmags/bigscape/wwtphqmags_antismash_6.0.1/network_files/2022-02-10_10-03-49_glocal_wwtphqmags_antismash_6.0.1/",
                  help = paste0(
                    "Directory with BiG-SCAPE output, containing Network Annotations ", 
                    "and clustering files"))
p <- add_argument(p, "--output", 
                  short = "-o", 
                  default = "~/AS_hqMAGs/r_markdown/tables/wwtphqmags_bgcs.csv", 
                  help = "Output csv file")
p <- add_argument(p, "--threads",
                  short = "-t",
                  help = "Number of threads to use in parallel", 
                  default = detectCores())

argv <- parse_args(p)


#Extracts info from antismash .json files

get_region_rows <-   function(genome_id){
    genome_id_json <- fromJSON(genome_id)
    records_df <- genome_id_json$records
    contig_names <- records_df$id
    features <- records_df$features
    names(features) <- contig_names
    features_df <- bind_rows(features, .id = 'contig')
    regions_df <- features_df[features_df$type == 'region',]
    ends <- str_sub(regions_df$location, start = 2, end = -2) %>%
      str_split(":", n =2, simplify = T)
    start <- as.numeric(ends[,1])
    end <- as.numeric(ends[,2])
    length <- as.numeric(ends[,2]) - as.numeric(ends[,1])
    product <- sapply(regions_df$qualifiers$product, paste0, collapse = ";") %>%
      as.character()
    contig_edge <- as.logical(unlist(regions_df$qualifiers$contig_edge))
    contig <- as.character(regions_df$contig)
    regions <- suppressMessages(bind_cols(
    contig, start, end, product, contig_edge))
    colnames(regions) <- c(
     "contig", "start", "end", "product", "contig_edge")
    regions
    }

genome_ids <- list.files(
  argv$antismash_dir,
  recursive = T,
  pattern = '*.json',
  full.names = TRUE)

# Parallelizes json parsing, shows a progress bar on the terminal

cluster <- makeForkCluster(nnodes = argv$threads)
pbo  <- pboptions(type="timer")
regions_list <- pbsapply(genome_ids, 
                         get_region_rows, 
                         simplify = FALSE,
                         cl  = cluster)

regions <- bind_rows(regions_list, .id = 'genome_id') %>%
  group_by(contig) %>%
  mutate(
    genome_id =str_split(genome_id, "/"),
    genome_id = sapply(genome_id, function(l) l[length(l)]),
    genome_id = str_replace(genome_id, '.json', ""),
    bgc_id = paste0(contig, '.region',str_pad(1:n(), width = 3, pad = '0')))

# Imports BiG-SCAPE's network annotations
  
annotation_files <- list.files(path = argv$bigscape_dir,
                               pattern = "Network_Annotations",
                               recursive = TRUE, 
                               full.names = TRUE)

bigscape_annotations <- distinct(
  bind_rows(
  lapply(annotation_files, 
         read_tsv,
         col_select = c(1,5),
         col_names =  TRUE,
         col_types = "cc"))) 

colnames(bigscape_annotations) <- c("bgc_id", "class")

# Imports BiG-SCAPE's clustering 

clustering_files <- list.files(path = argv$bigscape_dir,
                               pattern = "clustering",
                               recursive = TRUE, 
                               full.names = TRUE)

bigscape_clustering <- distinct(
  bind_rows(
  lapply(clustering_files, 
         read_tsv, 
         col_types = 'cc')))

colnames(bigscape_clustering) <- c("bgc_id", "GCF")

bgcs_dataframe <- bigscape_clustering %>% 
  group_by(bgc_id) %>% 
  summarise(GCF = paste0(unique(GCF), collapse =';')) %>%
  right_join(regions, by = "bgc_id") %>%
  left_join(bigscape_annotations, by = "bgc_id")

write_csv(bgcs_dataframe, 
          file = argv$output, 
          num_threads = argv$threads)




