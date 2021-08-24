//
//  ReverbConfiguration.h
//  Synestheatre
//
//  Created by James on 18/02/2020.
//  Copyright © 2020 James. All rights reserved.
//

#ifndef ReverbConfiguration_h
#define ReverbConfiguration_h

struct ReverbConfiguration {
    float wetDryMix;
    CFIndex presetIndex;
};

typedef struct ReverbConfiguration ReverbConfiguration;

#endif /* ReverbConfiguration_h */
