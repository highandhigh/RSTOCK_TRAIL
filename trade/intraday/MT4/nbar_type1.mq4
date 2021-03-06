//+------------------------------------------------------------------+
//|                                                   nbar_type1.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#define MAGICNBAR 20150002
//--- input parameters
input int      n;
input int      m;
input bool     up;
input bool     isLong;// 是否做多
extern string logname;
int count_n = 0 ;
int count_m = 0 ;
bool pre_n = False;
bool ishold =False;
double lot = 0.01;
int slip = 2;
bool New_Bar = False;
int myRetry    = 10;
int myopenedticket = 0;
void Fun_New_Bar()                              
  {                                             
   static datetime New_Time=0;                  
   New_Bar=false;                               
   if(New_Time!=Time[0])                        
     {
      New_Time=Time[0];                         
      New_Bar=True;                                
     }
  }
  
void writeLog(string symbol,double lots,datetime opentime ,double openprice,datetime closetime,double closeprince,double profit)
{
   string ordertype =isLong?"buy":"sell";
   int file_handle=FileOpen(logname,FILE_READ|FILE_WRITE|FILE_CSV);
   if(file_handle!=INVALID_HANDLE)
     {
       FileSeek(file_handle,0,SEEK_END);
       FileWrite(file_handle,ordertype,symbol,lots,opentime,openprice,closetime,closeprince,profit);
       FileClose(file_handle);
     }
     else
     {
      Print("file open erro:",file_handle);
     }
}
  
void holdorder()
{
    count_n++;
   if(count_n == n)
   {
      int res= -1 ;
      int ctn_i = -1;
	   int ti = myRetry;
      if(isLong == True)
      {
         while(true){
             res =  OrderSend(Symbol(),OP_BUY,lot,Ask,slip,0,0,"",MAGICNBAR,0,Red);
             if(res > 0 )
             {
                ishold = True;
                myopenedticket = res;
                break;
             }
             ti--;
             if(ti<=0) break;        
         }  
      } 
      else
      {    
          while(true){
             res =  OrderSend(Symbol(),OP_SELL,lot,Bid,slip,0,0,"",MAGICNBAR,0,Red);
             if(res > 0 )
             {
                ishold = True;
                myopenedticket = res;
                break;
             }
             ti--;
             if(ti<=0) break;        
         } 
      }                          
      count_n = 0;
      pre_n = False;
   }
}

//平仓开仓的订单
void clearOrders()
{
    if(myopenedticket == 0 ) return;
     bool res = OrderSelect(myopenedticket,SELECT_BY_TICKET);
     if(res)
     {
         if(OrderType() == OP_BUY){
   		   while(!OrderClose(OrderTicket(),OrderLots(),Bid,slip));
   		}
   	  if(OrderType() == OP_SELL){
   		    while(!OrderClose(OrderTicket(),OrderLots(),Ask,slip));
   		}
   		writeLog(OrderSymbol(),OrderLots(),OrderOpenTime(),OrderOpenPrice(),OrderCloseTime(),OrderClosePrice(),OrderProfit());
     }
     else
     {
        Alert("we dont select this order:",myopenedticket);
     }  
    ishold = False;
    myopenedticket = 0 ;
}
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     count_n = 0 ;
     count_m = 0 ;
     pre_n = FALSE;
     ishold = FALSE;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Fun_New_Bar();
   if(New_Bar == False) { return;} //新bar时去交易
    Print("ok ",Time[0]);
   bool uporfall =((Close[1] - Open[1]) > 0)?True:False;//前一个bar涨跌情况
   if(ishold == False) //未持仓
   {
      if(pre_n == False && up == True && uporfall == True)
      {
         pre_n = True;
      }
      if(pre_n == False && up == False && uporfall == False)
      {
         pre_n = True;
      }
      if(pre_n == True && up == True && uporfall ==True)
      {
        holdorder();
      }
      else if(pre_n == True && up == False && uporfall ==False)
      {
          holdorder();
      }
      else
      {
         count_n = 0;
         pre_n = False;
      }
   }
   else // 已经持仓
   {
      count_m++;
      if(count_m == m)
      {
         clearOrders();
         count_m = 0;
      }
   }
  }
//+------------------------------------------------------------------+
