## 國泰人壽投資型保單爬蟲
## 程式主要撰寫: 政大風管所 陳暐文
## 程式協助撰寫: 中山財管所 蘇彥庭

rm(list=ls());gc()
library(rvest)
library(dplyr)
library(stringr)
library(jsonlite)

# 下載保單代碼
url <- "https://cathaylife.moneydj.com/w/wa/ProductListJs.djjs"
invLinkedPolicyName <- read_html(url, encoding = "Big5") %>%
  html_nodes(xpath ="//body") %>%
  as.character()

# 刪除多餘字串讓rvest讀HTML語法
startSite <- regexpr("<ul>",  invLinkedPolicyName)
endSite <- regexpr("</ul>",  invLinkedPolicyName)
invLinkedPolicyName <- substring(invLinkedPolicyName, startSite, endSite+attr(endSite,"match.length")-1) %>%
  read_html() %>%
  html_nodes(xpath = "//a")

# 整理字串
invLinkedPolicyName <- tibble(name = invLinkedPolicyName %>% html_text,
                              policyLink = invLinkedPolicyName %>% html_attr("href"))
invLinkedPolicyName <- invLinkedPolicyName %>% filter(name != "配息" , name != "")   # 刪除配息代碼

# 取得網址的保單代碼
GetPolicyCode <- function(webLink){
  matchSite <- regexpr("prod=", webLink)
  policyCode = substring(webLink, matchSite+attr(matchSite,"match.length"), nchar(webLink))
  return(policyCode)
}
invLinkedPolicyName <- invLinkedPolicyName %>% mutate(policyCode = GetPolicyCode(policyLink))

# 指定保險商品代碼(policycode)，即可用下方程式碼抓出所有基金資訊
policycode <- "TV"
url <- paste0("https://cathaylife.moneydj.com/w/djjson/CathlifeSearchJSON.djjson?P=",policycode)
fund <- read_html(url, encoding = "big5") %>%
  html_text() %>%
  fromJSON() %>% as.data.frame()
internalCode <- fund[,4]

#辨別MoneyDJ代碼
DJcode <- matrix(NA,length(internalCode),1)
for(i in 1:length(internalCode)){
  DJcode[i,1] <- word(internalCode[i], 1, sep = fixed("-"))}

#連接至MoneyDJ抓取基金資料
output<- NULL
for (j in 1:length(DJcode)){
  #辨別基金為國內基金 or 國外基金，所使用網址不同
  if(fund[j,41] == "境內"){
    DJurl <- paste0("https://www.moneydj.com/funddj/yp/yp011000.djhtm?a=",DJcode[j])
    data <- read_html(DJurl, encoding = "big5") %>%
      html_nodes(xpath ="//tr/td[@class='t3t2']") %>%  
      html_text()
    result_1 <- cbind(internalCode[j],"基金統編",data[20],fund[j,5])
    output <- rbind(output,result_1) 
  }
  else{
    DJurl <- paste0("https://www.moneydj.com/funddj/yp/yp011001.djhtm?a=",DJcode[j])
    data <- read_html(DJurl, encoding = "big5") %>%
      html_nodes(xpath ="//tr/td[@class='t3t2']") %>%  
      html_text()
    result_2 <- cbind(internalCode[j],"ISINCode",data[21],fund[j,5])
    output <- rbind(output,result_2)
  }
  
  #呈現進度
  cat(paste0("目前進度： ", j, " / ", length(DJcode), "   基金內部代碼： ", internalCode[j], "\n"))
}

colnames(output) <- c("InternalCode","FundColname","FundCode","FundName")

