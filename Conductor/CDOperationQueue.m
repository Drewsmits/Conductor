//
//  CDOperationQueue.m
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

#import "CDOperationQueue.h"

@implementation CDOperationQueue

- (void)dealloc
{
    _operationsObserver = nil;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _queue                    = [[NSOperationQueue alloc] init];
        _operations               = [[NSMutableDictionary alloc] init];
        _progressObservers        = [[NSMutableSet alloc] init];
        _maxQueuedOperationsCount = CDOperationQueueCountMax;
    }
    return self;
}

+ (id)queueWithName:(NSString *)queueName
{
    CDOperationQueue *q = [[self alloc] init];
    q.queue.name = queueName;
    return q;
}

#pragma mark - Operations API

- (void)addOperation:(CDOperation *)operation 
{
    if (![operation isKindOfClass:[CDOperation class]])
    {
        NSAssert(nil, @"You must use a CDOperation sublcass with Conductor!");
        return;
    }
        
    //
    // If the operation already exists, give the new operation a unique identifier to avoid collision
    //
    if ([self getOperationWithIdentifier:operation.identifier] != nil)
    {
        ConductorLog(@"Already has operation with identifier %@. Uniquifiying this one.", operation.identifier);
        operation.identifier = [[NSProcessInfo processInfo] globallyUniqueString];
    }
    
    @synchronized(self.operations)
    {
        //
        // Add operation to dict
        //
        [self.operations setObject:operation 
                            forKey:operation.identifier];
        
        //
        // Update progress watcher count
        //
        [self.progressObservers makeObjectsPerformSelector:@selector(addToStartingOperationCount:)
                                                withObject:@(1)];
        
        //
        // Operation will call back when it is done
        //
        operation.delegate = self;
    }
    
    // Add operation to queue, which starts it
    [self.queue addOperation:operation];
    
    //
    // If the max is reached, alert the observer
    //
    if (self.maxQueueOperationCountReached)
    {
        if ([self.operationsObserver respondsToSelector:@selector(maxQueuedOperationsReachedForQueue:)])
        {
            [self.operationsObserver maxQueuedOperationsReachedForQueue:self];
        }
    } else {
        if ([self.operationsObserver respondsToSelector:@selector(canBeginSubmittingOperationsForQueue:)])
        {
            [self.operationsObserver canBeginSubmittingOperationsForQueue:self];
        }
    }
}

- (void)removeOperation:(CDOperation *)operation
{
    @synchronized(self.operations)
    {
        if (![self.operations objectForKey:operation.identifier]) return;
     
        ConductorLog(@"Removing operation %@ from queue %@", operation.identifier, self.name);

        //
        // Remove the operation
        //
        [self.operations removeObjectForKey:operation.identifier];
        
        //
        // All progress observers run the progress block with the current operation count
        //
        [self.progressObservers makeObjectsPerformSelector:@selector(runProgressBlockWithCurrentOperationCount:)
                                                withObject:@(self.operationCount)];
    }
}

- (void)cancelAllOperations
{
    /** 
     This method sends a cancel message to all operations currently in the queue. 
     Queued operations are cancelled before they begin executing. If an operation 
     is already executing, it is up to that operation to recognize the cancellation 
     and stop what it is doing.  Cancelled operations still call start, then should
     immediately respond to the cancel request.
    */
    [self.queue cancelAllOperations];
        
    /**
     Allow NSOperation queue to start operations and clear themselves out.
     They will all be marked as canceled, and if you build your sublcass
     correctly, they will exit properly.
     */
    [self setSuspended:NO];

}

- (void)cancelOperationWithIdentifier:(id)identifier
{
    CDOperation *op = [self getOperationWithIdentifier:identifier];
    [op cancel];
}

- (void)operationDidFinish:(CDOperation *)operation
{
    [self removeOperation:operation];
    
    //
    // If the max count hasn't been reached, alert the operations observer that the queue can accept
    // jobs again.
    //
    if (!self.maxQueueOperationCountReached)
    {
        if ([self.operationsObserver respondsToSelector:@selector(canBeginSubmittingOperationsForQueue:)])
        {
            [self.operationsObserver canBeginSubmittingOperationsForQueue:self];
        }
    }
    
    if (self.operationCount == 0)
    {
        [self queueDidFinish];
    }
}

- (void)operationWasCanceled:(CDOperation *)operation
{
    
}

#pragma mark - State

- (BOOL)isExecuting
{
    return (self.operationCount > 0);
}

- (BOOL)isFinished
{
    return (self.operationCount == 0);
}

- (BOOL)isSuspended
{
    return self.queue.isSuspended;
}

- (void)setSuspended:(BOOL)suspend
{
    [self.queue setSuspended:suspend];
}

- (void)queueDidFinish
{
    //
    // All progress observers run completion block
    //
    [self.progressObservers makeObjectsPerformSelector:@selector(runCompletionBlock)];
    
    //
    // Remove all progress observers
    //
    [self removeAllProgressObservers];
}

#pragma mark - Max

- (BOOL)maxQueueOperationCountReached
{
    return (self.operationCount >= self.maxQueuedOperationsCount);
}

- (void)setMaxConcurrentOperationCount:(NSUInteger)count
{
    [self.queue setMaxConcurrentOperationCount:count];
}

#pragma mark - Priority

- (BOOL)updatePriorityOfOperationWithIdentifier:(id)identifier 
                                  toNewPriority:(NSOperationQueuePriority)priority
{
    CDOperation *op = [self getOperationWithIdentifier:identifier];
    
    if (!op) return NO;
    
    [op setQueuePriority:priority];
    
    return YES;
}

#pragma mark - Progress

- (void)addProgressObserver:(CDProgressObserver *)observer
{
    @synchronized (self.progressObservers)
    {
        ConductorLog(@"Adding progress watcher to queue %@", self.name);
        observer.startingOperationCount = self.operationCount;
        [self.progressObservers addObject:observer];
    }
}

- (void)removeProgressObserver:(CDProgressObserver *)observer
{
    @synchronized (self.progressObservers)
    {
        [self.progressObservers removeObject:observer];
    }
}

- (void)removeAllProgressObservers
{
    @synchronized (self.progressObservers)
    {
        [self.progressObservers removeAllObjects];
    }
}

#pragma mark - Accessors

- (NSString *)name
{
    return self.queue ? self.queue.name : nil;
}

- (NSUInteger)operationCount
{
    return self.operations.count;
}

- (CDOperation *)getOperationWithIdentifier:(id)identifier
{
    if (!identifier) return nil;
    CDOperation *op = [self.operations objectForKey:identifier];
    return op;
}

@end
