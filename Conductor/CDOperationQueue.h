//
//  CDOperationQueue.h
//  Conductor
//
//  Created by Andrew Smith on 10/21/11.
//  Copyright (c) 2011 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
// of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

#import "CDOperation.h"
#import "CDProgressObserver.h"

@protocol CDOperationQueueDelegate;
@protocol CDOperationQueueOperationsObserver;

typedef enum {
    CDOperationQueueCountLow    = 2,
    CDOperationQueueCountMedium = 4,
    CDOperationQueueCountHigh   = 6,
    CDOperationQueueCountMax    = INT_MAX,
} CDOperationQueueCount;

@interface CDOperationQueue : NSObject <CDOperationDelegate>

@property (nonatomic, weak) id <CDOperationQueueOperationsObserver> operationsObserver;

/**
 * Holds the operation queue
 */
@property (nonatomic, readonly) NSOperationQueue *queue;

/**
 * Dictionary of all CDOperations in the queue, where the key is the operations 
 * identifier and the object is the operation
 */
@property (nonatomic, readonly) NSMutableDictionary *operations;

/**
 The name of the internal NSOperationQueue
 */
@property (nonatomic, readonly) NSString *name;

/**
 The number of operations in the queue.  Wrapper around the operationsCount
 of the internal NSOperationQueue
 */
@property (nonatomic, readonly) NSUInteger operationCount;

/**
 Set of all progress observers for the queue
 */
@property (nonatomic, readonly) NSMutableSet *progressObservers;

/**
 The max number of operations the queue can handle
 */
@property (nonatomic, assign) NSUInteger maxQueuedOperationsCount;

/**
 Returns YES if the queue has the maximum amount of operations
 */
@property (nonatomic, readonly) BOOL maxQueueOperationCountReached;

/**
 Returns a new queue with the queueName
 */
+ (id)queueWithName:(NSString *)queueName;

/**
 * Add an operation to the queue.
 */
- (void)addOperation:(CDOperation *)operation;

/**
 * Update the priority of a given operation if it hasn't already started running
 */
- (BOOL)updatePriorityOfOperationWithIdentifier:(id)identifier 
                                  toNewPriority:(NSOperationQueuePriority)priority;

/**
 Cancel all operations in internal NSOperatioQueue
 */
- (void)cancelAllOperations;

/**
 Cancel operation with identifier
 */
- (void)cancelOperationWithIdentifier:(id)identifier;

/**
 Pauses internal NSOperationQueue
 */
- (void)setSuspended:(BOOL)suspend;

/**
 Returns YES if the operation count is greater than zero
 */
- (BOOL)isExecuting;

/**
 Returns YES if the operation count is zero
 */
- (BOOL)isFinished;

/**
 Returns YES if the internal NSOperationQueue is suspended
 */
- (BOOL)isSuspended;

/**
 Updated the queues max concurency count.  Set it to 1 for serial execution of
 operations.
 */
- (void)setMaxConcurrentOperationCount:(NSUInteger)count;

/**
 * Retrieve an operation with a given identifier.  Returns nil if operation has
 * already finished.
 */
- (CDOperation *)getOperationWithIdentifier:(id)identifier;

/**
 Adds a CDProgressObserver. Observer progress and completion blocks will be run as operations finish
 and call back to the queue.
 */
- (void)addProgressObserver:(CDProgressObserver *)observer;

/**
 Removes the progress obsever
 */
- (void)removeProgressObserver:(CDProgressObserver *)observer;

/**
 Removes all progress observers
 */
- (void)removeAllProgressObservers;

@end

@protocol CDOperationQueueOperationsObserver <NSObject>
- (void)maxQueuedOperationsReachedForQueue:(CDOperationQueue *)queue;
- (void)canBeginSubmittingOperationsForQueue:(CDOperationQueue *)queue;
@end
