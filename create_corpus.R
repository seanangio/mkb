# date: 4 June 2018

library(tidyverse)
library(rvest)
library(stringr)
library(zoo) # for yearmon function

# scrape vector of dates for each speech
url <- "https://www.narendramodi.in/mann-ki-baat"
dates <- read_html(url) %>%
    html_nodes(".readTitle") %>%
    html_text %>%
    str_trim %>%
    word(start = -2, end = -1)

# scrape vector of speeches
speeches <- read_html(url) %>%
    html_nodes(".detailMankibatNew") %>%
    html_text %>%
    str_trim

# replace hindi speeches with NA
hindi <- c(29, 37:40)
speeches[hindi] <- NA

# create corpus and add source
corpus <- tibble(
        date = dates, text = speeches) %>%
    mutate(
        source = case_when(
            is.na(text) ~ "http://pib.nic.in/newsite/archiveReleases.aspx",
            TRUE ~ "https://www.narendramodi.in/mann-ki-baat"
        )
    )

# define tibble for manually found speeches
missing_speeches <- tibble(
    date = list.files("hindi_translations") %>% str_replace("^([^.]*).*", "\\1"),
    text = list.files("hindi_translations", full.names = TRUE) %>%
        map_chr(read_file),
    source = "http://pib.nic.in/newsite/archiveReleases.aspx"
)

# add in missing speeches to corpus
corpus <- corpus %>%
    filter(!is.na(text)) %>%
    bind_rows(missing_speeches)

# adding space after key punctuation where not present
corpus <- corpus %>%
    mutate(text = text %>%
               map_chr(str_replace_all, "\\.([[:alpha:]])", ". \\1") %>%
               map_chr(str_replace_all, "!([[:alpha:]])", "! \\1") %>% 
               map_chr(str_replace_all, ",([[:alpha:]])", ", \\1") %>% 
               map_chr(str_replace_all, ":([[:alpha:]])", ": \\1")
    )

# convert dates to date format and arrange by date
corpus <- corpus %>%
    mutate(date_obj = as.yearmon(date) %>% as.Date,
           date_abb = format(date_obj, "%b '%y")) %>%
    arrange(date_obj)

# output corpus to shiny app folder
saveRDS(corpus, "mkb_shiny/corpus.rds")
rm(list = ls())
