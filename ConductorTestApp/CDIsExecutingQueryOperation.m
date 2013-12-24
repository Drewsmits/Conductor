//
//  CDIsExecutingQueryOperation.m
//  Conductor
//
//  Created by Andrew Smith on 3/9/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "CDIsExecutingQueryOperation.h"
#import <Conductor/Conductor.h>

@implementation CDIsExecutingQueryOperation

+ (CDIsExecutingQueryOperation *)operationWithRandomNumCycles
{
    CDIsExecutingQueryOperation *op = [self new];
    op.numCycles = arc4random() % 2000;
    return op;
}

- (void)work
{
    for (int i = 0; i < self.numCycles; i++) {
        [[CDQueueController sharedInstance] isExecuting];
    }
}

@end
