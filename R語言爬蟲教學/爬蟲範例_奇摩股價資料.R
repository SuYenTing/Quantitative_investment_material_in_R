# 爬蟲rvest套件範例-奇摩股價資料
# 程式撰寫: 蘇彥庭
# grep套件說明:http://molecular-service-science.com/2015/01/18/text-processing-in-r-using-grep/
rm(list=ls());gc()
library(rvest)
library(dplyr)

# 股票代碼
stockCode <- 2317

# 下載資料網址
url <- paste0("https://tw.stock.yahoo.com/q/q?s=",stockCode)

# 下載股價資料(使用css語法爬取)
data <- read_html(url, encoding = "big5") %>%
  html_nodes(css="td tr+ tr td") %>%  
  html_text()

# 下載股價資料(使用xml語法爬取)
data <- read_html(url, encoding = "big5") %>%
  html_nodes(xpath="//tr[2]/td") %>%  
  html_text()

# 整理資料
name <- gsub("\\加到投資組合","",data[2])    # 刪除"加到投資組合"文字
name <- gsub(stockCode,"",code)              # 刪除股票代碼整理出股票名稱
date <- gsub("\\-","",Sys.Date())            # 日期                      
time <- data[3]                              # 時間
price <- as.numeric(data[4])                 # 成交價
bid <- as.numeric(data[5])                   # 買價
ask <- as.numeric(date[6])                   # 賣價
volume <- as.numeric(gsub("\\,","",data[8])) # 成交量
lastClose <- as.numeric(data[9])             # 昨收
diff <- price-lastClose                      # 漲跌
open <- as.numeric(data[10])                 # 開盤價
high <- as.numeric(data[11])                 # 最高價
low <- as.numeric(data[12])                  # 最低價

output <- tibble(stockCode, name, date, time, price, bid, ask, volume, lastClose, diff, open, high, low)

