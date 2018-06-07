library(shiny)
library(ggiraph)
library(tm)
library(wordcloud)

shinyServer(function(input, output) {
   
    # make word frequency dataset reactive
    wf_data <- reactive({
        input$wf_update
        isolate({
            withProgress({
                setProgress(message = "Processing corpus...")
                getCorpus(input$wf_dates, input$wf_stopwords)
            })
        })
    })
    
    # make word clouds repeatable
    wordcloud_rep <- repeatable(wordcloud)
    
    # word cloud logic
    output$wf_wordcloud <- renderPlot({
    
        v <- wf_data() %>%
            group_by(word) %>%
            count()
        wordcloud_rep(words = v$word, freq = v$n, 
                      scale = c(5, 0.5),
                      min.freq = input$wf_min_freq,
                      max.words = input$wf_max_words,
                      random.order = FALSE, rot.per = 0.35, 
                      colors = brewer.pal(8, "Dark2"))
    })
    
    # word frequency bar plot logic
    output$wf_top_words <- renderggiraph({

        top_words <- wf_data() %>%
            group_by(word) %>%
            count(sort = TRUE) %>%
            ungroup() %>%
            top_n(input$wf_top_n) %>%
            ggplot(aes(fct_reorder(word, n), n, fill = n)) +
            geom_bar_interactive(aes(tooltip = as.character(n), data_id = as.character(n)), 
                                 stat = "identity", width = 0.5) + 
            theme(aspect.ratio = 1/1.5) +
            xlab(NULL) +
            coord_flip() +
            ylab("Word Frequency") +
            ggtitle("Most Common Corpus Words") +
            theme(plot.title = element_text(size = 12)) +
            theme(legend.position = "none")
        
        ggiraph(code = print(top_words),
                hover_css = "cursor:pointer;stroke-width:5px;fill-opacity:0.8;",
                tooltip_extra_css = tooltip_css, tooltip_opacity = 0.75,
                selection_type = "none")
    })
    
    # make address length data reactive
    al_data <- reactive({
        input$al_update
        isolate({
            withProgress({
                setProgress(message = "Processing corpus...")
                getCorpus(input$al_dates, input$al_stopwords)
            })
        })
    })
    
    # address length logic
    output$address_length <- renderggiraph({ 

        v <- al_data() %>%
            group_by(date_obj, date_abb, date) %>%
            count(word) %>%
            group_by(date_obj, date_abb, date) %>%
            summarise(total_words = sum(n))
            
        p <- ggplot(v, aes(x = date_obj, y = total_words)) +
            geom_point_interactive(aes(tooltip = date,
                                       data_id = date), size = 2) +
            scale_x_date(NULL, date_breaks = "1 year", date_labels = "%b %Y") +
            scale_y_continuous("Words per Address", labels = scales::comma)

        if (input$al_fit) {
            p <- p + geom_smooth(method = "loess")
        }
        
        ggiraph(code = print(p), 
                hover_css = "cursor:pointer;fill:red;stroke:red;",
                selection_type = "none")

    })
    
    # address length table
    output$al_table <- DT::renderDataTable({
            al_data() %>%
            group_by(date, date_obj) %>%
            count(word) %>%
            group_by(date, date_obj) %>%
            summarise(total_words = sum(n)) %>%
            arrange(date_obj) %>%
            select(-date_obj)
    },
    colnames = c("Address Date", "Word Count"),
    options = list(
        columnDefs = list(list(className = 'dt-body-center', targets = "_all"),
                          list(className = 'dt-head-center', targets = "_all")),
        pageLength = 5,
        lengthMenu = c(5, 10, 15, 20)
        ) 
    )
    
    # make sentiment data reactive
    sa_data <- reactive({
        input$sa_update
        isolate({
            withProgress({
                setProgress(message = "Processing corpus...")
                getSentimentData(input$sa_dates)
            })
        })
    })
    
    # sentiment plot logic
    output$sentiment <- renderggiraph({
        
        if (input$sa_dict == "Bing") {
            sa_p <- sa_data() %>%
                inner_join(get_sentiments("bing"), by = "word") %>%
                count(date_obj, date, sentiment) %>%
                spread(sentiment, n) %>%
                mutate(ratio = positive / negative,
                       tt = str_c(
                           "<b>", date, "</b>",
                           "<br>+: ", positive, "  -: ", negative, "</b>",
                           "</span></div>"
                       )) %>%
                ggplot(aes(x = date_obj, y = ratio)) +
                geom_hline(yintercept = 1, color = "white", size = 2) +
                geom_point_interactive(aes(tooltip = tt, data_id = date_obj), size = 1) +
                scale_x_date(NULL, date_breaks = "1 year", date_labels = "%b %Y") +
                scale_y_continuous("Ratio of Positive to Negative Words")
            
        } else if (input$sa_dict == "NRC") {
            sa_p <- sa_data() %>%
                inner_join(get_sentiments("nrc"), by = "word") %>%
                filter(sentiment %in% c("positive", "negative")) %>%
                count(date_obj, date, sentiment) %>%
                spread(sentiment, n) %>%
                mutate(ratio = positive / negative,
                       tt = str_c(
                           "<b>", date, "</b>",
                           "<br>+: ", positive, "  -: ", negative, "</b>",
                           "</span></div>"
                       )) %>%
                ggplot(aes(x = date_obj, y = ratio)) +
                geom_hline(yintercept = 1, color = "white", size = 2) +
                geom_point_interactive(aes(tooltip = tt, data_id = date_obj), size = 1) +
                scale_x_date(NULL, date_breaks = "1 year", date_labels = "%b %Y") +
                    scale_y_continuous("Ratio of Positive to Negative Words")
            
        } else {
            sa_p <- sa_data() %>%
                inner_join(get_sentiments("afinn"), by = "word") %>% 
                group_by(date_obj, date) %>%
                summarise(sentiment = mean(score)) %>%
                mutate(tt = str_c(
                    "<b>", date, "</b>",
                    "<br>", round(sentiment, 3), "</b>",
                    "</span></div>"
                )) %>%
                ggplot(aes(x = date_obj, y = sentiment)) +
                geom_hline(yintercept = 1, color = "white", size = 2) +
                geom_point_interactive(aes(tooltip = tt, data_id = date_obj), size = 1) +
                scale_x_date(NULL, date_breaks = "1 year", date_labels = "%b %Y") +
                scale_y_continuous("Mean Sentiment Score")
        }
        
        sa_p <- sa_p + 
            ggtitle(str_c("Sentiment Analysis Using ", input$sa_dict, " Dictionary")) +
            theme(plot.title = element_text(size = 11)) +
            theme(axis.title = element_text(size = 10))
        
        ggiraph(code = print(sa_p),
                selection_type = "none",
                hover_css = "cursor:pointer;stroke-width:5px;",
                tooltip_extra_css = tooltip_css, tooltip_opacity = 0.75)
        
    })
    
    # sentiment bars logic
    output$sentiment_bars <- renderPlot({
        
        if (input$sa_dict == "Bing") {
            sa_bp <- sa_data() %>%
                inner_join(get_sentiments("bing"), by = "word") %>%
                count(word, sentiment, sort = TRUE) %>%
                group_by(sentiment) %>%
                top_n(input$sa_top_n) %>%
                ggplot(aes(fct_reorder(word, n), n, fill = sentiment)) +
                geom_col(show.legend = FALSE, width = 0.5) +
                facet_wrap(~sentiment, scales = "free_y") +
                coord_flip() +
                labs(x = NULL, y = "Contribution to Sentiment Score") +
                ggtitle("Top Contributors to Positive and Negative Sentiment")
            
        } else if (input$sa_dict == "NRC") {
            sa_bp <- sa_data() %>%
                inner_join(get_sentiments("nrc"), by = "word") %>%
                filter(sentiment %in% c("positive", "negative")) %>%
                count(word, sentiment, sort = TRUE) %>%
                group_by(sentiment) %>%
                top_n(input$sa_top_n) %>%
                ggplot(aes(fct_reorder(word, n), n, fill = sentiment)) +
                geom_col(show.legend = FALSE, width = 0.5) +
                facet_wrap(~sentiment, scales = "free_y") +
                coord_flip() +
                labs(x = NULL, y = "Contribution to Sentiment Score") +
                ggtitle("Top Contributors to Positive and Negative Sentiment")
            
        } else {
            sa_bp <- sa_data() %>%
                inner_join(get_sentiments("afinn"), by = "word") %>% 
                group_by(word) %>%
                summarize(total = sum(score),
                          posneg = ifelse(total >= 0, "positive", "negative"),
                          abs_total = abs(total)) %>%
                arrange(total) %>%
                group_by(posneg) %>%
                top_n(input$sa_top_n) %>%
                ggplot(aes(fct_reorder(word, abs_total), abs_total, fill = posneg)) +
                geom_col(show.legend = FALSE, width = 0.5) +
                facet_wrap(~posneg, scales = "free_y") +
                coord_flip() +
                labs(x = NULL, y = "Contribution to Sentiment Score") +
                ggtitle("Top Contributors to Positive and Negative Sentiment")
        }
        
        sa_bp +
            theme(plot.title = element_text(size = 14)) +
            theme(axis.text = element_text(size = 12)) +
            theme(axis.title = element_text(size = 12))
    })
    
    # create tf-idf plot
    output$tfidf <- renderPlot({
        
        tfidf_data %>%
            filter(date_abb_f %in% input$tf_dates) %>%
            group_by(date_obj) %>% 
            top_n(input$tf_top_n) %>%
            ggplot(aes(fct_reorder(word, tf_idf), tf_idf, fill = date_abb_f)) +
            geom_col(show.legend = FALSE, width = 0.5) +
            labs(x = NULL, y = "TF-IDF") +
            facet_wrap(~date_abb_f, ncol = 2, scales = "free") +
            coord_flip() +
            ggtitle("Most 'Important' Words per TF-IDF") +
            theme(axis.text = element_text(size = 12)) +
            theme(plot.title = element_text(size = 16)) +
            theme(axis.title.y = element_text(size = 12)) +
            theme(strip.text = element_text(size = 12))
        
    })
    
    # tf-idf cloud logic
    output$tfidf_cloud <- renderPlot({
        
        tfidf_words <- tfidf_data %>%
            group_by(date_obj) %>%
            arrange(date_obj, desc(tf_idf)) %>%
            mutate(rank = min_rank(desc(tf_idf))) %>%
            filter(rank <= input$tfc_cut) %>%
            ungroup() %>%
            select(word) %>% unique() %>% pull()
        
        tfidf_counts <- tidy_text %>%
            filter(word %in% tfidf_words) %>%
            count(word) %>%
            arrange(desc(n))
        
        wordcloud_rep(tfidf_counts$word, tfidf_counts$n,
                  scale = c(5, 0.5),
                  random.order = FALSE, rot.per = 0.35, 
                  min.freq = input$tfc_min_freq, 
                  max.words = input$tfc_max_words,
                  colors = brewer.pal(8, "Dark2"))
    })
    
    # tf-idf bar plot logic
    output$tfc_top_words <- renderggiraph({
        
        tfc_top_words <- tfidf_counts %>%
            top_n(input$tfc_top_n) %>%
            ggplot(aes(fct_reorder(word, n), n, fill = n)) +
            geom_bar_interactive(aes(tooltip = as.character(n), data_id = as.character(n)), 
                                 stat = "identity", width = 0.5) + 
            theme(aspect.ratio = 1/1.5) +
            xlab(NULL) +
            coord_flip() +
            ylab("Word Frequency") +
            ggtitle("Most Common Corpus Words Post TF-IDF Filter") +
            theme(plot.title = element_text(size = 12)) +
            theme(legend.position = "none")
        
        ggiraph(code = print(tfc_top_words),
                hover_css = "cursor:pointer;stroke-width:5px;fill-opacity:0.8;",
                tooltip_extra_css = tooltip_css, tooltip_opacity = 0.75,
                selection_type = "none")
    })
    
    # make bigram dataset reactive
    bigram_data <- reactive({
        input$bi_update
        isolate({
            withProgress({
                setProgress(message = "Processing corpus...")
                getBigrams(input$bi_dates)
            })
        })
    })
    
    # bigram word cloud logic
    output$bi_cloud <- renderPlot({
        
        bigram_counts <- bigram_data()

        wordcloud_rep(bigram_counts$bigram, bigram_counts$n,
                  scale = c(5, 0.5),
                  random.order = FALSE, rot.per = 0.15,
                  min.freq = input$bi_min_freq,
                  max.words = input$bi_max_words,
                  colors = brewer.pal(8, "Dark2"))
    })
    
    # bigram word plot logic
    output$bi_top_words <- renderggiraph({
        
        bigram_counts <- bigram_data()
        
        bi_top_words <- bigram_counts %>%
            top_n(input$bi_top_n) %>%
            ggplot(aes(fct_reorder(bigram, n), n, fill = n)) +
            geom_bar_interactive(aes(tooltip = as.character(n), data_id = as.character(n)),
                                 stat = "identity", width = 0.5) +
            theme(aspect.ratio = 1/1.5) +
            xlab(NULL) +
            coord_flip() +
            ylab("Bigram Frequency") +
            ggtitle("Most Common Bigrams") +
            theme(plot.title = element_text(size = 12)) +
            theme(legend.position = "none")
        
        ggiraph(code = print(bi_top_words),
                hover_css = "cursor:pointer;stroke-width:5px;fill-opacity:0.8;",
                tooltip_extra_css = tooltip_css, tooltip_opacity = 0.75,
                selection_type = "none")
    })
})
