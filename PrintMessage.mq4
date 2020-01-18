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
  writeHeaderToCSVFile();
  int i,hstTotal=OrdersHistoryTotal();

  int ticketNos[];
  string orderSymbols[];
  datetime orderOpenTimes[];
  datetime orderCloseTimes[];
  double lows[];
  double highs[];
  int orderTypes[];
  
  for(i=0;i<hstTotal;i++) {
    if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
      {
      Print("Access to history failed with error (",GetLastError(),")");
      break;
      }
    
    int ticketNo = OrderTicket();
    string orderSymbol = OrderSymbol();
    datetime orderOpenTime = OrderOpenTime();
    datetime orderCloseTime = OrderCloseTime();
    double low = calcLow(OrderOpenTime(), OrderCloseTime());
    double high = calcHigh(OrderOpenTime(), OrderCloseTime());
    int orderType = OrderType();

    Print("Ticket NO: ", ticketNo, " :: ", orderOpenTime," -> ", orderCloseTime, ":: High = ", high, " Low = ", low);
    writeToCSVFile(ticketNo, orderSymbol, orderOpenTime, orderCloseTime, low, high, orderType);
  }
}

int writeToCSVFile(int ticketNo,
                    string orderSymbol,
                    datetime orderOpenTime,
                    datetime orderCloseTime,
                    double low,
                    double high,
                    int orderType) {
  int handle=FileOpen("dairy_tick.csv", FILE_CSV|FILE_WRITE, ',');
  if (handle != INVALID_HANDLE){
    FileWrite(handle, ticketNo, orderSymbol, orderOpenTime, orderCloseTime, low, high, orderType);
    Print("YEEEY we wrote DATA to file");
    FileClose(handle);
  } else {
    Alert("Failed to open data file. Please check if you have write priviledge!");
  }
  return(0);
}

void writeHeaderToCSVFile() {
  int handle=FileOpen("dairy_tick.csv", FILE_CSV|FILE_WRITE, ',');
  Print("WRITE TO FILE. HANDLER = " + handle);
  if (handle != INVALID_HANDLE){
    FileWrite(handle, "Ticket No.", "Instrument", "Open Time", "Close Time", "Low", "High", "Order Type");
    Print("YEEEY we wrote to file");
    FileClose(handle);
  } else {
    Alert("Failed to open data file. Please check if you have write priviledge!");
  }
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

