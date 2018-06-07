library(markdown)
library(shiny)
library(shinyWidgets)
library(dplyr)
library(DT)
library(ggiraph)
library(shinythemes)

tags$head( tags$style(type = "text/css", "text {font-family: sans-serif}"))

navbarPage("Mann Ki Baat Radio Addresses", theme = shinytheme("cerulean"),
           tabPanel("About",
                    includeMarkdown("about.md"),
                    br()
            ),
           tabPanel("Address Length",
                    sidebarLayout(
                        sidebarPanel(
                            sliderInput("al_dates", "Select Date Range",
                                        min = min(corpus$date_obj),
                                        max = max(corpus$date_obj),
                                        value = range(corpus$date_obj),
                                        timeFormat = "%b '%y"
                            ),
                            radioButtons("al_stopwords", 
                                         "Stopwords (the, a, to, etc)",
                                         choices = c("Remove stopwords", "Keep stopwords"),
                                         selected = "Keep stopwords"
                            ),
                            actionButton("al_update", "Update Corpus"),
                            hr(),
                            checkboxInput("al_fit", "Add smooth model fit", 
                                          value = FALSE)
                        ),
                        mainPanel(
                            ggiraphOutput("address_length"),
                            DT::dataTableOutput("al_table")
                        )
                    )
           ),
           tabPanel("Word Frequencies",
                    sidebarLayout(
                        sidebarPanel(
                            sliderInput("wf_dates", "Select Date Range",
                                        min = min(corpus$date_obj),
                                        max = max(corpus$date_obj),
                                        value = range(corpus$date_obj),
                                        timeFormat = "%b '%y"
                            ),
                            radioButtons("wf_stopwords", "Stopwords (the, a, to, etc)",
                                         choices = c("Remove stopwords", "Keep stopwords"),
                                         selected = "Remove stopwords"
                            ),
                            actionButton("wf_update", "Update Corpus"),
                            hr(),
                            sliderInput("wf_min_freq", "Minimum Frequency:",
                                        min = 1, max = 50, value = 15
                            ),
                            sliderInput("wf_max_words", "Maximum Number of Words:",
                                        min = 1, max = 200, value = 100
                            ),
                            hr(),
                            numericInput("wf_top_n", "Number of Words in Barplot", 
                                         value = 10, min = 1, max = 30, step = 1)
                        ),
                        mainPanel(
                            plotOutput("wf_wordcloud"),
                            ggiraphOutput("wf_top_words")
                        )
                    )
           ),
           tabPanel("Sentiment Analysis",
                    sidebarLayout(
                        sidebarPanel(
                            sliderInput("sa_dates", "Select Date Range",
                                        min = min(corpus$date_obj),
                                        max = max(corpus$date_obj),
                                        value = range(corpus$date_obj),
                                        timeFormat = "%b '%y"
                            ),
                            actionButton("sa_update", "Update Corpus"),
                            hr(),
                            radioButtons("sa_dict", "Select Dictionary",
                                         choices = c("Bing", "NRC", "AFINN"),
                                         selected = "Bing"),
                            numericInput("sa_top_n", "Number of Words in Barplot", 
                                         value = 10, min = 1, max = 30, step = 1)
                        ),
                        mainPanel(
                            ggiraphOutput("sentiment"),
                            br(),
                            plotOutput("sentiment_bars")
                        )
                    )
            ),
           tabPanel("TF-IDF",
               sidebarLayout(
                   sidebarPanel(
                       checkboxGroupInput("tf_dates", "Select Date(s) to View",
                                          choices = corpus$date_abb,
                                          selected = tail(corpus$date_abb, 4), 
                                          inline = TRUE),
                       numericInput("tf_top_n", "Number of Words in Barplot", 
                                    value = 10, min = 1, max = 30, step = 1)
                   ),
                   mainPanel(
                       plotOutput("tfidf", height = 800)
                   )
               )
           ),
           tabPanel("TF-IDF Cloud",
                sidebarLayout(
                    sidebarPanel(
                        helpText("TF-IDF Cutoff refers to the number of top-ranking words per the tf-idf statistic to be included in the word cloud. For example, setting the cutoff at 15 means the full corpus will be filtered to include only words appearing in the top 15 tf-idf rankings in at least one address."),
                        sliderInput("tfc_cut", "TF-IDF Cutoff:",
                                    min = 1, max = 30, value = 15),
                        actionButton("tfc_update", "Update Corpus"),
                        hr(),
                        sliderInput("tfc_min_freq", "Minimum Frequency:",
                                    min = 1, max = 50, value = 15),
                        sliderInput("tfc_max_words", "Maximum Number of Words:",
                                    min = 1, max = 200, value = 100),
                        hr(),
                        numericInput("tfc_top_n", "Number of Words in Barplot", 
                                     value = 10, min = 1, max = 30, step = 1)
                    ),
                    mainPanel(
                        plotOutput("tfidf_cloud"),
                        ggiraphOutput("tfc_top_words")
                    )
                )
            ),
           tabPanel("Bigrams",
                    sidebarLayout(
                        sidebarPanel(
                            helpText("Note: Stopwords have already been removed."),
                            sliderInput("bi_dates", "Select Date Range",
                                        min = min(corpus$date_obj),
                                        max = max(corpus$date_obj),
                                        value = range(corpus$date_obj),
                                        timeFormat = "%b '%y"
                            ),
                            actionButton("bi_update", "Update Corpus"),
                            hr(),
                            helpText("Note: 'dear countrymen' is too large to plot on the word cloud"),
                            sliderInput("bi_min_freq", "Minimum Frequency:",
                                        min = 1, max = 50, value = 15),
                            sliderInput("bi_max_words", "Maximum Number of Words:",
                                        min = 1, max = 200, value = 100),
                            hr(),
                            numericInput("bi_top_n", "Number of Words in Barplot", 
                                         value = 10, min = 1, max = 30, step = 1)
                        ),
                        mainPanel(
                            plotOutput("bi_cloud"),
                            ggiraphOutput("bi_top_words")
                        )
                    )
           )
)