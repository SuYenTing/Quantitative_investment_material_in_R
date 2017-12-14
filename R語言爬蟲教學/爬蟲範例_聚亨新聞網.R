# 爬取聚亨新聞網台股新聞頁面
# 程式撰寫: 蘇彥庭
rm(list=ls());gc()
library(rvest)

# 網址
url <- paste0("https://news.cnyes.com/news/cat/tw_stock_news")

# 下載新聞標題(使用語法爬取)
title <- read_html(url, encoding = "utf-8") %>%
  html_nodes(css="._1xc h3") %>%
  html_text()

# 取出新聞連結
newsLink <- read_html(url, encoding = "utf-8") %>%
  html_nodes(xpath="//main/div[4]/div[2]/div/a") %>%
  html_attr("href")

# 迴圈連結取出新聞內容
newsContent <- NULL
for(ix in 1:length(newsLink)){
  
  cat(paste0("目前進度:",ix,"/",length(newsLink),"\n"))
  
  # 網址
  url <- paste0("https://news.cnyes.com",newsLink[ix])
  
  # 下載股價資料(使用語法爬取)
  data <- read_html(url, encoding = "utf-8") %>%
    html_nodes(css="._82F div") %>%
    html_text() %>%
    .[1]
  
  # 儲存資料
  newsContent <- c(newsContent, data)  
  
  # 暫停程式碼
  Sys.sleep(1)
}

# 整理成tibble
output <- tibble(title, newsLink, newsContent)



