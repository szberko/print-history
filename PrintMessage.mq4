//+------------------------------------------------------------------+
//|                                                 PrintMessage.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

struct OrderPeriod {
   int orderPeriodInSeconds;
   int orderPeriodPositiveInSeconds;
   int orderPeriodNegativeInSeconds;
};

void OnStart() {
  int i,hstTotal=OrdersHistoryTotal();

  int ticketNos[];
  string orderSymbols[];
  datetime orderOpenTimes[];
  datetime orderCloseTimes[];
  double lows[];
  double highs[];
  string orderTypes[];
  double orderOpenPrices[];
  double orderStopLosses[];
  double orderTakeProfits[];
  double orderClosePrices[];
  double orderLots[];
  OrderPeriod orderPeriods[];

  ArrayResize(ticketNos, hstTotal);
  ArrayResize(orderSymbols, hstTotal);
  ArrayResize(orderOpenTimes, hstTotal);
  ArrayResize(orderCloseTimes, hstTotal);
  ArrayResize(lows, hstTotal);
  ArrayResize(highs, hstTotal);
  ArrayResize(orderTypes, hstTotal);
  ArrayResize(orderOpenPrices, hstTotal);
  ArrayResize(orderStopLosses, hstTotal);
  ArrayResize(orderTakeProfits, hstTotal);
  ArrayResize(orderClosePrices, hstTotal);
  ArrayResize(orderLots, hstTotal);
  ArrayResize(orderPeriods, hstTotal);
  
  for(i=0; i < hstTotal; i++) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) {
      Print("Access to history failed with error (",GetLastError(),")");
      break;
    }
    
    ticketNos[i] = OrderTicket();
    orderSymbols[i] = OrderSymbol();
    orderOpenTimes[i] = OrderOpenTime();
    orderCloseTimes[i] = OrderCloseTime();
    lows[i] = calcLow(OrderOpenTime(), OrderCloseTime());
    highs[i] = calcHigh(OrderOpenTime(), OrderCloseTime());
    orderTypes[i] = getOrderTypeFrom(OrderType());
    orderOpenPrices[i] = OrderOpenPrice();
    orderStopLosses[i] = OrderStopLoss();
    orderTakeProfits[i] = OrderTakeProfit();
    orderClosePrices[i] = OrderClosePrice();
    orderLots[i] = OrderLots();
    orderPeriods[i] = calcPeriod(orderOpenTimes[i], orderCloseTimes[i], orderOpenPrices[i]);
  }

  writeToCSVFileArray(hstTotal, 
                      ticketNos, 
                      orderSymbols, 
                      orderOpenTimes, 
                      orderCloseTimes, 
                      lows, 
                      highs, 
                      orderTypes,
                      orderOpenPrices,
                      orderStopLosses,
                      orderTakeProfits,
                      orderClosePrices,
                      orderLots,
                      orderPeriods);
}

double calcR(double orderOpenPrice, double orderClosePrice){
  return MathAbs(orderOpenPrice - orderClosePrice);
}

OrderPeriod calcPeriod(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice) {
  OrderPeriod orderPeriod;
  orderPeriod.orderPeriodInSeconds = orderCloseTime - orderOpenTime;

  orderPeriod.orderPeriodPositiveInSeconds = calcPositivePeriod(orderOpenTime, orderCloseTime, orderOpenPrice);
  orderPeriod.orderPeriodNegativeInSeconds = calcNegativePeriod(orderOpenTime, orderCloseTime, orderOpenPrice);

  return orderPeriod;
}

int calcSeconds(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice) {
  return orderCloseTime - orderOpenTime;
}

int calcPositivePeriod(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice){
  datetime positionInTime = orderOpenTime;
  int counter = 0;

  while(positionInTime < orderCloseTime){
    int  iWhenM1 = iBarShift(NULL, PERIOD_M1, positionInTime, true);
    // Calculate just in case if the bar has match
    
    if(iWhenM1 != -1) {
      double hiWhen = iHigh(NULL, PERIOD_M1, iWhenM1);
      // amount of seconds in positive area
      // Print("|| TICKET NO: ", ticketNo, "|| DATETIME: ", positionInTime, " || ORDER OPEN PRICE: ", orderOpenPrice, " || PRICE IN HISTORY: ", hiWhen); 
      if(hiWhen > orderOpenPrice) {
        counter++;
      }
    }
    positionInTime++;
  }
  return counter;
}

