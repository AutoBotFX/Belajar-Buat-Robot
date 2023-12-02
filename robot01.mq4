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
input    double      inLotX      = 2.0;      //Multiplier

input    int         inTakeProfit   = 10;       //Take Profit (pips)
input    int         inStopLoss     = 0;        //Stop Loss (pips);

input    bool        inIsTrailingStop  = true;  //Is Trailing Stop
input    int         inTrailingStart   = 5;     //Trailing Start
input    int         inTrailingStep    = 1;     //Trailing Step

input    int         inMAFastPeriod = 10;       //MA Fast Period
input    int         inMASlowPeriod = 30;       //MA Slow Period
input    ENUM_MA_METHOD inMAMethod  = MODE_SMA; //MA Method
input    ENUM_APPLIED_PRICE inMAPrice  = PRICE_CLOSE;  //MA Applied to

input    bool        inIsAveraging     = true;        //Is Averaging
input    int         inJarakAveraging  = 10;          //Jarak Averaging (pips)
input    int         inMaxOrders       = 10;          //Max Orders

double gMinLot, gMaxLot, gLotStep;
string   gPair;
int      gDigit;
double   gPoint;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//-----------
   gPair = Symbol();
   gDigit   = (int) MarketInfo(gPair, MODE_DIGITS);
   gPoint   = MarketInfo(gPair, MODE_POINT);
   if (gDigit % 2 == 1 ) gPoint *= 10;
   
   gMinLot  = MarketInfo(gPair, MODE_MINLOT);
   gMaxLot  = MarketInfo(gPair, MODE_MAXLOT);
   gLotStep = MarketInfo(gPair, MODE_LOTSTEP);
   
   
   
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
   
   transaksi(orderType);
   
   updateTPSL();
   
  }
//+------------------------------------------------------------------+

void transaksi(int orderType){

   int tOrderBuy = 0, tOrderSell = 0;
   double hargaBuyTerBawah = 0.0, hargaSellTerAtas = 0.0;
   
   int tOrders = OrdersTotal();
   for (int i=tOrders-1; i>=0; i--){
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) ){
         if (OrderSymbol() == gPair){
            if (OrderType() == OP_BUY){
               tOrderBuy++;
               if (OrderOpenPrice() < hargaBuyTerBawah || hargaBuyTerBawah == 0.0){
                  hargaBuyTerBawah = OrderOpenPrice();
               }
            }else if (OrderType() == OP_SELL){
               tOrderSell++;
               if (OrderOpenPrice() > hargaSellTerAtas){
                  hargaSellTerAtas = OrderOpenPrice();
               }
            }
         }
      } 
   
   }
   
   double lotSize = 0.0;
   
   if (orderType >= 0){
      if ( (tOrderBuy == 0 && orderType == OP_BUY) || (tOrderSell == 0 && orderType == OP_SELL) ){
         lotSize  = getLotSize(0);
         openOrder(orderType, lotSize);
      }
   }
   
   
   if (inIsAveraging==true){
      if (tOrderBuy > 0 && tOrderBuy < inMaxOrders && hargaBuyTerBawah - (inJarakAveraging * gPoint) >= Ask){
         lotSize  = getLotSize(tOrderBuy);
         openOrder(OP_BUY, lotSize);
         
      }else if (tOrderSell > 0 && tOrderSell < inMaxOrders && hargaSellTerAtas + (inJarakAveraging * gPoint) <= Bid){
         lotSize  = getLotSize(tOrderSell);
         openOrder(OP_SELL, lotSize);
      }
   
   
   }
   
   

}

