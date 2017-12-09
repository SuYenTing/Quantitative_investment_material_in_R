# 爬蟲rvest套件範例-PPT股市版
# 程式撰寫: 蘇彥庭
rm(list=ls());gc()
library(rvest)
library(dplyr)

# 首先連結股市版首頁
url <- "https://www.ptt.cc/bbs/movie/index.html"

# 利用上一頁面的連結推斷目前在第幾頁
pageNum <- read_html(url, encoding = "utf-8") %>%
  html_nodes(xpath="//a[@class='btn wide'][2]") %>%   # 指定到上一頁 
  html_attr("href") %>%                               # 取得href屬性的值
  gsub("\\D","",.) %>% 
  as.numeric()

# 讀取頁數
pageRead <- 100  

# 建立文章連結表
articleTable <- NULL

# 迴圈翻取各頁各文章的連結
for(page in seq((pageNum-pageRead+1), pageNum, 1)){
  
  cat(paste0("目前正在讀取第 ",page," 個頁面，進度: ",page," / ",pageNum,"\n"))
  
  # 連結
  url <- paste0("https://www.ptt.cc/bbs/movie/index",page,".html")
  
  # 下載網頁原始碼
  html <- read_html(url, encoding = "utf-8")
  
  # 讀取標題
  title <-  html %>% 
    html_nodes(xpath="//div[@class='title']") %>% 
    html_text() %>%
    gsub("\n", "", .) %>%
    gsub("\t", "", .)
  
  # 讀取文章連結
  link <- html %>% 
    html_nodes(xpath="//div[@class='title']/a") %>% 
    html_attr("href") %>% 
    paste0("https://www.ptt.cc",.)
  
  # 讀取文章日期
  articleDate <- html %>% 
    html_nodes(xpath="//div[@class='date']") %>% 
    html_text()
  
  # 移除文章已被刪除項目
  removeSite <- grep("刪除",title)
  if(length(removeSite)>0){
    articleDate <- articleDate[-removeSite]
    title <- title[-removeSite]
  }
  
  # 儲存資料  
  articleTable <- bind_rows(articleTable, tibble(articleDate, title, link))
  
  # 暫停延緩
  Sys.sleep(0.5)
}

# 儲存檔案
save(articleTable, file="./movieData/pttMovieArticle.Rdata")

