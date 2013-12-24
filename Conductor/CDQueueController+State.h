//
//  CDQueueController+State.h
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "CDQueueController.h"

@interface CDQueueController (State)

/**
 Returns YES if any of the queues are running.
 */
- (BOOL)isExecuting;

/**
 Returns YES if the queue with the given name has operations either executing
 or in the queue.
 */
- (BOOL)isQueueExecutingNamed:(NSString *)queueName;

/**
 Suspends all queues.
 */
- (void)suspendAllQueues;

/**
 Suspends a specific queue
 */
- (void)suspendQueueNamed:(NSString *)queueName;

/**
 Resumes any suspended queues
 */
- (void)resumeAllQueues;

/**
 Resumes a specific queue
 */
- (void)resumeQueueNamed:(NSString *)queueName;

/**
 * Cancels all operations in all queues.  Useful when you need to cleanup before
 * shutting the app down.
 */
- (void)cancelAllOperations;

/**
 * Cancels all the operations is a specific queue
 */
- (void)cancelAllOperationsInQueueNamed:(NSString *)queueName;

@end
