rm(list=ls(all=T))
source('D:/Rcode/code/RSTOCK_TRAIL/globaltool/include.R',encoding='utf8')
source('D:/Rcode/code/RSTOCK_TRAIL/globaltool/readdata.R',encoding='utf8')
sourceDir('D:/Rcode/code/RSTOCK_TRAIL/trade/eventAnalysis',encoding='utf8')

doubo_m = read_m_1m_taobao()
douyou_m = read_y_1m_taobao()
corp_m = read_c_1m_taobao()
dou1_m = read_s1_1m_taobao()

dou1_day = to_day(dou1_m)
doubo_day = to_day(doubo_m)
douyou_day = to_day(douyou_m)
corp_day = to_day(corp_m)

#对齐开盘时间
index(doubo_m) = index(doubo_m) - 60
index(douyou_m) = index(douyou_m) - 60
index(corp_m) = index(corp_m) - 60
index(dou1_m) = index(dou1_m) - 60

doubo_15m = to_minutes(doubo_m,k=15)
douyou_15m = to_minutes(douyou_m,k=15)
corp_15m = to_minutes(corp_m,k=15)
dou1_15m = to_minutes(dou1_m,k=15)


pricedata = dou1_m
days = as.character(unique(as.Date(index(pricedata))))

records = data.frame()
for(day in days)
{
  p = pricedata[day]
  if(nrow(p) ==0) next
  perdstart = paste(day,'09:00:00')
  perdend = paste(day,'15:00:00')
  perd = paste(perdstart,perdend,sep='/')
  nperd = nrow(p[perd])
  if(nperd == 0) next
  
  time1 = paste(day,'09:01:00')
  time2 = paste(day,'09:10:00')
  time3 = paste(day,'15:00:00')
  
  open = as.numeric(p[time1]$Open)
  end1 = as.numeric(p[time2]$Close)
  end2 = as.numeric(p[time3]$Close)
  r = data.frame(date=day,open = open,end1 = end1,end2=end2,sign1 = sign(end1 - open),sign2 = sign(end2 - open))
  records = rbind(records,r)
}

years = unique(substring(days,1,7))
anlysisframe = data.frame()
for(y in years)
{
  sub = subset(records,substring(date,1,7) == y)
  sub1 = subset(sub,sign1 == sign2)
  ratio = nrow(sub1) / nrow(sub)
  a = data.frame(year = y , ratio = ratio)
  anlysisframe = rbind(anlysisframe,a)
}

#最高最低点 时间分布统计 暂时只考虑9-15点
maxtime  = c()
mintime = c()
for(day in days)
{
  p = pricedata[day]
  if(nrow(p) ==0) next
  perdstart = paste(day,'09:00:00')
  perdend = paste(day,'15:00:00')
  perd = paste(perdstart,perdend,sep='/')
  nperd = nrow(p[perd])
  if(nperd == 0) next
  p = p[perd]
  maxp = max(p$High)
  maxi = which(p$High == maxp)
  maxi = unique(substring(as.character(index(p[maxi,])),12,13))
  maxtime = c(maxtime,maxi)
  
  minp = min(p$Low)
  mini = which(p$Low == minp)
  mini = unique(substring(as.character(index(p[mini,])),12,13))
  mintime = c(mintime,mini)
}
aggregate(maxtime,by = list(maxtime),length)
aggregate(mintime,by = list(mintime),length)

#回测
records = data.frame()
for(day in days)
{
  p = pricedata[day]
  if(nrow(p) ==0) next
  perdstart = paste(day,'09:00:00')
  perdend = paste(day,'15:00:00')
  perd = paste(perdstart,perdend,sep='/')
  nperd = nrow(p[perd])
  if(nperd == 0) next
  
  time1 = paste(day,'09:01:00')
  time2 = paste(day,'09:10:00')
  time3 = paste(day,'15:00:00')
  
  open = as.numeric(p[time1]$Open)
  end1 = as.numeric(p[time2]$Close)
  end2 = as.numeric(p[time3]$Close)
  type = ''
  if((end1 - open) < 0 )
  {
    type = 'short'
  }
  else if((end1 - open) == 0)
  {
    next
  }
  else
  {
    type = 'long'
  }
  
  i = which(as.character(index(p)) == time2) + 1
  enter = as.numeric(p[i,]$Open)
  if(type =='short')
  {
    stopprice = open + 100
    stopwin = enter - 10
  }
  else
  {
    stopprice = open - 100
    stopwin = enter + 10
    
  }
  isstop = F
  for(idx in i : nrow(p))
  {
    idxcl = as.numeric(p[idx,]$Close)
    if(type == 'short')
    {
      if(idxcl > stopprice)
      {
        isstop = T
        r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = enter - idxcl )
        records = rbind(records,r)
        break
      }
      
      if(idxcl < stopwin)
      {
      #  isstop = T
       # r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = enter - idxcl )
       # records = rbind(records,r)
      #  break
      }
    }
    else
    {
      if(idxcl < stopprice)
      {
        isstop = T
        r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = idxcl - enter )
        records = rbind(records,r)
        break
      }
      
      if(idxcl > stopwin)
      {
       # isstop = T
      #  r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = enter - idxcl )
       # records = rbind(records,r)
      #  break
      }
    }
  }
  if(isstop == F)
  {
    r = data.frame(time = index(p[idx,]),enter=enter,out =idxcl,isstop = isstop,type = type , profit = ifelse(type == 'long',(idxcl - enter),( enter - idxcl)) )
    records = rbind(records,r)
  }
}


