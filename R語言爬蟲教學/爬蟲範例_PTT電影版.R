# 爬蟲rvest套件範例-PPT股市版
# 程式撰寫: 蘇彥庭
rm(list=ls());gc()
library(rvest)
library(dplyr)
library(RMySQL)
library(xlsx)

# 首先連結電影版首頁
url <- "https://www.ptt.cc/bbs/movie/index.html"

# 利用上一頁面的連結推斷目前在第幾頁
pageNum <- read_html(url, encoding = "utf-8") %>%
  html_nodes(xpath="//a[@class='btn wide'][2]") %>%   # 指定到上一頁 
  html_attr("href") %>%                               # 取得href屬性的值
  gsub("\\D","",.) %>% 
  as.numeric()

# 讀取頁數
pageRead <- 300  

# 建立文章連結表
articleTable <- NULL

# 迴圈翻取各頁各文章的連結
for(page in seq((pageNum-pageRead), (pageNum+1), 1)){
  
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
  removeSite <- grep("\\刪除)",title)
  if(length(removeSite)>0){
    articleDate <- articleDate[-removeSite]
    title <- title[-removeSite]
  }
  
  # 儲存資料  
  articleTable <- bind_rows(articleTable, tibble(articleDate, title, link))
  
  # 暫停延緩
  Sys.sleep(0.1)
}

# 判斷文章類別
movieData <- read.xlsx("./movieData/電影資訊.xlsx", sheetIndex=1, encoding="UTF-8", stringsAsFactors=FALSE) %>% 
  as_data_frame()
movieName <- movieData$movieName

# 迴圈電影名稱進行聲量分析
articleTable$movie <- rep("NULL", nrow(articleTable))
for(ix in 1:nrow(movieData)){
  
  # 聲量分析電影名稱
  movieName <- movieData$movieName[ix]
  
  # 相關文章
  relativeTitle <- articleTable$title[grep(movieName, articleTable$title)]
  
  # 於ptt文章後面紀錄
  articleTable$movie[articleTable$title %in% relativeTitle] <- movieName
}

# 儲存檔案
save(articleTable, file="./movieData/pttMovieArticle.Rdata")

# 寫入資料庫
filePath <- "C:/Users/Su-Yen-Ting/Desktop"
con <- dbConnect(dbDriver("MySQL"), host="140.117.70.217",user='yen_ting',password='quant')
write.table(articleTable, paste0(filePath,"/article_data.txt"),
            sep = "\t",row.names = FALSE,col.names = FALSE,quote = FALSE,fileEncoding ="utf8")
dbSendQuery(con,"SET SQL_SAFE_UPDATES=0;")
dbSendQuery(con,"TRUNCATE movie.article_data;")
dbSendQuery(con, paste0("load data local infile '",filePath,"/article_data.txt' into table movie.article_data LINES TERMINATED BY '\r\n';"))
dbDisconnect(con)


