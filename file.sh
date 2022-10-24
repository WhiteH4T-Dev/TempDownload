awk -v FS='#' '/# en_US.UTF8 UTF-8/{OFS="";$1=""}1' file