int calcNegativePeriod(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice) {
  datetime positionInTime = orderOpenTime;
  int counter = 0;
  while(positionInTime < orderCloseTime){
    int  iWhenM1 = iBarShift(NULL, PERIOD_M1, positionInTime, true);
    // Calculate just in case if the bar has match
    if(iWhenM1 != -1) {
      double hiWhen = iHigh(NULL, PERIOD_M1, iWhenM1);
      // Print("|| TICKET NO: ", ticketNo, "|| DATETIME: ", positionInTime, " || ORDER OPEN PRICE: ", orderOpenPrice, " || PRICE IN HISTORY: ", hiWhen); 
      if(hiWhen < orderOpenPrice) {
        counter++;
      }
    }
    positionInTime++;
  }
  return counter;
}

int writeToCSVFileArray(int totalNoOfOrders,
                    int &ticketNos[],
                    string &orderSymbols[],
                    datetime &orderOpenTimes[],
                    datetime &orderCloseTimes[],
                    double &lows[],
                    double &highs[],
                    string &orderTypes[],
                    double &orderOpenPrices[],
                    double &orderStopLosses[],
                    double &orderTakeProfits[],
                    double &orderClosePrices[],
                    double &orderLots[],
                    OrderPeriod &orderPeriods[]) {
  int handle=FileOpen("dairy_tick.csv", FILE_READ | FILE_WRITE | FILE_CSV, ',');
  if (handle != INVALID_HANDLE){
    Print("write to file");
    FileWrite(handle, 
                "Ticket No.", 
                "Instrument", 
                "Open Time", 
                "Close Time", 
                "Low", 
                "High", 
                "Order Type",
                "Order Open Price",
                "Order Stop Loss",
                "Order Take Profit",
                "Order Close Price",
                "Order Lots",
                "Order Period in Seconds",
                "Order Positive Period in Seconds",
                "Order Negative Period in Seconds");

    for(int i=0; i < totalNoOfOrders; i++) {
      FileWrite(handle, 
                ticketNos[i], 
                orderSymbols[i], 
                orderOpenTimes[i], 
                orderCloseTimes[i], 
                lows[i], 
                highs[i], 
                orderTypes[i],
                orderOpenPrices[i],
                orderStopLosses[i],
                orderTakeProfits[i],
                orderClosePrices[i],
                orderLots[i],
                orderPeriods[i].orderPeriodInSeconds,
                orderPeriods[i].orderPeriodPositiveInSeconds,
                orderPeriods[i].orderPeriodNegativeInSeconds
                );
    }
  
    FileClose(handle);
  } else {
    Alert("Failed to open data file. Please check if you have write priviledge!");
  }
  return(0);
}

void calcLowAndHigh(datetime start, datetime end)
  {
    string   s           = Symbol();
    int      p           = Period();
    datetime t1          = start;
    datetime t2          = end;
    int      t1_shift    = iBarShift(s,p,t1);
    int      t2_shift    = iBarShift(s,p,t2);
    int      bar_count   = t1_shift-t2_shift;
    int      high_shift  = iHighest(s,p,MODE_HIGH,bar_count,t2_shift);
    int      low_shift   = iLowest(s,p,MODE_LOW,bar_count,t2_shift);
    double   high        = iHigh(s,p,high_shift);
    double   low         = iLow(s,p,low_shift);
    Print(t1," -> ",t2,":: High = ",high," Low = ",low);
  }

double calcLow(datetime start, datetime end) {
  string   s           = Symbol();
  int      p           = Period();
  datetime t1          = start;
  datetime t2          = end;
  int      t1_shift    = iBarShift(s,p,t1);
  int      t2_shift    = iBarShift(s,p,t2);
  int      bar_count   = t1_shift-t2_shift;
  int      low_shift   = iLowest(s,p,MODE_LOW,bar_count,t2_shift);
  double   low         = iLow(s,p,low_shift);
  return low;
}

double calcHigh(datetime start, datetime end) {
  string   s           = Symbol();
  int      p           = Period();
  datetime t1          = start;
  datetime t2          = end;
  int      t1_shift    = iBarShift(s,p,t1);
  int      t2_shift    = iBarShift(s,p,t2);
  int      bar_count   = t1_shift-t2_shift;
  int      high_shift  = iHighest(s,p,MODE_HIGH,bar_count,t2_shift);
  double   high        = iHigh(s,p,high_shift);
  return high;
}
//+------------------------------------------------------------------+

string getOrderTypeFrom(int orderType) {
  switch(orderType) {
    case(0):
      return "BUY";
      break;
    case(1):
      return "SELL";
      break;
    case(2):
      return "BUY_LIMIT";
      break;
    case(3):
      return "SELL_LIMIT";
      break;
    case(4):
      return "BUY_STOP";
      break;
    case(5):
      return "SELL_STOP";
      break;
    default:
      return "";
  }
}
