# 爬蟲rvest套件範例-PPT股市版
# 程式撰寫: 蘇彥庭
rm(list=ls());gc()
library(rvest)
library(dplyr)

# 首先連結股市版首頁
url <- "https://www.ptt.cc/bbs/Stock/index.html"

# 利用上一頁面的連結推斷目前在第幾頁
pageNum <- read_html(url, encoding = "utf-8") %>%
  html_nodes(xpath="//a[@class='btn wide'][2]") %>%   # 指定到上一頁 
  html_attr("href") %>%                               # 取得href屬性的值
  gsub("\\D","",.) %>% 
  as.numeric()
  
# 讀取頁數
pageRead <- 10  

# 建立文章連結表
linkTable <- NULL

# 迴圈翻取各頁各文章的連結
for(page in seq((pageNum-pageRead+1), pageNum, 1)){
  
  cat(paste0("目前正在讀取第 ",page," 個頁面，進度: ",page," / ",pageNum,"\n"))
  
  # 連結
  url <- paste0("https://www.ptt.cc/bbs/Stock/index",page,".html")
  
  # 下載網頁原始碼
  html <- read_html(url, encoding = "utf-8")
  
  # 讀取標題
  title <-  html %>% 
    html_nodes(xpath="//div[@class='title']/a") %>% 
    html_text()
  
  # 讀取文章連結
  link <- html %>% 
    html_nodes(xpath="//div[@class='title']/a") %>% 
    html_attr("href") %>% 
    paste0("https://www.ptt.cc",.)
    
  # 儲存資料  
  linkTable <- bind_rows(linkTable, tibble(title,link))
  
  # 暫停延緩
  Sys.sleep(0.5)
}

# 建立文章儲存表
article <- NULL

# 迴圈讀取文章內容
for(ix in 1:nrow(linkTable)){

  cat(paste0("目前正在讀取第 ",ix," 個文章內容，進度: ",ix," / ",nrow(linkTable),"\n"))
  
  # 連結
  url <- linkTable$link[ix]
  
  # 下載文章原始碼
  html <- read_html(url, encoding = "utf-8")
  
  # 讀取文章內容
  content <- html %>% 
    html_nodes(xpath="//div[@id='main-content']") %>%
    html_text()
  
  # 儲存文章內容
  article <- append(article, list(content))
  
  # 暫停延緩
  Sys.sleep(0.5)
}






