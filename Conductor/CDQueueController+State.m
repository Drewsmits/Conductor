//
//  CDQueueController+State.m
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
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


#import "CDQueueController+State.h"

@implementation CDQueueController (State)

#pragma mark - Executing

- (BOOL)isExecuting
{
    __block BOOL isExecuting = NO;
    @synchronized (self.queues)
    {
        [self.queues enumerateKeysAndObjectsUsingBlock:^(id queueName, CDOperationQueue *queue, BOOL *stop) {
            if (queue.isExecuting) {
                isExecuting = YES;
                *stop = YES;
            }
        }];
    };
    return isExecuting;
}

- (BOOL)isQueueExecutingNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    if (!queue) return NO;
    return queue.isExecuting;
}

#pragma mark - Suspend

- (void)suspendAllQueues
{
    ConductorLog(@"Suspend all queues");
    
    NSArray *queuesNamesToSuspend = [self allQueueNames];
    
    for (NSString *queueName in queuesNamesToSuspend) {
        [self suspendQueueNamed:queueName];
    }
}

- (void)suspendQueueNamed:(NSString *)queueName
{
    ConductorLog(@"Suspend queue: %@", queueName);
    CDOperationQueue *queue = [self getQueueNamed:queueName];;
    [queue setSuspended:YES];
}

#pragma mark - Resume

- (void)resumeAllQueues
{
    ConductorLog(@"Resume all queues");
    for (NSString *queueName in self.queues) {
        [self resumeQueueNamed:queueName];
    }
}

- (void)resumeQueueNamed:(NSString *)queueName
{
    ConductorLog(@"Resume queue: %@", queueName);
    CDOperationQueue *queue = [self getQueueNamed:queueName];;
    [queue setSuspended:NO];
}

#pragma mark - Cancel

- (void)cancelAllOperations
{
    ConductorLog(@"Cancel all operations");

    NSArray *queuesNamesToCancel = [self allQueueNames];
    
    for (NSString *queueName in queuesNamesToCancel) {
        [self cancelAllOperationsInQueueNamed:queueName];
    }
}

- (void)cancelAllOperationsInQueueNamed:(NSString *)queueName
{
    ConductorLog(@"Cancel all operations in queue: %@", queueName);
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    [queue cancelAllOperations];
}

@end
