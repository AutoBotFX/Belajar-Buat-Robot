//+------------------------------------------------------------------+
//|                                                      robot01.mq4 |
//|                                                     Yulianto Hiu |
//|                                               https://robotop.id |
//+------------------------------------------------------------------+
#property copyright "Yulianto Hiu"
#property link      "https://robotop.id"
#property version   "1.00"
#property strict


input    double      inLotSize   = 0.01;     //Lot Size
input    int         inMAFastPeriod = 10;       //MA Fast Period
input    int         inMASlowPeriod = 30;       //MA Slow Period
input    ENUM_MA_METHOD inMAMethod  = MODE_SMA; //MA Method
input    ENUM_APPLIED_PRICE inMAPrice  = PRICE_CLOSE;  //MA Applied to

double gMinLot, gMaxLot, gLotStep;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
   gMinLot  = MarketInfo(Symbol(), MODE_MINLOT);
   gMaxLot  = MarketInfo(Symbol(), MODE_MAXLOT);
   gLotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   
   
   
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

   bool  isNewCandle = false;
   isNewCandle = checkNewCandle();
   
   int orderType = -1;
   
   //if (isNewCandle == true){
   if (isNewCandle){
      orderType = getSignal();
   }
   
   openOrder(orderType);
   
  }
//+------------------------------------------------------------------+

bool checkNewCandle(){
   bool isNewCandle  = false;
   
   static datetime jamCandle  = TimeCurrent();
   if (jamCandle < iTime(NULL, 0, 0) ){
      isNewCandle = true;
      jamCandle   = iTime(NULL, 0, 0);
   }
   
   return (isNewCandle);

}


int getSignal(){
   int signal = -1;
   
   double MAFast2 = iMA(Symbol(), 0, inMAFastPeriod, 0, inMAMethod, inMAPrice, 2);
   double MAFast1 = iMA(Symbol(), 0, inMAFastPeriod, 0, inMAMethod, inMAPrice, 1);
   
   double MASlow2 = iMA(Symbol(), 0, inMASlowPeriod, 0, inMAMethod, inMAPrice, 2);
   double MASlow1 = iMA(Symbol(), 0, inMASlowPeriod, 0, inMAMethod, inMAPrice, 1);
   
   if (MASlow2 > MAFast2 && MASlow1 < MAFast1){
      signal   = OP_BUY;
   }else if (MASlow2 < MAFast2 && MASlow1 > MAFast1){
      signal   = OP_SELL;
   }
   
   return (signal);
   
}

void openOrder(int orderType){

   if (orderType >= 0){
   
      double hargaOpen = 0.0;
      double lotSize = 0.0;
      lotSize  = getLotSize();
      color warna = clrNONE;
      
      if (orderType == OP_BUY){
         hargaOpen   = Ask;
         warna = clrBlue;
      }else if (orderType == OP_SELL){
         hargaOpen   = Bid;
         warna = clrRed;
      }
   
      int noTiket = OrderSend(NULL, orderType, lotSize, hargaOpen, 0, 0, 0, "belajar code", 0, 0, warna);
      if (noTiket > 0){
         Print ("Order berhasil");
      }else{
         Print ("Order gagal open");
      }
   
   }
   
}

double getLotSize(){
   double lotSize = inLotSize;
   
   //Martingale
   //Deret 
   
   lotSize  = MathRound(lotSize / gLotStep) * gLotStep;
   lotSize  = (lotSize < gMinLot) ? gMinLot : (lotSize > gMaxLot) ? gMaxLot : lotSize;

   lotSize  = NormalizeDouble(lotSize, 2);
   
   return(lotSize);

}

