//
//  CDOneSecondOperation.m
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "CDOneSecondOperation.h"

@implementation CDOneSecondOperation

- (void)work
{
    sleep(1);
}

- (void)cleanup
{
    // noop
}

@end
