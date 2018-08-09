## Google Trends爬蟲程式範例
# 程式撰寫: 中山財管所 研究助理 蘇彥庭
# 爬取方式參考網站:https://www.jianshu.com/p/b9d95ad418b6

# 程式簡要說明:
# Google Trends的搜尋熱度趨勢變化資料主要是放在https://trends.google.com.tw/trends/api/widgetdata/multiline這個API
# 但因為POST參數內有一個token參數是由Google給的
# 而token參數可透過https://trends.google.com.tw/trends/api/explore這個API取得
# 因此程式分成兩階段爬取，第一階段先找出token參數，第二階段再找到趨勢資料
rm(list=ls());gc()
library(rvest)
library(dplyr)
library(jsonlite)

#匯入要找的資料
event <- read.csv("CRASH事件日1229.csv")
keyword <- as.character(event$TICKER)
geo <- ""                           # 查詢全球無需給參數
startDate <- as.Date(event$START)
endDate <-  as.Date(event$END)
category <- "0"  

# # 查詢資料設定
# keyword <- "NSYSU"           # 查詢關鍵字
# geo <- "TW"                  # 地區
# startDate <- "2016-04-15"    # 查詢起始日期
# endDate <- "2018-04-14"      # 查詢結束日期
# category <- "0"              # 類別 ex:0為所有類別，958為工作與教育

for(i in 1:nrow(event)){
  
  if((startDate[i]<"2004-01-01")){
    cat("第 ",i," 筆事件發生在2004-01-01以前，Google尚未有資料\n")
    next
  }else{
    cat("目前正在下載第 ",i," 筆事件搜尋熱度資料，進度: ",i," / ",nrow(event),"\n")
  }
  
  # 組建第一階段字串
  req <- paste0('{"comparisonItem":[{"keyword":"',keyword[i],'","geo":"',geo,
                '","time":"',startDate[i],' ',endDate[i],'"}],"category":',category,',"property":""}')
  
  # 組建第一階段網址
  url <- paste0("https://trends.google.com.tw/trends/api/explore?hl=zh-TW&tz=-480&req=",req,"&tz=-480")
  
  # 取得第一階段爬蟲的token參數值
  data <- read_html(URLencode(url), encoding = "utf-8") %>% 
    html_nodes(xpath="//body") %>%
    html_text()
  data <- substring(data,6,nchar(data)) %>% fromJSON()  # 濾掉前面5個字元後，即可轉為JSON格式
  token <- data$widgets[1,"token"]                      # 取出本次查詢的token參數
  
  # 組建第二階段字串
  if(nchar(geo)==0){
    req <- paste0('{"time":"',startDate[i],' ',endDate[i],'","resolution":"WEEK","locale":"zh-TW",',
                  '"comparisonItem":[{"geo":{},"complexKeywordsRestriction":{"keyword":[{"type":"BROAD","value":"',keyword[i],
                  '"}]}}],"requestOptions":{"property":"","backend":"IZG","category":',category,'}}')
  }else{
    req <- paste0('{"time":"',startDate[i],' ',endDate[i],'","resolution":"WEEK","locale":"zh-TW",',
                  '"comparisonItem":[{"geo":{"country":"',geo,'"},"complexKeywordsRestriction":{"keyword":[{"type":"BROAD","value":"',keyword[i],
                  '"}]}}],"requestOptions":{"property":"","backend":"IZG","category":',category,'}}')
  }
  
  # 組建第二階段網址
  url <- paste0("https://trends.google.com.tw/trends/api/widgetdata/multiline?hl=zh-TW&tz=-480&req=",req,"&token=",token)
  
  # 第二階段爬蟲取得資料
  data <- read_html(URLencode(url), encoding = "utf-8") %>% 
    html_nodes(xpath="//body") %>%
    html_text()
  
  data <- substring(data,6,nchar(data)) %>% fromJSON() # 濾掉前面5個字元後，即可轉為JSON格式
  result <- data$default$timelineData                  # Google Trends的搜尋熱度趨勢變化資料
  
}


