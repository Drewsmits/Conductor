//
//  CDQueueController+Test.h
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "CDQueueController.h"

@interface CDQueueController (Test)

/**
 Blocks the calling thread until all jobs in the designated queue finish.  This
 can be useful for unit testing asynchronous code.  This could be dangerous in
 production.
 */
- (void)waitForQueueNamed:(NSString *)queueName;

- (void)logAllOperations;

- (void)logAllOperationsInQueueNamed:(NSString *)queueName;

@end
