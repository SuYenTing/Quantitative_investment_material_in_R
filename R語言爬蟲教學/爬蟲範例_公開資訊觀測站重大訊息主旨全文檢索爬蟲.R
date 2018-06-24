# 公開資訊觀測站重大資訊詳細資料爬蟲程式
# 程式撰寫: 中山大學財務管理學系 研究助理 蘇彥庭
# 撰寫日期: 2018/06/24
# 程式說明: 此程式先至公開資訊觀測站重大資訊主旨檢索查詢資料，
# 再由主旨檢索資料頁面原始碼內找到重大資訊詳細資料的Post參數組合，
# 透過此Post參數組合找到最後的重大資訊詳細資料。

rm(list=ls());gc()
library(rvest)
library(tidyverse)

# 重大資訊查詢設定
searchKeyWord <- "董事長"     # 檢索關鍵字
searchYear <- 107             # 搜尋年度
searchMonth <- 6              # 搜尋月份
searchBegintDay <- 1          # 搜尋月份起始日
searchEndDay <- 31            # 搜尋月份結束日

# 重大資訊查詢網址
url <- paste0("http://mops.twse.com.tw/mops/web/ajax_t51sb10?",
              "encodeURIComponent=1&firstin=true&id=&key=&TYPEK=&Stp=4&go=false&",
              "COMPANY_ID=&r1=1&KIND=L&CODE=&keyWord=", searchKeyWord, "&year=", searchYear,
              "&month1=", searchMonth,"&begin_day=", searchBegintDay,"&end_day=",searchEndDay)

# 整理重大資訊網址詳細資料之參數
html <- read_html(url)  # 下載網頁內容

# 建立股票名稱與日期清單 用於判斷資料是否真的有下載下來
checkName <- html %>%
  html_nodes(xpath = "//tr/td[2]") %>%
  html_text() %>%
  gsub("\\s","", .)

checkDate <- html %>%
  html_nodes(xpath = "//tr/td[3]") %>%
  html_text()

# 整理詳細資料Post參數
postParameters <- html %>%                     
  html_nodes("td") %>%                         # 選擇td節點資料
  html_nodes("input") %>%                      # 再選擇input節點資料
  html_attr("onclick") %>%                     # 再選擇onclick屬性資料
  gsub('document.fm.|.value|"', "", .) %>%     # 刪除不必要的字串
  gsub('openWindow\\(,\\);', "", .) %>%        # 刪除不必要的字串
  strsplit(split = ";")                        # 以分號切割字串

# 逐步下載重大資訊網址詳細資料
output <- NULL
ix <- 1
for(ix in 1:length(postParameters)){
  
  cat(paste0("目前進度: ", ix, " / ", length(postParameters), "\n"))
  Sys.sleep(1)  # 緩衝爬蟲程式 
  
  # 讀取參數
  iPostParameters <- postParameters[[ix]]
  
  # 建立重大資訊網址連結
  url <- paste0("http://mops.twse.com.tw/mops/web/ajax_t05st01?step=2&colorchg=1&",
                iPostParameters[5],"&", iPostParameters[6],"&off=1&firstin=1&", iPostParameters[4],"&year=2018&month=6&",
                iPostParameters[3],"&", iPostParameters[2],"&", iPostParameters[1],"&b_date=1&e_date=1&t51sb10=t51sb10")

  # 股票代碼
  stockCode <- gsub("co_id=", "", iPostParameters[5])

  # 為避免被伺服器阻擋 此處透過while來暫停程式並重啟
  run <- T
  while(run==T){
    
    html <- try(read_html(url))  # 讀取網頁資料
    
    # 判斷網頁是否查詢過於頻繁 若查詢過於頻繁 則暫停數秒
    if(attributes(html)$class[1]=="try-error"){
      cat("伺服器直接阻擋 暫停程式60秒\n")
      Sys.sleep(60)
      next
    }
    
    severBanSignal <- grepl("查詢過於頻繁", html)
    if(severBanSignal==T){
      cat("查詢過於頻繁 暫停程式60秒\n")
      Sys.sleep(60)
      next
    }
    
    # 若皆無上述情況發生 則跳離while迴圈
    run <- F
  }
  
  # 判斷網頁是否查不到資料  若查不到資料則以警告形式提醒使用者
  noDataSignal <- grepl("資料庫中查無需求資料", html)
  if(noDataSignal==T){
    warning(paste0("股票代碼 ",stockCode, " 於日期 ", gsub("spoke_date=", "", iPostParameters[3])," 之重大訊息查無資料\n"))
    next  
  }
  
  # 股票名稱
  stockName <- html %>%
    html_nodes(xpath = "//tr[1]/td[@class='compName']") %>%
    html_text() %>%
    strsplit("\n") %>%
    unlist() %>%
    .[4] %>%
    gsub("\\s|公司提供", "", .)
  
  # 檢查點: 判斷是否未下載到資料
  if(checkName[ix]!=stockName){
    stop("股票名稱: Post資料與參數不一致")
  }
    
  # 序號
  number <- html %>%
    html_nodes(xpath = "//tr[1]/td[@class='odd'][1]") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 發言日期
  announceDate <- html %>%
    html_nodes(xpath = "//tr[1]/td[@class='odd'][2]") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 檢查點: 判斷是否未下載到資料
  if(checkDate[ix]!=announceDate){
    stop("發言日期: Post資料與參數不一致")
  }
  
  # 發言時間
  announceTime <- html %>%
    html_nodes(xpath = "//tr[1]/td[@class='odd'][3]") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 發言人
  spokesman <- html %>%
    html_nodes(xpath = "//tr[2]/td[@class='odd'][1]") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 發言人職稱
  spokesmanPosition <- html %>%
    html_nodes(xpath = "//tr[2]/td[@class='odd'][2]") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 發言人電話
  spokesmanTel <- html %>%
    html_nodes(xpath = "//tr[2]/td[@class='odd'][3]") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 主旨
  subject <- html %>%
    html_nodes(xpath = "//tr[3]/td[@class='odd']/pre/font") %>%
    html_text() %>%
    gsub("\\s", "", .)
    
  # 符合條款
  terms <- html %>%
    html_nodes(xpath = "//tr[4]/td[@class='odd'][1]") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 事實發生日
  occurrenceDate <- html %>%
    html_nodes(xpath = "//tr[4]/td[@class='odd'][2]") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 說明
  instructions <- html %>%
    html_nodes(xpath = "//tr[5]/td[@class='odd']/pre") %>%
    html_text() %>%
    gsub("\\s", "", .)
  
  # 儲存成資料表格式
  output <- output %>% 
    bind_rows(tibble(ix = ix,
                     stockCode = stockCode,
                     stockName = stockName,
                     number = number,
                     announceDate = announceDate,
                     announceTime = announceTime,
                     spokesman = spokesman,
                     spokesmanPosition = spokesmanPosition,
                     spokesmanTel = spokesmanTel,
                     subject = subject,
                     terms = terms,
                     occurrenceDate = occurrenceDate,
                     instructions = instructions))
}
  
