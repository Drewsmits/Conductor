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

@interface CDOperationQueue ()

@property (nonatomic, readwrite, strong) NSOperationQueue *queue;
@property (nonatomic, readwrite, strong) NSMutableDictionary *operations;
@property (nonatomic, readwrite, strong) NSMutableSet *progressWatchers;

- (void)operationDidFinish:(CDOperation *)operation;

@end

@implementation CDOperationQueue

@synthesize delegate,
            queue,
            operations,
            progressWatchers;

- (void)dealloc {
    delegate = nil;
}

- (id)init {
    self = [super init];
    if (self) {
        self.queue            = [[NSOperationQueue alloc] init];
        self.operations       = [[NSMutableDictionary alloc] init];
        self.progressWatchers = [[NSMutableSet alloc] init];
    }
    return self;
}

+ (id)queueWithName:(NSString *)queueName {
    CDOperationQueue *q = [[self alloc] init];
    q.queue.name = queueName;
    return q;
}

- (void)queueDidFinish {
    [self.progressWatchers makeObjectsPerformSelector:@selector(runCompletionBlock)];
    
    [self.delegate queueDidFinish:self];
}

#pragma mark - Operations API

- (void)addOperation:(CDOperation *)operation {
    [self addOperation:operation atPriority:operation.queuePriority];
}

- (void)addOperation:(CDOperation *)operation 
          atPriority:(NSOperationQueuePriority)priority {
    
    if (![operation isKindOfClass:[CDOperation class]]) {
        NSAssert(nil, @"You must use a CDOperation sublcass with Conductor!");
        return;
    }
    
    // Add operation to operations dict
    @synchronized (self.operations) {
        [self.operations setObject:operation 
                            forKey:operation.identifier];
    }
    
    // KVO operation isFinished.  Allows cleanup after operation is
    // finished or canceled, as well as queue progress updates.
    [operation addObserver:self
                forKeyPath:@"isFinished" 
                   options:NSKeyValueObservingOptionNew 
                   context:nil];
    
    // set priority
    [operation setQueuePriority:priority];
    
    // Update progress watcher count
    [self.progressWatchers makeObjectsPerformSelector:@selector(addToStartingOperationCount:)
                                           withObject:[NSNumber numberWithInt:1]];

    
    // Add operation to queue and start
    [self.queue addOperation:operation];
}

- (void)removeOperation:(CDOperation *)operation {
    if (![self.operations objectForKey:operation.identifier]) return;
    
    ConductorLogTrace(@"Removing operation %@ from queue %@", operation.identifier, self.name);
    
    [operation removeObserver:self forKeyPath:@"isFinished"];
    
    @synchronized (self.operations) {
        [self.operations removeObjectForKey:operation.identifier];
    }

    [self.progressWatchers makeObjectsPerformSelector:@selector(runProgressBlockWithCurrentOperationCount:)
                                           withObject:[NSNumber numberWithInt:self.operationCount]];
}

- (void)cancelAllOperations {
    // We don't want to KVO any operations anymore, because
    // we are cancelling.
    
    @synchronized (self.operations) {
        for (CDOperation *operation in self.queue.operations) {
            [self removeOperation:operation];
        }
    }
    
    [self.queue cancelAllOperations];
        
    // Allow NSOperation queue to start operations and clear themselves out.
    // They will all be marked as canceled, and if you build your sublcass
    // correctly, they will exit properly.
    [self setSuspended:NO];
}

- (void)operationDidFinish:(CDOperation *)operation {
    [self removeOperation:operation];
    
    if (self.operationCount == 0) {
        [self queueDidFinish];
    }
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
        
    if ([keyPath isEqualToString:@"isFinished"] && [object isKindOfClass:[CDOperation class]]) {
        CDOperation *op = (CDOperation *)object;
        [self operationDidFinish:op];
    }

}

#pragma mark - Priority

- (BOOL)updatePriorityOfOperationWithIdentifier:(id)identifier 
                                  toNewPriority:(NSOperationQueuePriority)priority {
    CDOperation *op = [self getOperationWithIdentifier:identifier];
    
    // These tests are probably not necessry, just thrown in for extra safety
    if (op && ![op isExecuting] && ![op isCancelled] && ![op isFinished]) {
        [op setQueuePriority:priority];
        return YES;
    }
    
    return NO;
}

#pragma mark - Progress

- (void)addProgressWatcherWithProgressBlock:(CDOperationQueueProgressWatcherProgressBlock)progressBlock
                         andCompletionBlock:(CDOperationQueueProgressWatcherCompletionBlock)completionBlock {    
       
    ConductorLogTrace(@"Adding progress watcher to queue %@", self.name);
    
    CDOperationQueueProgressWatcher *watcher = [CDOperationQueueProgressWatcher progressWatcherWithStartingOperationCount:self.operationCount
                                                                                                            progressBlock:progressBlock
                                                                                                       andCompletionBlock:completionBlock];
    [self.progressWatchers addObject:watcher];
}

#pragma mark - State

//- (BOOL)isReady {
//    return (self.state == CDOperationQueueStateReady);
//}

- (BOOL)isExecuting {
    return (self.operationCount > 0);
}

- (BOOL)isFinished {
    return (self.operationCount == 0);
}

- (BOOL)isSuspended {
    return self.queue ? self.queue.isSuspended : NO;
}

#pragma mark - Accessors

- (void)setSuspended:(BOOL)suspend {
    [self.queue setSuspended:suspend];
}

- (NSString *)name {
    return self.queue ? self.queue.name : nil;
}

- (NSInteger)operationCount {
    return self.operations.count;
}

- (CDOperation *)getOperationWithIdentifier:(id)identifier {
    CDOperation *op = [self.operations objectForKey:identifier];
    return op;
}

@end
