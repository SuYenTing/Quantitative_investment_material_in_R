# 爬蟲rvest套件範例-臺灣證交所
# 程式撰寫: 蘇彥庭
rm(list=ls());gc()
library(rvest)
library(dplyr)

#### 爬取單一股票 ####
# 連結
url <- "http://www.twse.com.tw/exchangeReport/MI_INDEX?response=html&type=ALLBUT0999"

# 股價資料表標題
stockTitle <- read_html(url, encoding = "utf-8") %>%
  html_nodes(xpath="//table[5]/thead/tr[3]/td") %>%  
  html_text() %>%
  matrix(ncol=16, byrow=T) 

# 股價資料表
stockPriceData <- read_html(url, encoding = "utf-8") %>%
  html_nodes(xpath="//table[5]/tbody/tr/td") %>%  
  html_text() %>%
  matrix(ncol=16, byrow=T) %>%
  as_data_frame()

# 替換股價資料表標題
colnames(stockPriceData) <- stockTitle

#### 爬取一段期間的股價資料 ####
# 爬取期間
dateList <- seq.Date(from=as.Date("2017-11-01"), to=as.Date("2017-11-30"), "days") %>% gsub("\\-","",.)

# 儲存表
output <- NULL

for(di in 1:length(dateList)){
  
  cat(paste0("目前正在下載 ",dateList[di]," 交易日，進度: ",di," / ",length(dateList),"\n"))
  
  # 連結
  url <- paste0("http://www.twse.com.tw/exchangeReport/MI_INDEX?response=html&date=",
                dateList[di],"&type=ALLBUT0999")
  
  # 判斷當日是否有股價資料
  contnet <- read_html(url, encoding = "utf-8") %>% 
    html_nodes(xpath="/html/body/div[1]") %>%  
    html_text()
    
  if(grepl("沒有符合條件的資料",contnet)==F){
    
    # 股價資料表標題
    stockTitle <- read_html(url, encoding = "utf-8") %>%
      html_nodes(xpath="//table[5]/thead/tr[3]/td") %>%  
      html_text() %>%
      matrix(ncol=16, byrow=T) 
    
    # 股價資料表
    stockPriceData <- read_html(url, encoding = "utf-8") %>%
      html_nodes(xpath="//table[5]/tbody/tr/td") %>%  
      html_text() %>%
      matrix(ncol=16, byrow=T) %>%
      as_data_frame()
    
    # 替換股價資料表標題
    colnames(stockPriceData) <- stockTitle
    
    # 儲存資料
    output <- bind_rows(output, stockPriceData)
    
  }else{
    cat(paste0("交易日 ",dateList[di]," 未開盤\n"))
  }
  
  # 暫停延緩
  Sys.sleep(5)
}

