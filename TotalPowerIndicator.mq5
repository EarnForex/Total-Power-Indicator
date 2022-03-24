//+------------------------------------------------------------------+
//|                                          TotalPowerIndicator.mq5 |
//|                             Copyright © 2011-2022, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//|                Based on indicator by Daniel "Asirikuy" Fernandez |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011-2022, www.EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/TotalPowerIndicator/"
#property version   "1.01"

#property description "Displays the concentration of bull power periods, bear power periods, and total periods when either bulls or bears had prevalence."
#property description "Supports two events for alerts:"
#property description "1. Bull/Bear Power == 100, which is a strong reversal signal."
#property description "2. Bull/Bear Crossover, which is a strong trend signal."

#property indicator_separate_window
#property indicator_minimum -10
#property indicator_maximum 110
#property indicator_level1 0
#property indicator_level2 50
#property indicator_level3 100
#property indicator_buffers 3
#property indicator_plots   3
#property indicator_color1 clrLightSeaGreen
#property indicator_type1  DRAW_LINE
#property indicator_width1 2
#property indicator_label1 "Total Power"
#property indicator_color2 clrCrimson
#property indicator_type2  DRAW_LINE
#property indicator_width2 2
#property indicator_label2 "Bear Power"
#property indicator_color3 clrDarkGreen
#property indicator_type3  DRAW_LINE
#property indicator_width3 2
#property indicator_label3 "Bull Power"

enum enum_candle_to_check
{
    Current,
    Previous
};

input int Lookback_Period = 45; // Lookback Period
input int Power_Period = 10; // Power Period
input bool AlertOn100Power    = false; // Alert on 100 Power
input bool AlertOnCrossover   = false; // Alert on Crossover
input bool EnableNativeAlerts = false;
input bool EnableEmailAlerts  = false;
input bool EnablePushAlerts   = false;
input enum_candle_to_check TriggerCandle = Previous;

double Power[];
double Bears[];
double Bulls[];

// Buffers for CopyBuffer of the standard indicators
double BearB[], BullB[];

// Global variables
int myBear, myBull;
datetime LastAlertTime = D'01.01.1970';

void OnInit()
{
    SetIndexBuffer(0, Power, INDICATOR_DATA);
    SetIndexBuffer(1, Bears, INDICATOR_DATA);
    SetIndexBuffer(2, Bulls, INDICATOR_DATA);

    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, Power_Period + Lookback_Period);
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, Power_Period + Lookback_Period);
    PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, Power_Period + Lookback_Period);
    
    IndicatorSetInteger(INDICATOR_DIGITS, 2);
    IndicatorSetString(INDICATOR_SHORTNAME, "TPI (" + IntegerToString(Lookback_Period) + ", " + IntegerToString(Power_Period) + ")");

    myBear = iBearsPower(NULL, 0, Power_Period);
    myBull = iBullsPower(NULL, 0, Power_Period);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tickvolume[],
                const long &volume[],
                const int &spread[])
{
    int counted_bars = prev_calculated;

    if (rates_total < Power_Period + Lookback_Period) return 0;

    int limit = counted_bars;
    if (limit < Power_Period + Lookback_Period) limit = Power_Period + Lookback_Period;

    for (int i = limit; i < rates_total; i++)
    {
        int bearcount = 0;
        int bullcount = 0;

        if (CopyBuffer(myBear, 0, rates_total - i - 1, Lookback_Period, BearB) != Lookback_Period) return 0;
        if (CopyBuffer(myBull, 0, rates_total - i - 1, Lookback_Period, BullB) != Lookback_Period) return 0;

        for (int j = Lookback_Period - 1; j >= 0; j--)
        {
            if (BearB[j] < 0) bearcount++;
            if (BullB[j] > 0) bullcount++;
        }

        Power[i] = MathAbs(bullcount - bearcount) * 100 / Lookback_Period;
        Bears[i] = bearcount * 100 / Lookback_Period;
        Bulls[i] = bullcount * 100 / Lookback_Period;
    }

    // Alerts
    if (((TriggerCandle > 0) && (Time[rates_total - 1] > LastAlertTime)) || (TriggerCandle == 0))
    {
        string Text;
        if (AlertOn100Power)
        {
            // 100 Bull Power.
            if ((Bulls[rates_total - 1 - TriggerCandle] == 100) && (Bulls[TriggerCandle + 1] < 100))
            {
                Text = "TPI: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - Bull Power = 100!";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("TPI Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
                LastAlertTime = Time[rates_total - 1];
            }
            // 100 Bear Power
            if ((Bears[rates_total - 1 - TriggerCandle] == 100) && (Bears[TriggerCandle + 1] < 100))
            {
                Text = "TPI: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - Bear Power = 100!";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("TPI Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
                LastAlertTime = Time[rates_total - 1];
            }
        }
        if (AlertOnCrossover)
        {
            // Bull > Bear.
            if ((Bulls[rates_total - 1 - TriggerCandle] > Bears[rates_total - 1 - TriggerCandle]) && (Bulls[rates_total - 2 - TriggerCandle] <= Bears[rates_total - 2 - TriggerCandle]))
            {
                Text = "TPI: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - Bull Power is now greater than Bear Power.";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("TPI Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
                LastAlertTime = Time[rates_total - 1];
            }
            // Bear > Bull.
            if ((Bulls[rates_total - 1 - TriggerCandle] < Bears[rates_total - 1 - TriggerCandle]) && (Bulls[rates_total - 2 - TriggerCandle] >= Bears[rates_total - 2 - TriggerCandle]))
            {
                Text = "TPI: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - Bear Power is now greater than Bull Power.";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("TPI Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
                LastAlertTime = Time[rates_total - 1];
            }
        }
    }

    return rates_total;
}
//+------------------------------------------------------------------+