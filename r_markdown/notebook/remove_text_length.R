#'  Removes the textLength attribute from a svg produced by ggsave
#'  
#'  The function ggsave adds the parameter textLength when it generates svg files,
#'  which makes text difficult to resize if you want to edit it in ej. Inkscape. 
#'  This function removes this parameter.  
#'  
#' @param file Input svg file
#'
#' @return file Output svg file

remove_text_length <- function(file){
  html <- readLines(file)
  html <- str_replace_all(html, "textLength=\\'.+?\\'", '')
  html <- str_replace_all(html, 'textLength=\\".+?\\"', '')
  write_lines(html, file = file)
}

