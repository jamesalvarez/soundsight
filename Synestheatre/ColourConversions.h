//
//  ColourConversions.h
//  CameraColourExplorer
//
//  Created by James on 10/08/2017.
//  Copyright © 2017 James. All rights reserved.
//

#ifndef ColourConversions_h
#define ColourConversions_h

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

#include <stdio.h>

EXTERNC void convertRGBtoLAB(int inR, int inG, int inB, float* outL, float* outa, float* outb);

EXTERNC void convertRGBtoXYZ(int inR, int inG, int inB, float* outX, float* outY, float* outZ);

EXTERNC void convertXYZtoLab(float inX, float inY, float inZ, float* outL, float* outa, float* outb);

EXTERNC void convertLabtoXYZ(float inL, float ina, float inb, float* outX, float* outY, float* outZ);

EXTERNC void convertXYZtoRGB(float inX, float inY, float inZ, int* outR, int* outG, int* outB);

EXTERNC void convertLabtoLCH(float ina, float inb, float* outC, float* outH);

EXTERNC void convertRGBtoLCH(int inR, int inG, int inB, float *outL, float* outC, float* outH);

EXTERNC float Lab_color_difference(float inL1, float ina1, float inb1, float inL2, float ina2, float inb2);

EXTERNC float RGB_color_Lab_difference(int R1, int G1, int B1, int R2, int G2, int B2);

EXTERNC void convertLCHtoRGB(float inL, float inC, float inH, int *outR, int *outG, int *outB);


#endif /* ColourConversions_h */
