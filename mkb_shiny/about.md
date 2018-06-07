### Mann Ki Baat

"Mann Ki Baat", meaning ("Mind's Voice"), is a monthly radio address by India's Prime Minister Narendra Modi. From its launch in October 2014, Modi has delivered 44 addresses (as of 4 June 2018), typically at the end of each month. Given he assumed the office of Prime Minister in only May 2014, these radio addresses serve as a key chronology of his time as Prime Minister.

The depth of the corpus (44 speeches), the high-profile nature of the programme (1.43 lakh audio recordings per month according to Wikipedia), and the regularity of the interval (monthly) make the Mann Ki Baat addresses an excellent corpus for text analysis.

![](mkb_img.png)
[Source: https://www.narendramodi.in/mann-ki-baat]

### Creating the Corpus

The English translations of the Hindi addresses are available at https://www.narendramodi.in/mann-ki-baat, and in a few cases http://pib.nic.in/newsite/archiveReleases.aspx. I used the "rvest" package to collect them. Only a very minimal amount of cleaning was required. In rare cases, untranslatable Hindi expressions remain in the English translation. They were ignored.

### Text Analysis Guide

Key to much of this analysis has been the "tidytext" package, which itself builds on the tidyverse. The freely available [Tidy Text Mining](https://www.tidytextmining.com/) book was also very valuable for explaining core text analysis concepts.

##### Address Length

The first tab simply looks at the length of the radio addresses in terms of total number of words. From a fairly short speech in its infancy, the address has grown over time, reaching a peak around Jan 2017 and since then becoming somewhat shorter.

##### Word Frequencies

The second tab shows the most common words in both word cloud and barplot formats. Not surprisingly, the most common words, whether looking at the entire corpus or narrowing the search to a single address, tend to be quite generic words, suitable to any Prime Minister addressing the people of his or her state.

##### Sentiment Analysis

The third tab is sentiment analysis. Sentiment analysis, in this context, involves using pre-defined dictionaries of words which have been labelled in some way by sentiment. The Bing dictionary, for instance, has assigned nearly 7,000 words labels of "positive" or "negative". Words in our own corpus then are matched to this dictionary, and positive and negative corpus words can be counted. Similarly, the NRC dictionary labels words according to ten different sentiments, like "anger" and "joy", along with "positive" and "negative". Lastly, the AFINN dictionary assigns words a numeric score ranging from 5 to -5. In all cases, words not found in the chosen dictionary are dropped from the corpus.

In some cases, words in these dictionaries are labelled inappropriately for the context in which it is being used. For example, both the NRC and AFINN dictionaries label the word "dear" as a positive word. In many contexts, a positive label makes sense. However, in the case of these radio addresses, "dear" is used simply as a salutation and is arguably not something that deserves a positive sentiment. In these cases, we can simply include such words in the list of stopwords to be removed from the corpus. Here, I removed "government", "scheme", "mother", and "dear", all of which have a context different in this corpus than in the pre-defined dictionaries.

##### TF-IDF

Perhaps of greatest interest is "TF-IDF", a statistic which stands for term frequency inverse document frequency. The Tidy Text Mining book carries an excellent description of this statistic and what it represents. According to the authors, "The statistic tf-idf is intended to measure how important a word is to a document in a collection (or corpus) of documents, for example, to one novel in a collection of novels or to one website in a collection of websites." Or, in this case, the importance of a word in one radio address in a collection of radio addresses.

Rather than word frequency alone, the tf-idf statistic does a much better job of communicating the most important themes of an address. For instance, for January 2015, soon after the US President visited, we get words like "barack" and "obama". For March 2015, the same month a land acquisition reform bill was introduced in Parliament, we get words like "law", "compensation", and "farmers". For November 2016, soon after demonetisation, we get words like "cashless", "notes", and "rupee". in Feb we get words like "class", "exams"

Note that the tf-idf statistic is calculated for the corpus as a whole, and so when selecting dates to view, the tf-idf rankings for each address refer to their scoring amongst the corpus as a whole, not just those selected addresses.

##### TF-IDF Cloud

The previous tab is useful for identifying the key thematic words of each address. This tab allows a user to filter the corpus by these key words as identified by the tf-idf statistic. Users can then visualize frequency counts of that filtered corpus in a word cloud and a bar plot. It is a way of accumulating the insights of the previous individual facets.

Perhaps more striking than the words present are the words that are absent from the top of the list. Common political words like "election", "vote", "BJP", or "Congress" are not among the most used words. Instead, we find words like "water", "women", "yoga", "exams" and "khadi". Judging from these results, the addresses certainly are not devoid of political content, but they also have a different purpose than a campaign rally.

##### Bigrams

All of the previous analysis has focused on individual words, or unigrams. We can also tokenize the corpus into bigrams, groupings of two words. Examining two words at a time can help provide additional context to the meaning of each word, if the corpus is large enough in size for the counts still to have meaning.

Aside from the name of the address itself, the bigram approach uncovers a few new dimensions, such as references to former leaders like Gandhi or Ambedkar, or timely events like the World Cup or Yoga Day.

### Further Information

The code for this project can be found on [Github](https://github.com/seanangio/mkb). Other data projects by the author can be found at http://sean.rbind.io/.
