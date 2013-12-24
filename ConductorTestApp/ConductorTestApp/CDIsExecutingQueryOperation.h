//
//  CDIsExecutingQueryOperation.h
//  Conductor
//
//  Created by Andrew Smith on 3/9/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <Conductor/CDQueueController.h>

@interface CDIsExecutingQueryOperation : CDOperation

@property (nonatomic, assign) NSUInteger numCycles;

+ (CDIsExecutingQueryOperation *)operationWithRandomNumCycles;

@end
