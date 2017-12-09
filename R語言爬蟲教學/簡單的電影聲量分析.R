# 簡單的電影聲量分析
# 程式撰寫: 蘇彥庭
rm(list=ls());gc()
library(dplyr)
library(xlsx)

# 讀取電影資訊表(爬蟲範例_奇摩電影資訊.R程式結果)
movieData <- read.xlsx("./movieData/電影資訊.xlsx", sheetIndex=1, encoding="UTF-8") %>% as_data_frame()

# 讀取ptt文章資訊
load("./movieData/pttMovieArticle.Rdata")

# 建立儲存表
textAnalysis <- NULL

# 迴圈電影名稱進行聲量分析
for(ix in 1:nrow(movieData)){
  
  # 聲量分析電影名稱
  movieName <- movieData$movieName[ix]
  
  # 相關文章數
  relativeTitle <- articleTable$title[grep(movieName, articleTable$title)]
  
  # 聲量比率=相關文章數/總文章數(熱絡度)
  relativeRatio <- length(relativeTitle)/nrow(articleTable)
  
  # 推薦好文章數
  goodNums <- grep("好", relativeTitle) %>% length()
  
  # 推薦負文章數
  badNums <- grep("負", relativeTitle) %>% length()
  
  # 推薦好比率
  goodRatio <- goodNums/(goodNums+badNums)
  
  # 推薦壞比率
  badRatio <- badNums/(goodNums+badNums)
  
  # 儲存資訊
  textAnalysis <- bind_rows(textAnalysis, tibble(movieName, relativeRatio, goodNums, badNums, goodRatio, badRatio))
}

# 分析結果
analysisResult <- textAnalysis %>%
  filter(relativeRatio>0.005) %>%
  arrange(desc(goodRatio))







