//
//  CDSuperLongTaskOperation.m
//  Conductor
//
//  Created by Andrew Smith on 12/12/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "CDSuperLongTaskOperation.h"

@implementation CDSuperLongTaskOperation

- (void)work
{
    NSLog(@"Starting super long operation");
    
    [self beginBackgroundTask];
    
    // Slightly longer than the permitted 10 minutes
    for (int i = 0; i < 620; i++) {
        
        if (self.isCancelled) {
            [self finish];
            return;
        }
        
        NSLog(@"time: %i", i);
        sleep(1);
    }
    
    NSLog(@"Finishing super long operation");
}

@end
