
# detect all taxa for a given level in a GTDB taxonomy vector
detect_taxa <- function(tax, level){
  level_letter <- str_sub(level, end = 1)
  level_pattern <- paste0("(",level_letter, "__.+?)(;|$)")
   table(str_match(tax, level_pattern)[,2]) %>%
     data.frame() %>%
     set_names(c('taxon', 'count')) %>%
     mutate(taxon = as.character(taxon))
}

select_appropiate_taxa <- function(
    gtdb_tax_vector, 
    min,
    max,
    taxonomic_levels = c(
      "domain", "phylum", "class","order","family","genus", "species")){
  
  result <- data.frame(taxon = character(), count = integer())
  
  for (level in taxonomic_levels){
    # saves in "result" the taxa below a frequency cutoff
    df <- detect_taxa(gtdb_tax_vector, level) 
    big_clades <- df[df$count > max,]$taxon
    big_clades_pattern <- paste(big_clades, collapse = "|")
    df <- df[df$count < max,]
    result <- bind_rows(result, df)
    # subsets GTDB taxonomy vector to non-saved elements in each iteration
    gtdb_tax_vector <- gtdb_tax_vector[str_detect(gtdb_tax_vector, big_clades_pattern)]
  }
  filter(result, count > min) %>%
    filter(str_detect(taxon, "__;", negate = TRUE)) %>%
    pull(taxon)
}


