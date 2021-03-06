#通过yahoo更新
rm(list=ls(all=T))
source('D:/Rcode/code/RSTOCK_TRAIL/collectdata/include.R',encoding='utf8')

update_data_from_yahoo = function(symbol,tablename)
{
  data = readFromDataBase(tablename)
  lastdate = max(as.Date(data$date))
  begindate = lastdate + 1
  data_yahoo= data.frame()
  try((data_yahoo =adjustOHLC(getSymbols(symbol,auto.assign=F,from=begindate),use.Adjusted = T)),silent=T)
  if(nrow(data_yahoo) > 0 )
  {
    colnames(data_yahoo) = c('Open','High','Low','Close','Volume','adjust')
    if( data_yahoo$Volume > 0)
    {
      data_yahoo$Close = data_yahoo$adjust
      data_yahoo = data_yahoo[,1:5]
      dates = as.character(index(data_yahoo))
      data_yahoo = as.data.frame(data_yahoo)
      data_yahoo$date = dates
      insertToDataBase(tablename,data_yahoo)
    }
    else
    {
      print(paste(symbol,lastdate))
    }
  }
  else
  {
    print(paste(symbol,lastdate))
  }
}

config = list(c(symbol='000001.SS',tablename='shindex',exp='上证')
              #   ,c(symbol='399001.SZ',file='399001.txt',exp='深圳')
              ,c(symbol='^IXIC',tablename='ixic',exp='纳斯达克')
              ,c(symbol='^DJI',tablename='dji',exp='道琼斯')
              ,c(symbol='^GSPC',tablename='gspc',exp = '标准普尔')
              ,c(symbol='^N225',tablename='n225',exp = '日经225')
              ,c(symbol='^TWII',tablename='TWII',exp = '台湾台北加权指数')
              ,c(symbol='^HSI',tablename='HSI',exp = '恒生指数')
              ,c(symbol='^FCHI',tablename='FCHI',exp = '法国CAC40指数')
              ,c(symbol='^GDAXI',tablename='DAX',exp = '德国法兰克福DAX指数')
)

for(i in 1:length(config))
{
   l = config[[i]]
   symbol = l['symbol']
   tablename = l['tablename']
   update_data_from_yahoo(symbol,tablename)
}