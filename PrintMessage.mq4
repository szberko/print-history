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
//| Calsses and structure definitions                                |
//+------------------------------------------------------------------+
const int INVALID_VALUE = -1;
const int INVALID_R_VALUE = -1000;

struct TimeAndRStatistics {
  public:
    int seconds;
    double r;
    double price;
};

struct PeriodOfTime {
  public:
    int allInSeconds;
    int positiveInSeconds;
    int negativeInSeconds;
    double positiveInPercent;
    double negativeInPercent;
    double maxPositiveR;
    double maxNegativeR;
    double maxPositivePrice;
    double maxNegativePrice;
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
    double            rValue;
    double            reachedR;
    PeriodOfTime      periodOfTime;
    double            netProfit;
    double            balance;

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
                      double c_rValue,
                      double c_reachedR,
                      PeriodOfTime& c_periodOfTime,
                      double c_netProfit,
                      double c_balance) {
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
      rValue = c_rValue;
      reachedR = c_reachedR;
      periodOfTime = c_periodOfTime;
      netProfit = c_netProfit;
      balance = c_balance;
    }
};

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

void OnStart() {
  int numberOfCompletedOrders = OrdersHistoryTotal();
  int numberOfActiveOrders = OrdersTotal();
  int numberOfAllOrders = numberOfCompletedOrders + numberOfActiveOrders;

  Order orders[];

  ArrayResize(orders, numberOfAllOrders);
  double currentBalance = 0;
  for(int i=0; i < numberOfCompletedOrders; i++) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) {
      Print("Access to history failed with error (", GetLastError(), ")");
      break;
    }

    writeOrderMetadata(currentBalance, orders[i]);
  }

  for(int i=0; i < numberOfActiveOrders; i++) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) {
      Print("Access to actual orders failed with error (", GetLastError(), ")");
      break;
    }
    writeOrderMetadata(currentBalance, orders[i + numberOfCompletedOrders]);
  }

  writeToCSVFileArray(numberOfAllOrders, orders);
}

void writeOrderMetadata(double &currentBalance, Order &order) {
  double rValue = calcRValue(OrderOpenPrice(), OrderStopLoss());
  currentBalance = currentBalance + OrderSwap() + OrderCommission() + OrderProfit();

  order.setMetadata(
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
    rValue,
    calcReachedR(OrderOpenPrice(), OrderClosePrice(), rValue, OrderType()),
    calcPeriod(OrderOpenTime(), OrderCloseTime(), OrderOpenPrice(), OrderType(), rValue),
    OrderProfit(),
    currentBalance
  );
}

//+------------------------------------------------------------------+
//| Write to file algorithm                                          |
//+------------------------------------------------------------------+
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
                "Value of R",
                "Reached R",
                "Order Period in Seconds",
                "Order Max Positive Price",
                "Order Max Positive R",
                "Order Positive Period in Percent",
                "Order Positive Period in Seconds",
                "Order Max Price",
                "Order Max Negative R",
                "Order Negative Period in Percent",
                "Order Negative Period in Seconds",
                "Net Profit",
                "Balance");

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
                order.rValue,
                order.reachedR,
                order.periodOfTime.allInSeconds,
                order.periodOfTime.maxPositivePrice,
                order.periodOfTime.maxPositiveR,
                order.periodOfTime.positiveInPercent,
                order.periodOfTime.positiveInSeconds,
                order.periodOfTime.maxNegativePrice,
                order.periodOfTime.maxNegativeR,
                order.periodOfTime.negativeInPercent,
                order.periodOfTime.negativeInSeconds,
                order.netProfit,
                order.balance
                );
    }
  
    FileClose(handle);
  } else {
    Alert("Failed to open data file. Please check if you have write priviledge!");
  }
  return(0);
}

double calcRValue(double orderOpenPrice, double stopLoss){
  return MathAbs(orderOpenPrice - stopLoss);
}

double calcReachedR(double orderOpenPrice, double orderClosePrice, double rValue, int orderType) {
  if(isBuyOrder(orderType) && rValue > 0) {
    return (orderClosePrice - orderOpenPrice) / rValue;
  }

  if(isSellOrder(orderType) && rValue > 0){
    return (orderOpenPrice - orderClosePrice) / rValue;
  }

  return INVALID_R_VALUE;
}

bool isBuyOrder(int orderType) {
  return orderType == 0 || orderType == 2 || orderType == 4;
}

bool isSellOrder(int orderType) {
  return orderType == 1 || orderType == 3 || orderType == 5;
}

