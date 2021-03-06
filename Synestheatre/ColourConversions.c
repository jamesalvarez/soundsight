//
//  ColourConversions.c
//  CameraColourExplorer
//
// Taken from: https://github.com/gi0rikas/Color-conversions
//

#include "ColourConversions.h"

// http://www.easyrgb.com/index.php?X=MATH&H=02#text2
#include <stdio.h>
#include <math.h>

float ref_X = 95.047;
float ref_Y = 100.0;
float ref_Z = 108.883;


void convertRGBtoLAB(int inR, int inG, int inB, float * outL, float * outa, float * outb) {
    
    float X,Y,Z;
    convertRGBtoXYZ(inR, inG, inB, &X, &Y, &Z);
    convertXYZtoLab(X, Y, Z, outL, outa, outb);
}


void convertRGBtoXYZ(int inR, int inG, int inB, float * outX, float * outY, float * outZ) {
    
    
    float var_R = (inR / 255.0f); //R from 0 to 255
    float var_G = (inG / 255.0f); //G from 0 to 255
    float var_B = (inB / 255.0f); //B from 0 to 255
    
    if (var_R > 0.04045f)
        var_R = powf(( (var_R + 0.055f) / 1.055f), 2.4f);
    else
        var_R = var_R / 12.92f;
    
    if (var_G > 0.04045)
        var_G = powf(( (var_G + 0.055f) / 1.055f), 2.4f);
    else
        var_G = var_G / 12.92f;
    
    if (var_B > 0.04045f)
        var_B = powf(( (var_B + 0.055f) / 1.055f), 2.4f);
    else
        var_B = var_B / 12.92f;
    
    var_R = var_R * 100;
    var_G = var_G * 100;
    var_B = var_B * 100;
    
    //Observer. = 2°, Illuminant = D65
    *outX = var_R * 0.4124f + var_G * 0.3576f + var_B * 0.1805f;
    *outY = var_R * 0.2126f + var_G * 0.7152f + var_B * 0.0722f;
    *outZ = var_R * 0.0193f + var_G * 0.1192f + var_B * 0.9505f;
}

void convertXYZtoLab(float inX, float inY, float inZ, float * outL, float * outa, float * outb) {
    
    float var_X = (inX / ref_X); //ref_X = 95.047
    float var_Y = (inY / ref_Y); //ref_Y = 100.0
    float var_Z = (inZ / ref_Z); //ref_Z = 108.883
    
    if ( var_X > 0.008856 )
        var_X = powf(var_X , ( 1.0f/3 ));
    else
        var_X = ( 7.787 * var_X ) + ( 16.0f/116 );
    
    if ( var_Y > 0.008856 )
        var_Y = powf(var_Y , ( 1.0f/3 ));
    else
        var_Y = ( 7.787 * var_Y ) + ( 16.0f/116 );
    
    if ( var_Z > 0.008856 )
        var_Z = powf(var_Z , ( 1.0f/3 ));
    else
        var_Z = ( 7.787 * var_Z ) + ( 16.0f/116 );
    
    *outL = ( 116 * var_Y ) - 16;
    *outa = 500 * ( var_X - var_Y );
    *outb = 200 * ( var_Y - var_Z );
}

void convertLabtoXYZ( float inL, float ina, float  inb, float * outX, float * outY, float * outZ) {
    
    float var_Y = ( inL + 16 ) / 116;
    float var_X = (ina/500) + var_Y;
    float var_Z = var_Y - (inb/200);
    
    if ( powf(var_Y,3.f) > 0.008856 )
        var_Y = powf(var_Y,3.f);
    else
        var_Y = ( var_Y - (16/116) ) / 7.787;
    
    if ( powf(var_X,3.f) > 0.008856 )
        var_X = powf(var_X,3.f);
    else
        var_X = ( var_X - (16/116) ) / 7.787;
    
    if ( powf(var_Z,3.f) > 0.008856 )
        var_Z = powf(var_Z,3.f);
    else
        var_Z = ( var_Z - (16/116) ) / 7.787;
    
    *outX = ref_X * var_X;     //ref_X =  95.047     Observer= 2°, Illuminant= D65
    *outY = ref_Y * var_Y;     //ref_Y = 100.000
    *outZ = ref_Z * var_Z;     //ref_Z = 108.883
}

void convertXYZtoRGB(float inX, float inY, float inZ, int * outR, int * outG, int * outB) {
    
    
    float var_X = inX/100;
    float var_Y = inY/100;
    float var_Z = inZ/100;
    
    float var_R = var_X *  3.2406 + (var_Y * -1.5372) + var_Z * (-0.4986);
    float var_G = var_X * (-0.9689) + var_Y *  1.8758 + var_Z *  0.0415;
    float var_B = var_X *  0.0557 + var_Y * (-0.2040) + var_Z *  1.0570;
    
    if ( var_R > 0.0031308 )
        var_R = 1.055 * powf(var_R, ( 1.0f / 2.4 ) )  - 0.055;
    else
        var_R = 12.92 * var_R;
    
    if ( var_G > 0.0031308 )
        var_G = 1.055 * powf(var_G, ( 1.0f / 2.4 ) ) - 0.055;
    else
        var_G = 12.92 * var_G;
    
    if ( var_B > 0.0031308 )
        var_B = 1.055 * powf(var_B, ( 1.0f / 2.4 ) ) - 0.055;
    else
        var_B = 12.92 * var_B;
    
    *outR = (int)(var_R * 255);
    *outG = (int)(var_G * 255);
    *outB = (int)(var_B * 255);
    
    
}

void convertLCHtoLAB(float inC, float inH, float* outa, float* outb) {
    *outa = inC * cos(inH);
    *outb = inC * sin(inH);
}

void convertLabtoLCH(float ina, float inb, float* outC, float* outH) {
    *outC = sqrt((ina * ina) + (inb * inb));
    *outH = atan2f(inb, ina);
}

void convertLCHtoRGB(float inL, float inC, float inH, int *outR, int *outG, int *outB) {
    float A,B,X,Y,Z;
    convertLCHtoLAB(inC, inH, &A, &B);
    convertLabtoXYZ(inL, A, B, &X, &Y, &Z);
    convertXYZtoRGB(X,Y,Z,outR, outG, outB);
}

void convertRGBtoLCH(int inR, int inG, int inB, float *outL, float* outC, float* outH) {
    float a,b;
    convertRGBtoLAB(inR, inG, inB, outL, &a, &b);
    convertLabtoLCH(a, b, outC, outH);
}

float Lab_color_difference( float inL1, float ina1, float  inb1, float inL2, float ina2, float  inb2){
    return( sqrt( powf(inL1 - inL2, 2.f) + powf(ina1 - ina2, 2.f) + powf(inb1 - inb2, 2.f) ) );
}

float RGB_color_Lab_difference( int R1, int G1, int B1, int R2, int G2, int B2) {
    float x1=0,y1=0,z1=0;
    float x2=0,y2=0,z2=0;
    float l1=0,a1=0,b1=0;
    float l2=0,a2=0,b2=0;
    
    convertRGBtoXYZ(R1, G1, B1, &x1, &x1, &z1);
    convertRGBtoXYZ(R2, G2, B2, &x2, &x2, &z2);
    
    convertXYZtoLab(x1, y1, z1, &l1, &a1, &b1);
    convertXYZtoLab(x2, y2, z2, &l2, &a2, &b2);
    
    return( Lab_color_difference(l1 ,a1 ,b1 ,l2 ,a2 ,b2) );
}