#回测-早上九点时段决定区间
records = data.frame()
for(day in days)
{
  print(day)
  p = pricedata[day]
  if(nrow(p) ==0) next
  perdstart = paste(day,'09:00:00')
  perdend = paste(day,'15:00:00')
  perd = paste(perdstart,perdend,sep='/')
  nperd = nrow(p[perd])
  if(nperd == 0) next
  p = p[perd]
  
  time1 = paste(day,'09:01:00')
  time2 = paste(day,'10:00:00')
  tp = paste(time1,time2,sep='/')
  
  open = as.numeric(p[time1]$Open)
  upperline = max(p[tp]$High)[1] +3 
  lowerline = min(p[tp]$Low)[1]  - 3
  centerline = floor((upperline + lowerline) / 2)
  if((upperline - lowerline) < 20) next
  
  i = which(as.character(index(p)) == time2) + 1
  type = ''
  ishold = F
  stepped = F
  longcount = 0
  shortcount = 0
 # idx = i
  for(idx in i : (nrow(p)-1))
  {
    idxcl = as.numeric(p[idx,]$Close)
    if(idxcl > upperline && ishold == F && longcount < 1)
    {
      ishold = T
      type = 'long'
      enter = as.numeric(p[idx+1,]$Open)
      entertime = index(p[idx+1,])
      stopprice = centerline
      stopwinprice = enter
      longcount = longcount + 1
      next
    }
    if(idxcl < lowerline  && ishold == F && shortcount < 1)
    {
      ishold = T
      type = 'short'
      enter = as.numeric(p[idx+1,]$Open)
      entertime = index(p[idx+1,])
      stopprice = centerline
      stopwinprice = enter
      shortcount = shortcount + 1
      next
    }
    
    if(ishold == T)
    {
      if(type == 'long')
      {
        #止损
        if(idxcl < stopprice)
        {
          out = as.numeric(p[idx+1,]$Open)
          outtime = index(p[idx+1,])
          r = data.frame(entertime = entertime,enter = enter,outtime = outtime,out = out,stepped=stepped,isstop = T,type = type,profit =out-enter,up=upperline-open,low=open-lowerline)
          records = rbind(records,r)
          ishold = F
          
        }
        #移动止损
        if(idxcl > stopwinprice + 10)
        {
          stepped = T
          stopprice = stopwinprice + 5
          stopwinprice = idxcl
          
        }
      }
      if(type == 'short')
      {
        #止损
        if(idxcl > stopprice)
        {
          out = as.numeric(p[idx+1,]$Open)
          outtime = index(p[idx+1,])
          r = data.frame(entertime = entertime,enter = enter,outtime = outtime,out = out,stepped=stepped,isstop = T,type = type,profit =enter-out,up=upperline-open,low=open-lowerline)
          records = rbind(records,r)
          ishold = F
          
        }
        if(idxcl < stopwinprice - 10)
        {
          stepped = T
          stopprice = stopwinprice  - 5
          stopwinprice = idxcl
          
          
        }
      }
    }
  }
  if(ishold == T)
  {
    out = as.numeric(p[idx+1,]$Open)
    outtime = index(p[idx+1,])
    r = data.frame(entertime = entertime,enter = enter,outtime = outtime,out = out,stepped=stepped,isstop = F,type = type,profit =ifelse(type == 'long',(out-enter),(enter-out)),up=upperline-open,low=open-lowerline)
    records = rbind(records,r)
  }
  
  
}

year = substring(records$entertime,1,4)
months = substring(records$entertime,1,6)
profits = records$profit
aggregate(x=profits,by=list(year),sum)
length(profits[profits>0]) / length(profits)
sum(profits)
length(profits)
sum(profits[profits>0])
sum(profits[profits<0])


subrecords = subset(records,substring(records$entertime,1,4) == '2016')
subprofits = subrecords$profit
subyear = substring(subrecords$entertime,1,7)
aggregate(x=subprofits,by=list(subyear),sum)

sum(subprofits)
length(subprofits[subprofits>0]) / length(subprofits)
sum(subprofits[subprofits>0])
sum(subprofits[subprofits<0])


#开盘n分钟跳空,大阴大阳
#考虑每个开盘瞬间的跳空情况，相关市场跳空情况，跳空后第一根k线涨跌情况，不同时间框架下的
#跳空情况，判定条件是到一定时期收盘是否会有关闭缺口的迹象
pricedata_m = corp_15m
pricedata_m$smashort = lag(SMA(Cl(pricedata_m),3),1)
pricedata_m$smalong= lag(SMA(Cl(pricedata_m),10),1)

