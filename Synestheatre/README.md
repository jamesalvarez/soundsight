#  Guide to various features



## Heartbeat Interval
Rate in seconds of sound pulses

## Depth Data Window
Height and width of subwindow to take depth data (0.05-1).  Allows user to focus on detail at center.

## Focus
Focus on centre sounds 1 = play all sounds in the row/col
0 = just the centre pixel

## Timing Offset
Timing offsets 0 - 1.  When timing offset is 0, all sounds are played similataneously with the heartbeat.  When it is 1, the sounds are spread out over the access.

## Depth mode
In depth mode, further away sounds are played later than closer ones.  In normal mode just the timing offsets are applied.

## Depth Range
Range of of depth in mm. 50 - 10000.  This affects sound volume, and timing offset when in depth mode.
