library(tidyverse)
library(tidytext)
library(memoise)

# read in data
corpus <- readRDS("corpus.rds")
tidy_text <- corpus %>%
    unnest_tokens(word, text)

# function to prepare corpus for word frequencies
getCorpus <- memoise(function(dates, stopwords) {
    
    data <- tidy_text %>%
        filter(between(date_obj, dates[1], dates[2]))
    
    if (stopwords == "Remove stopwords") {
        data <- data %>%
            anti_join(stop_words, by = "word")
    } 
    
    data
})

# for sa, remove words that in other contexts may be negative but here are neutral
custom_stop_words <- bind_rows(data_frame(word = c("government", "mother", 
                                                   "dear", "scheme"), 
                                          lexicon = c("custom")), 
                               stop_words)

# function to prepare sentiment data
getSentimentData <- memoise(function(dates) {
    
    data <- tidy_text %>%
        filter(between(date_obj, dates[1], dates[2])) %>%
        anti_join(custom_stop_words)
    data
})

# save custom tooltip css for ggiraph objects
tooltip_css <- "background-color:gray;color:white;padding:5px;border-radius:5px;font-family:sans-serif;font-size:12px;"

# prepare tf-idf data (not reactive!)
tfidf_data <- tidy_text %>%
    mutate(date_abb_f = factor(date_abb, levels = corpus$date_abb)) %>%
    group_by(date_obj) %>%
    count(date_obj, date_abb_f, word) %>%
    group_by(date_obj) %>%
    mutate(speech_sum = sum(n)) %>%
    arrange(desc(n)) %>%
    bind_tf_idf(word, date_obj, n)

# unnest bigram data
bigrams <- corpus %>%
     unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%
     separate(bigram, c("word1", "word2"), sep = " ") %>%
     filter(!word1 %in% stop_words$word) %>%
     filter(!word2 %in% stop_words$word) %>%
     unite(bigram, word1, word2, sep = " ")

# function to prepare bigram data
getBigrams <- memoise(function(dates) {
    
    bigrams %>%
        filter(between(date_obj, dates[1], dates[2])) %>%
        count(bigram, sort = TRUE)
    
})