//+------------------------------------------------------------------+
//| Calculate time periods                                           |
//+------------------------------------------------------------------+
PeriodOfTime calcPeriod(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice, int orderType, double orderRValue) {
  PeriodOfTime periodOfTime;
  periodOfTime.allInSeconds = orderCloseTime - orderOpenTime;

  TimeAndRStatistics statisticsAboveOpenPrice = calcSecondsAboveOpenPrice(orderOpenTime, orderCloseTime, orderOpenPrice, orderRValue);
  TimeAndRStatistics statisticsBelowOpenPrice = calcSecondsBelowOpenPrice(orderOpenTime, orderCloseTime, orderOpenPrice, orderRValue);

  

  // BUY
  if(isBuyOrder(orderType)){
    periodOfTime.maxPositivePrice = statisticsAboveOpenPrice.price;
    periodOfTime.maxNegativePrice = statisticsBelowOpenPrice.price;

    periodOfTime.positiveInSeconds = statisticsAboveOpenPrice.seconds;
    periodOfTime.negativeInSeconds = statisticsBelowOpenPrice.seconds;

    periodOfTime.maxPositiveR = statisticsAboveOpenPrice.r;
    periodOfTime.maxNegativeR = statisticsBelowOpenPrice.r;
  }

  // SELL
  if(isSellOrder(orderType)){
    periodOfTime.maxPositivePrice = statisticsBelowOpenPrice.price;
    periodOfTime.maxNegativePrice = statisticsAboveOpenPrice.price;

    periodOfTime.positiveInSeconds = statisticsBelowOpenPrice.seconds;
    periodOfTime.negativeInSeconds = statisticsAboveOpenPrice.seconds;

    periodOfTime.maxPositiveR = statisticsBelowOpenPrice.r;
    periodOfTime.maxNegativeR = statisticsAboveOpenPrice.r;
  }

  if (periodOfTime.allInSeconds > 0) {
    periodOfTime.positiveInPercent = ((double) periodOfTime.positiveInSeconds / (double) periodOfTime.allInSeconds) * 100;
    periodOfTime.negativeInPercent = ((double) periodOfTime.negativeInSeconds / (double) periodOfTime.allInSeconds) * 100;
  } else {
    periodOfTime.positiveInPercent = INVALID_VALUE;
    periodOfTime.negativeInPercent = INVALID_VALUE;
  }

  return periodOfTime;
}

int calcSeconds(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice) {
  return orderCloseTime - orderOpenTime;
}

TimeAndRStatistics calcSecondsAboveOpenPrice(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice, double orderRValue) {
  datetime positionInTime = orderOpenTime;
  int seconds = 0;
  double highestPrice = orderOpenPrice;
  
  while(positionInTime < orderCloseTime){
    int  iWhenM1 = iBarShift(NULL, PERIOD_M1, positionInTime, true);
    // Calculate just in case if the bar has match
    if(iWhenM1 != -1) {
      double candleClosePrice = iClose(NULL, PERIOD_M1, iWhenM1);
      double candleHighestPrice = iHigh(NULL, PERIOD_M1, iWhenM1);
      // amount of seconds above open price area
      if(candleClosePrice > orderOpenPrice) {
        seconds++;
      }

      if(candleHighestPrice > highestPrice){
        highestPrice = candleHighestPrice;
      }
    }
    positionInTime++;
  }
  
  TimeAndRStatistics timeAndRStatistics;
  timeAndRStatistics.seconds = seconds;
  timeAndRStatistics.price = highestPrice;
  if (orderRValue > 0) {
    timeAndRStatistics.r = (highestPrice - orderOpenPrice) / orderRValue;
  } else {
    timeAndRStatistics.r = INVALID_VALUE;
  }
  return timeAndRStatistics;
}

TimeAndRStatistics calcSecondsBelowOpenPrice(datetime orderOpenTime, datetime orderCloseTime, double orderOpenPrice, double orderRValue) {
  datetime positionInTime = orderOpenTime;

  int seconds = 0;
  double lowestPrice = orderOpenPrice;

  while(positionInTime < orderCloseTime){
    int  iWhenM1 = iBarShift(NULL, PERIOD_M1, positionInTime, true);
    // Calculate just in case if the bar has match
    if(iWhenM1 != -1) {
      double candleClosePrice = iClose(NULL, PERIOD_M1, iWhenM1);
      double candleLowestPrice = iLow(NULL, PERIOD_M1, iWhenM1);
      // amount of seconds below open price area
      if(candleClosePrice <= orderOpenPrice) {
        seconds++;
      }
      
      if(candleLowestPrice < lowestPrice) {
        lowestPrice = candleLowestPrice;
      }
    }
    positionInTime++;
  }

  TimeAndRStatistics timeAndRStatistics;
  timeAndRStatistics.seconds = seconds;
  timeAndRStatistics.price = lowestPrice;
  if (orderRValue > 0) {
    timeAndRStatistics.r = (orderOpenPrice - lowestPrice) / orderRValue;
  } else {
    timeAndRStatistics.r = INVALID_VALUE;
  }
  return timeAndRStatistics;
}

//+------------------------------------------------------------------+
//| Calculate lowest and highest value                               |
//+------------------------------------------------------------------+
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
