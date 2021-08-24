//
//  DepthSensor.m
//  Synestheatre
//
//  Created by James on 25/07/2018.
//  Copyright © 2018 James. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#ifndef _INCL_GUARD_COLOUR
#define _INCL_GUARD_COLOUR

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )

typedef struct Colour {
    UInt32 r;
    UInt32 g;
    UInt32 b;
} Colour;

NS_INLINE Colour ConvertUint32(UInt32 input) {
    Colour c = { R(input), G(input), B(input)};
    return c;
}

static const Colour ColourBlack = {0,0,0};
#endif

@protocol DepthSensor

/**
 *  Callback to take user readable status messages
 */
@property (nonatomic, copy) void (^updateStatusBlock)(NSString*);

/*
 * Callback when new data is available
 */
@property (nonatomic, copy) void (^newDataBlock)(void);

/**
 *  Starts the structure sensor
 */
-(void)startDepthSensor;


/**
 *  Stops the structure sensor
 */
-(void)stopDepthSensor;


/**
 *  Coloured UIImage of depth data from the sensor
 *
 *  @return UIImage
 */
-(UIImage*)getSensorImage;

/*
 **  @param rows        number of rows
 *  @param cols        number of columns
 *  @param heightScale height of sub window within (1.0 for full height)
 *  @param widthScale  width of sub window within (1.0 for full width)
 */
-(void)setViewWindowWithRows:(int)rows cols:(int)cols heightScale:(float)heightScale widthScale:(float)widthScale;

/**
 *  Get an array of floats of depth for each row/col, spaced out evenly across the full array - or within sub window.
 *  Using nearest neighbor resampling.
 *  @param outArray    depths in mm
 */
-(bool)getDepthInMillimeters:(float*)outArray;

/**
 *  Get an array of colors for each row/col, spaced out evenly across the full array - or within sub window.
 *  Using nearest neighbor resampling.
 *  @param outArray    colors
 */
-(bool)getColours:(Colour*)outArray;

/**
 *  Coloured UIImage of colour data
 *
 *  @return UIImage
 */
-(UIImage*)getColourImage;

-(NSString*) getCentreDebugInfo;

-(NSString*) getSensorType;

-(bool) isSensorConnected;
-(NSString*) sensorDisconnectionReason;

@end
