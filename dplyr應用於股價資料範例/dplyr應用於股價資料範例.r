
library(dplyr)
library(quantmod)

load("stockPriceData.Rdata")

head(stockPriceData, 10)

class(stockPriceData)

stockPriceData <- stockPriceData %>% as_data_frame() 

class(stockPriceData)

stockPriceData %>% filter(code==1101)

stockPriceData %>% filter(code==1101 & date==20170103)

stockPriceData %>% filter(code==1101, date==20170103)

stockPriceData %>% filter(code==1101 | code==1102)

stockPriceData %>% filter(code==c(1101,1102,1103))

stockPriceData %>% arrange(code)

stockPriceData %>% arrange(code, date)

stockPriceData %>% arrange(desc(date))

stockPriceData %>% arrange(desc(code), date)

stockPriceData %>% mutate(diffOpenClose=close-open)

stockPriceData %>% mutate(diffOpenClose=close-open, diffHighLow=high-low)

stockPriceData %>% transmute(code, name, date, diffOpenClose=close-open, diffHighLow=high-low)

stockPriceData %>% transmute(date, name, close)

stockPriceData %>% rename(stockCode=code, tradeDate=date)

stockPriceData %>% distinct(date)

stockPriceData %>% distinct(code, name)

groupData <- stockPriceData %>% group_by(code)
print(groupData)

noGroupData <- groupData %>% group_by()
print(noGroupData)

stockPriceData %>% group_by(code) %>% summarise(meanVolume=mean(tradeVolume), maxClose=max(close), minClose=min(close))

stockPriceData %>% slice(1:10)

stockPriceData %>% group_by(code) %>% slice(1:5)

stockPriceData %>% mutate(num=row_number())

stockPriceData %>% mutate(totalNums=n())

stockPriceData %>% group_by(code) %>% summarise(tradeDayNums=n())

stock_1101 <- stockPriceData %>% filter(code==1101) %>% select(date, close_1101=close) # 製作1101台泥的收盤價資料表
stock_1102 <- stockPriceData %>% filter(code==1102) %>% select(date, close_1102=close) # 製作1102亞泥的收盤價資料表
joinData <- stock_1101 %>% left_join(stock_1102, by=c("date"="date"))                  # 併表(此處以1101為主表)
joinData

# 製作1101台泥的收盤價資料表
stock_1101 <- stockPriceData %>% filter(code==1101 & date<=20170109) %>% select(date, close) 

# 製作1102亞泥的收盤價資料表
stock_1102 <- stockPriceData %>% filter(code==1102 & date<=20170109) %>% select(date, close)

bind_rows(stock_1101, stock_1102)

bind_cols(stock_1101, stock_1102)

stockPriceData %>%        
arrange(code, date) %>%      # 按股票代號及日期進行排序
group_by(code) %>%           # 以股票代號為群組
filter(n()>60) %>%           # 過濾交易日數不足股票:避免交易日數低於60日無法計算移動平均線Bug
mutate(MA5=SMA(close,5),     # 計算5日移動平均線
       MA20=SMA(close,20),   # 計算20日移動平均線
       MA60=SMA(close,60))   # 計算60日移動平均線

stockPriceData %>%        
arrange(code, date) %>%        # 按股票代號及日期進行排序
group_by(code) %>%             # 以股票代號為群組
mutate(lagClose=lag(close,1),  # 昨日收盤價:lag股價一期
       ret=close/lagClose-1)   # 報酬率=今日收盤價/昨日收盤價-1

stockPriceData %>%        
arrange(code, date) %>%          # 按股票代號及日期進行排序
group_by(code) %>%               # 以股票代號為群組
filter(n()>10) %>%               # 過濾交易日數不足股票:避免交易日數低於10日無法計算移動平均線Bug
mutate(MA5=SMA(close,5),         # 計算5日移動平均線
       MA10=SMA(close,10),       # 計算10日移動平均線
       lagMA5=lag(MA5,1),        # 昨日5日移動平均線
       lagMA10=lag(MA10,1)) %>%  # 昨日10日移動平均線
filter(lagMA5<lagMA10, MA5>MA10) # 黃金交叉條件(昨日5日均線<昨日10日均線，今日5日均線>今日10日均線)
