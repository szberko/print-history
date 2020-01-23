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
void OnStart() {
  int i,hstTotal=OrdersHistoryTotal();

  int ticketNos[];
  string orderSymbols[];
  datetime orderOpenTimes[];
  datetime orderCloseTimes[];
  double lows[];
  double highs[];
  int orderTypes[];

  ArrayResize(ticketNos, hstTotal);
  ArrayResize(orderSymbols, hstTotal);
  ArrayResize(orderOpenTimes, hstTotal);
  ArrayResize(orderCloseTimes, hstTotal);
  ArrayResize(lows, hstTotal);
  ArrayResize(highs, hstTotal);
  ArrayResize(orderTypes, hstTotal);
  
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
    orderTypes[i] = OrderType();
  }

  writeToCSVFileArray(hstTotal, ticketNos, orderSymbols, orderOpenTimes, orderCloseTimes, lows, highs, orderTypes);
}

int writeToCSVFileArray(int totalNoOfOrders,
                    int &ticketNos[],
                    string &orderSymbols[],
                    datetime &orderOpenTimes[],
                    datetime &orderCloseTimes[],
                    double &lows[],
                    double &highs[],
                    int &orderTypes[]) {
  int handle=FileOpen("dairy_tick.csv", FILE_READ | FILE_WRITE | FILE_CSV, ',');
  if (handle != INVALID_HANDLE){
    Print("write to file");
    FileWrite(handle, "Ticket No.", "Instrument", "Open Time", "Close Time", "Low", "High", "Order Type");

    for(int i=0; i < totalNoOfOrders; i++) {
      FileWrite(handle, ticketNos[i], orderSymbols[i], orderOpenTimes[i], orderCloseTimes[i], lows[i], highs[i], orderTypes[i]);
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

