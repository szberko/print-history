void OnStart()
{
   string   s           = Symbol();
   int      p           = Period();
   datetime t1          = D'2020.01.01';
   datetime t2          = D'2020.01.10';
   int      t1_shift    = iBarShift(s,p,t1);
   int      t2_shift    = iBarShift(s,p,t2);
   int      bar_count   = t1_shift-t2_shift;
   int      high_shift  = iHighest(s,p,MODE_HIGH,bar_count,t2_shift);
   int      low_shift   = iLowest(s,p,MODE_LOW,bar_count,t2_shift);
   double   high        = iHigh(s,p,high_shift);
   double   low         = iLow(s,p,low_shift);
   Print(t1," -> ",t2,":: High = ",high," Low = ",low);
}

2020.01.16 20:29:39.221	lowest EURUSD.lmx,M1: 1577836800 -> 1578614400:: High = 1.1224 Low = 1.1094
