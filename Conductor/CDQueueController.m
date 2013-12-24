//
//  Conductor.m
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

#import "CDQueueController.h"

@implementation CDQueueController

- (id)init
{
    self = [super init];
    if (self) {
        _queues = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (id)sharedInstance
{
    static CDQueueController *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });
    return _sharedInstance;
}

#pragma mark - Queues

- (BOOL)addQueue:(CDOperationQueue *)queue
{
    @synchronized (self.queues) {
        if (!queue) {
            NSAssert(NO, @"Cannot add a nil queue to Conductor.");
            return NO;
        }
        
        if (!queue.name) {
            NSAssert(NO, @"Cannot add a queue without a name to Conductor.");
            return NO;
        }
        
        if ([self getQueueNamed:queue.name]) {
            ConductorLog(@"Conductor already has queue named %@", queue.name);
            return NO;
        }
        
        ConductorLog(@"Adding queue named: %@", queue.name);
        
        [self.queues setObject:queue forKey:queue.name];
        
        return YES;
    }
}

- (CDOperationQueue *)getQueueNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self.queues objectForKey:queueName];
    return queue;
}

- (NSArray *)allQueueNames
{
    return [self.queues allKeys];
}

- (BOOL)hasQueues
{
    return (self.queues.count > 0);
}

#pragma mark - Operations

- (void)addOperation:(CDOperation *)operation 
        toQueueNamed:(NSString *)queueName 
{        
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    NSAssert(queue, @"Tried to add an operation to a queue that doesnt exist. Create the queue, then add it to Conductor.");
    
    ConductorLog(@"Adding operation to queue: %@", queue.name);
        
    // Add and start operation
    [queue addOperation:operation];
}

- (BOOL)updatePriorityOfOperationWithIdentifier:(NSString *)identifier
                                   inQueueNamed:(NSString *)queueName
                                  toNewPriority:(NSOperationQueuePriority)priority
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    return [queue updatePriorityOfOperationWithIdentifier:identifier
                                            toNewPriority:priority];
}

- (BOOL)hasOperationWithIdentifier:(NSString *)identifier 
                      inQueueNamed:(NSString *)queueName
{
    return ([self operationWithIdentifier:identifier inQueueNamed:queueName] != nil);
}

- (CDOperation *)operationWithIdentifier:(NSString *)identifier
                            inQueueNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    return [queue getOperationWithIdentifier:identifier];
}

- (NSUInteger)numberOfOperationsInQueueNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    if (!queue) return 0;
    return [queue operationCount];
}

#pragma mark - Queue Progress

- (void)addProgressObserver:(CDProgressObserver *)observer
               toQueueNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    [queue addProgressObserver:observer];
}

- (void)removeProgresObserver:(CDProgressObserver *)observer
               fromQueueNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    [queue removeProgressObserver:observer];
}

#pragma mark - Operation Observer

- (void)addQueueOperationObserver:(id)observer
                     toQueueNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    queue.operationsObserver = observer;
}

- (void)removeQueuedOperationObserver:(id)observer
                       fromQueueNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    queue.operationsObserver = nil;
}

@end