void updateTPSL(){

   int tOrderBuy = 0, tOrderSell = 0;
   double tValBuy = 0.0, tValSell = 0.0;
   double tLotBuy = 0.0, tLotSell = 0.0;
   
   int tOrders = OrdersTotal();
   for (int i=tOrders-1; i>=0; i--){
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) ){
         if (OrderSymbol() == gPair){
            if (OrderType() == OP_BUY){
               tOrderBuy++;
               tValBuy  += OrderOpenPrice() * OrderLots();
               tLotBuy  += OrderLots();
               
            }else if (OrderType() == OP_SELL){
               tOrderSell++;
               
               tValSell += OrderOpenPrice() * OrderLots();
               tLotSell += OrderLots();
            }
         }
      } 
   
   }
   
   double hargaBEPBuy   = 0.0, hargaBEPSell = 0.0;
   
   if (tOrderBuy > 0){
      hargaBEPBuy = tValBuy / tLotBuy;
   }
   if (tOrderSell > 0){
      hargaBEPSell = tValSell / tLotSell;
   }
   
   double tpBuy = 0.0, tpSell = 0.0;
   double slBuy = 0.0, slSell = 0.0;
   
   tpBuy = (inTakeProfit>0) ? hargaBEPBuy + (inTakeProfit * gPoint) : 0.0;
   tpSell = (inTakeProfit>0) ? hargaBEPSell - (inTakeProfit * gPoint) : 0.0;
   
   if (inIsAveraging == false){
      slBuy = (inStopLoss>0) ? hargaBEPBuy - (inStopLoss * gPoint) : 0.0;
      slSell = (inStopLoss>0) ? hargaBEPSell + (inStopLoss * gPoint) : 0.0;
   }
   
   
   
   tOrders = OrdersTotal();
   for (int i=tOrders-1; i>=0; i--){
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) ){
         if (OrderSymbol() == gPair){
            if (OrderType() == OP_BUY){
            
               if (inIsTrailingStop==true && Bid-(inTrailingStart*gPoint) >= hargaBEPBuy && Bid - ( (inTrailingStart+inTrailingStep) * gPoint) >= OrderStopLoss() ){
                  slBuy = Bid - (inTrailingStart * gPoint);
               }else{
                  slBuy = (inStopLoss > 0) ? hargaBEPBuy - (inStopLoss * gPoint) : OrderStopLoss();
                  slBuy = (OrderStopLoss() < hargaBEPBuy) ? slBuy : OrderStopLoss();
               }
            
               if ( ! OrderModify(OrderTicket(), OrderOpenPrice(), slBuy, tpBuy, 0, clrBlue)){
                  Print ("WARNING: Update TP/SL BUY tidak berhasil");
               }
               
               
            }else if (OrderType() == OP_SELL){
               
               if (inIsTrailingStop==true && Ask+(inTrailingStart*gPoint) <= hargaBEPBuy && (Ask + ( (inTrailingStart+inTrailingStep) * gPoint) <= OrderStopLoss() || OrderStopLoss() == 0) ){
                  slSell = Ask + (inTrailingStart * gPoint);
               }else{
                  slSell = (inStopLoss > 0) ? hargaBEPSell + (inStopLoss * gPoint) : OrderStopLoss();
                  slSell = (OrderStopLoss() > hargaBEPSell) ? slSell : OrderStopLoss();
               }
            
               if ( ! OrderModify(OrderTicket(), OrderOpenPrice(), slSell, tpSell, 0, clrRed)){
                  Print ("WARNING: Update TP/SL SELL tidak berhasil");
               }
               
            }
         }
      } 
   }
   
   
}


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
   
   double MAFast2 = iMA(gPair, 0, inMAFastPeriod, 0, inMAMethod, inMAPrice, 2);
   double MAFast1 = iMA(gPair, 0, inMAFastPeriod, 0, inMAMethod, inMAPrice, 1);
   
   double MASlow2 = iMA(gPair, 0, inMASlowPeriod, 0, inMAMethod, inMAPrice, 2);
   double MASlow1 = iMA(gPair, 0, inMASlowPeriod, 0, inMAMethod, inMAPrice, 1);
   
   if (MASlow2 > MAFast2 && MASlow1 < MAFast1){
      signal   = OP_BUY;
   }else if (MASlow2 < MAFast2 && MASlow1 > MAFast1){
      signal   = OP_SELL;
   }
   
   return (signal);
   
}

void openOrder(int orderType, double lotSize){

   if (orderType >= 0){
   
      double hargaOpen = 0.0;
      
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

double getLotSize(int tOrder){
   double lotSize = inLotSize;
   
   
   lotSize  = inLotSize * MathPow(inLotX, tOrder);
   
   lotSize  = MathRound(lotSize / gLotStep) * gLotStep;
   lotSize  = (lotSize < gMinLot) ? gMinLot : (lotSize > gMaxLot) ? gMaxLot : lotSize;

   lotSize  = NormalizeDouble(lotSize, 2);
   
   return(lotSize);

}

