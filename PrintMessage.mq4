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

struct PeriodOfTime {
  public:
    int inSeconds;
    int positiveInSeconds;
    int negativeInSeconds;
};

class Order {
  public:
    int               ticketNo;
    string            symbol;
    datetime          openTime;
    datetime          closeTime;
    double            low;
    double            high;
    string            type;
    double            openPrice;
    double            stopLoss;
    double            takeProfit;
    double            closePrice;
    double            lot;
    PeriodOfTime      periodOfTime;

    void setMetadata(int c_ticketNo,
                      string c_symbol,
                      datetime c_openTime,
                      datetime c_closeTime,
                      double c_low,
                      double c_high,
                      string c_type,
                      double c_openPrice,
                      double c_stopLoss,
                      double c_takeProfit,
                      double c_closePrice,
                      double c_lot,
                      PeriodOfTime& c_periodOfTime) {
      ticketNo = c_ticketNo;
      symbol = c_symbol;
      openTime = c_openTime;
      closeTime = c_closeTime;
      low = c_low;
      high = c_high;
      type = c_type;
      openPrice = c_openPrice;
      stopLoss = c_stopLoss;
      takeProfit = c_takeProfit;
      closePrice = c_closePrice;
      lot = c_lot;
      periodOfTime = c_periodOfTime;
    }
};

void OnStart() {
  int numberOfOrders = OrdersHistoryTotal();

  Order orders[];

  ArrayResize(orders, numberOfOrders);
  
  for(int i=0; i < numberOfOrders; i++) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) {
      Print("Access to history failed with error (",GetLastError(),")");
      break;
    }
    
    orders[i].setMetadata(
      OrderTicket(),
      OrderSymbol(),
      OrderOpenTime(),
      OrderCloseTime(),
      calcLow(OrderOpenTime(), OrderCloseTime()),
      calcHigh(OrderOpenTime(), OrderCloseTime()),
      getOrderTypeFrom(OrderType()),
      OrderOpenPrice(),
      OrderStopLoss(),
      OrderTakeProfit(),
      OrderClosePrice(),
      OrderLots(),
      calcPeriod(OrderOpenTime(), OrderCloseTime(), OrderOpenPrice())
    );
  }

  writeToCSVFileArray(numberOfOrders, orders);
}

double calcR(double orderOpenPrice, double orderClosePrice){
  return MathAbs(orderOpenPrice - orderClosePrice);
}

PeriodOfTime calcPeriod(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice) {
  PeriodOfTime periodOfTime;
  periodOfTime.inSeconds = orderCloseTime - orderOpenTime;

  periodOfTime.positiveInSeconds = calcPositivePeriod(orderOpenTime, orderCloseTime, orderOpenPrice);
  periodOfTime.negativeInSeconds = calcNegativePeriod(orderOpenTime, orderCloseTime, orderOpenPrice);

  return periodOfTime;
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

int writeToCSVFileArray(int totalNoOfOrders, Order &orders[]) {
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
      Order order = orders[i];
      FileWrite(handle, 
                order.ticketNo, 
                order.symbol, 
                order.openTime, 
                order.closeTime, 
                order.low, 
                order.high, 
                order.type,
                order.openPrice,
                order.stopLoss,
                order.takeProfit,
                order.closePrice,
                order.lot,
                order.periodOfTime.inSeconds,
                order.periodOfTime.positiveInSeconds,
                order.periodOfTime.negativeInSeconds
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
