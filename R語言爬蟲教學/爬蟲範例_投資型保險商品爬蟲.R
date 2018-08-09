# 南山人壽投資型保險商品爬蟲
# 程式目標: 取得投資型保險商品基金池的基金統編或ISIN代碼 方便後續合併基金淨值資料
# 程式撰寫: 中山財管所 蘇彥庭 研究助理
rm(list=ls());gc()
library(tidyverse)
library(rvest)
library(jsonlite)
library(RCurl)
library(XML)

# 下載投資型保險商品清單
url <- "http://ilp.nanshanlife.com.tw/w/custom/djjson/SelectJson.djjson?a=P&P1=nanshan&P2=False&P3=False&P4=False&P5=0"
invLinkedPolicyName <- read_html(url, encoding = "Big5") %>%
  html_text() %>%
  fromJSON()
invLinkedPolicyName <- invLinkedPolicyName$ResultSet$Menu %>% as_data_frame()

# 目標保單代碼
targetPolicyCode <- "AWMSP"   # AWMSP: 南山人壽伴我一生躉繳變額壽險(AWMSP)

# 下載基金資訊
url <- paste0("http://ilp.nanshanlife.com.tw/w/custom/djjson/SearchProductJSON.djjson?P=", targetPolicyCode)
policyFund <- read_html(url, encoding = "Big5") %>%
  html_text() %>%
  fromJSON()
policyFund <- policyFund$ResultSet$Result %>% as_data_frame()

# 下載基金ISIN代碼
policyFundCode <- policyFund$V40   # 股票內部代碼
policyLocation <- policyFund$V41   # A:國內基金/ B:國外基金
output <- NULL                     # 建立儲存表
ix <- 1
for(ix in 1:length(policyFundCode)){
  
  # 由於國內和國外的基金資訊版面不同 故需用if來做區隔處理
  if(policyLocation[ix] == "A"){
    
    # 此基金為國內基金
    url <- paste0("http://ilp.nanshanlife.com.tw/w/wr/wr01.djhtm?a=", policyFundCode[ix])
    html <- try(read_html(url, encoding = "Big5"))
    
    # 若遇到字碼問題 則以RCurl的getURL函數來取得網頁資料
    # 並透過iconv來做字碼轉換 再透過read_html從character格式轉成xml格式
    if(any(attr(html,"class")=="try-error")){
      html <- getURL(url, .encoding='Big5') %>% 
        iconv(from="big5", to="utf-8", sub = "?") %>%
        iconv(from="utf-8", to="big5", sub = "?") %>%
        read_html()
    }
      
    # 讀取欄位名稱
    fundColname <- html %>%
      html_nodes(xpath = '//*[@id="SysJustIFRAMEDIV"]/table//tr[9]/th') %>%
      html_text()
    
    # 讀取欄位資料
    fundCode <- html %>%
      html_nodes(xpath = '//*[@id="SysJustIFRAMEDIV"]/table//tr[9]/td') %>%
      html_text()
    
  }else if(policyLocation[ix] == "B"){
    
    # 此基金為國外基金
    url <- paste0("http://ilp.nanshanlife.com.tw/w/wb/wb01.djhtm?a=", policyFundCode[ix])
    html <- try(read_html(url, encoding = "Big5"))
    
    # 若遇到字碼問題 則以RCurl的getURL函數來取得網頁資料
    if(any(attr(html,"class")=="try-error")){
      html <- getURL(url, .encoding='Big5')
    }else{
      html <- html %>% html_text()
    }
    
    # 讀取ISIN資料
    # 此處用xpath無法擷取到ISIN資料 非常奇怪 改用正規表達式抓取
    matchSite <- regexpr("\\ISIN Code", html)
    start <- matchSite+attr(matchSite, "match.length")
    stop <- start+11                           # ISIN固定12碼
    fundCode <- substring(html, start, stop)   # ISIN代碼
    fundColname <- "ISIN代碼"
    
  }else{
    
    # 特殊基金(非國內和國外基金 ETF之類的)
    # 額外處理 特別標記
    fundColname <- "需手動查詢"
    fundCode <- ""
  }
  
  # 儲存資訊
  output <- output %>%
    bind_rows(tibble(internalCode = policyFundCode[ix], fundColname = fundColname, fundCode = fundCode))
  
  # 呈現資訊
  cat(paste0("目前進度: ", ix, " / ", length(policyFundCode), "  基金內部代碼: ", policyFundCode[ix], "   ",
             fundColname, ": ", fundCode, "\n"))
}

# 整理爬蟲結果
output <- output %>%
  left_join(policyFund %>% select(internalCode = V40, fundName = V3),
            by = c("internalCode" = "internalCode"))