pricedata = corp_day
days = as.character(unique(as.Date(index(pricedata))))
alltime = index(pricedata_m)
time = '09:00:00'
time1 = '11:30:00'

result = data.frame()
resultfirst = c()
for(day in days[2:length(days)])
{
  iday = which(days == day)
  preday = days[iday - 1]
  opentime = paste(day,time)
  endtime = paste(day,time1)
  
  idx = which(alltime == opentime)
  endidx = which(alltime == endtime)
  
  if(length(idx) == 0) next
  precloseidx = idx - 1
  
  preday_votile = as.numeric(Cl(pricedata[preday]) - Op(pricedata[preday]))
  
  open = as.numeric(Op(pricedata_m[idx,]))
  close = as.numeric(Cl(pricedata_m[idx,]))
  starthigh =  as.numeric(Hi(pricedata_m[idx,]))
  startlow =  as.numeric(Lo(pricedata_m[idx,]))
  
  prehigh = as.numeric(Hi(pricedata_m[precloseidx,]))
  prelow = as.numeric(Lo(pricedata_m[precloseidx,]))
  
  
  
  smashort = as.numeric(pricedata_m[idx,]$smashort)
  smalong = as.numeric(pricedata_m[idx,]$smalong)
  
  upgap = open - prehigh
  downgap = prelow - open
  
  if(abs(close - open) > 20) resultfirst = c(resultfirst,day)
  
  if(upgap > 0)
  {
    type = 'up'
  }
  else if(downgap > 0)
  {
    type = 'down'
  }
  else
  {
    type = ''
    next
  }
  
  votile = close - open
  r = data.frame(day,type =type,votile = votile,smalong=smalong,smashort=smashort,signvotile = sign(votile),signsma=sign(smashort-smalong))
  result = rbind(result,r)
}


downset = subset(result,signsma =='-1')
sumdown = sum(downset$votile)
vdown = downset$votile 
rdown = length(vdown[vdown>0])/length(vdown)

upset =  subset(result,type =='up')
sumup = sum(upset$votile)
vup = upset$votile
rup = length(vup[vup < 0])/length(vup)

rdataframe = as.data.frame(result)
rdataframe$signvotile = as.factor(rdataframe$signvotile)
rdataframe$signsma = as.factor(rdataframe$signsma)
rdataframe$preday_votile = as.factor(rdataframe$preday_votile)

ct <- rpart.control(xval=10, minsplit=20, cp=0.001)  
fit = rpart(signvotile ~ signsma + type + preday_votile,data = rdataframe,control = ct)
rpart.plot(fit)

sub = subset(rdataframe,type == 'down' & signsma == '-1' & preday_votile == '-1')
chisq.test(rdataframe$signvotile,rdataframe$preday_votile)
chisq.test(rdataframe$signvotile,rdataframe$type)
chisq.test(rdataframe$signvotile,rdataframe$signsma)

#回测,以第一根k线作为参考
records = data.frame()
for(i in 1:nrow(result))
{
  r = result[i,]
  day = as.character(as.Date(r$day))
  starttime = paste(day,'09:00:00')
  endtime = paste(day,'15:00:00')
  span = paste(starttime,endtime,sep='/')
  intraprice = pricedata_m[span]
  
  high = as.numeric(Hi(intraprice[1,]))
  low = as.numeric(Lo(intraprice[1,]))
  ishold = F
  type = ''
  long = F
  short = F
  gaptype = result[i,]$type
  breakhigh = F
  breaklow = F
  for(j in 2:nrow(intraprice)-1)
  {
    #最后n分钟突破 不再交易
    if(j > (nrow(intraprice) - 10) && ishold == F) break
    
    if(long || short)
    {
      open = as.numeric(Op(intraprice[j,]))
      entertime = as.character(index(intraprice[j,]))
      long = F
      short = F
      ishold = T
    }
    
    cl =as.numeric(Cl(intraprice[j,]))
    if(cl > high && ishold == F && breakhigh == F)
    {
     # type = 'long'
      breakhigh = T
     # long = T
     # next
    }
    if(cl < low && ishold == F && breaklow ==F )
    {
     # type = 'short'
      breaklow = T
      #short = T
     # next
    }
    
    if(cl < high && ishold == F && breakhigh == T)
    {
      breakhigh = F
      type = 'short'
      short = T
    }
    if(cl > low && ishold == F && breaklow == T)
    {
      breaklow = F
      type = 'long'
      short = T
    }
  }
  if(ishold == T )
  {
    out = as.numeric(Op(intraprice[j,]))
    outtime = as.character(index(intraprice[j,]))
    r = data.frame(entertime = entertime,open=open,out=out,outtime=outtime,type = type,profit = ifelse(type=='long',out-open,open-out))
    records = rbind(records,r)
  }
}

#区间法

