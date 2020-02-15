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

class Trade {
  public:
    int       ticketNo;
    string    orderSymbol;
    datetime  orderOpenTime;
    datetime  orderCloseTime;
    double    low;
    double    high;
    string    orderType;
    double    orderOpenPrice;
    double    orderStopLosse;
    double    orderTakeProfit;
    double    orderClosePrice;
    double    orderLot;
    OrderPeriod       orderPeriod;
};

void OnStart() {
  int i,hstTotal = OrdersHistoryTotal();

  Trade trades[];

  ArrayResize(trades, hstTotal);
  
  for(i=0; i < hstTotal; i++) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) {
      Print("Access to history failed with error (",GetLastError(),")");
      break;
    }
    
    
    trades[i].ticketNo = OrderTicket();
    trades[i].orderSymbol = OrderSymbol();
    trades[i].orderOpenTime = OrderOpenTime();
    trades[i].orderCloseTime = OrderCloseTime();
    trades[i].low = calcLow(OrderOpenTime(), OrderCloseTime());
    trades[i].high = calcHigh(OrderOpenTime(), OrderCloseTime());
    trades[i].orderType = getOrderTypeFrom(OrderType());
    trades[i].orderOpenPrice = OrderOpenPrice();
    trades[i].orderStopLosse = OrderStopLoss();
    trades[i].orderTakeProfit = OrderTakeProfit();
    trades[i].orderClosePrice = OrderClosePrice();
    trades[i].orderLot = OrderLots();
    trades[i].orderPeriod = calcPeriod(trades[i].orderOpenTime, trades[i].orderCloseTime, trades[i].orderOpenPrice);
  }

  writeToCSVFileArray(hstTotal, trades);
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

int writeToCSVFileArray(int totalNoOfOrders, Trade &trades[]) {
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
                trades[i].ticketNo, 
                trades[i].orderSymbol, 
                trades[i].orderOpenTime, 
                trades[i].orderCloseTime, 
                trades[i].low, 
                trades[i].high, 
                trades[i].orderType,
                trades[i].orderOpenPrice,
                trades[i].orderStopLosse,
                trades[i].orderTakeProfit,
                trades[i].orderClosePrice,
                trades[i].orderLot,
                trades[i].orderPeriod.orderPeriodInSeconds,
                trades[i].orderPeriod.orderPeriodPositiveInSeconds,
                trades[i].orderPeriod.orderPeriodNegativeInSeconds
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
