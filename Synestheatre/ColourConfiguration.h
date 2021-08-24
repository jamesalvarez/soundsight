//
//  ColourConfiguration.h
//  Synestheatre
//
//  Created by James on 08/11/2018.
//  Copyright © 2018 James. All rights reserved.
//

#ifndef ColourConfiguration_h
#define ColourConfiguration_h

#define MAX_LIGHTNESS_THRESHOLDS 10
#define MAX_HUE_THRESHOLDS 10
#define MAX_COLOURS 20

struct ColourConfiguration {
    
    // Legacy: B&W mode - keeping this seperate for now
    bool bw_mode;
    float bw_level;
    
    
    // Full colour mode boundary and normal modes
    bool boundary_mode;
    float saturation_threshold;
    float lightness_thresholds[MAX_LIGHTNESS_THRESHOLDS]; //im just fixing these instead of messing with dynamic arrays
    float hue_thresholds[MAX_HUE_THRESHOLDS];
    int n_lightness_thresholds;
    int n_hue_thresholds;
    float colour_timings[MAX_COLOURS];
    
};

typedef struct ColourConfiguration ColourConfiguration;
#endif /* ColourConfiguration_h */
