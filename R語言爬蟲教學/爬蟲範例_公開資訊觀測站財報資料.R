# 爬蟲rvest套件範例-公開資訊觀測站範例
# 程式撰寫: 蘇彥庭
rm(list=ls());gc()
library(RCurl)
library(dplyr)
library(XML)

# 參數設置
stockCode <- 2317   # 股票代碼
reportYear <- 2017  # 財報年份
reportSeason <- 2   # 財報季度

# 下載資料網址
url <- paste0("http://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID=",
              stockCode,"&SYEAR=",reportYear,"&SSEASON=",reportSeason,"&REPORT_ID=C")

#### 資產負債表 ####
# 資產負債表標題
balanceSheetTitle <- getURL(url, .encoding="big5") %>%
  iconv(from="big5", to="utf-8") %>%
  htmlParse(encoding="utf-8") %>%
  xpathSApply(path="//table[@class='result_table hasBorder']//tr[@class='tblHead'][1]/th", xmlValue) %>%
  matrix(ncol=4, byrow=T)

# 資產負債表
balanceSheet <- getURL(url, .encoding="big5") %>%
  iconv(from="big5", to="utf-8") %>%
  htmlParse(encoding="utf-8") %>%
  xpathSApply(path="//table[@class='result_table hasBorder']//tr/td", xmlValue) %>%
  matrix(ncol=4, byrow=T)

# 整理資產負債表
colnames(balanceSheet) <- balanceSheetTitle


#### 損益表 ####
# 損益表標題
incomeStatementTitle <- getURL(url, .encoding="big5") %>%
  iconv(from="big5", to="utf-8") %>%
  htmlParse(encoding="utf-8") %>%
  xpathSApply(path="//table[@class='main_table hasBorder'][1]//tr[@class='tblHead'][1]/th", xmlValue) %>%
  matrix(ncol=5, byrow=T)

# 損益表
incomeStatement <- getURL(url, .encoding="big5") %>%
  iconv(from="big5", to="utf-8") %>%
  htmlParse(encoding="utf-8") %>%
  xpathSApply(path="//table[@class='main_table hasBorder'][1]//tr/td", xmlValue) %>%
  matrix(ncol=5, byrow=T)

# 整理損益表
colnames(incomeStatement) <- incomeStatementTitle

#### 現金流量表 ####
# 現金流量表標題
cashFlowTitle <- getURL(url, .encoding="big5") %>%
  iconv(from="big5", to="utf-8") %>%
  htmlParse(encoding="utf-8") %>%
  xpathSApply(path="//table[@class='main_table hasBorder'][2]//tr[@class='tblHead'][1]/th", xmlValue) %>%
  matrix(ncol=3, byrow=T)

# 現金流量表
cashFlow <- getURL(url, .encoding="big5") %>%
  iconv(from="big5", to="utf-8") %>%
  htmlParse(encoding="utf-8") %>%
  xpathSApply(path="//table[@class='main_table hasBorder'][2]//tr/td", xmlValue) %>%
  matrix(ncol=3, byrow=T)

# 整理現金流量表標題
colnames(cashFlow) <- cashFlowTitle

