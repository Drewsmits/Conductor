//
//  CDOperationQueueProgressWatcherTests.m
//  Conductor
//
//  Created by Andrew Smith on 5/2/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "CDOperationQueueProgressWatcherTests.h"

#import "CDProgressObserver.h"
#import "CDTestOperation.h"
#import "CDLongRunningTestOperation.h"

@implementation CDOperationQueueProgressWatcherTests

- (void)testCreateWatcher {
    CDProgressObserver *watcher = [CDProgressObserver progressObserverWithStartingOperationCount:10
                                                                                   progressBlock:nil
                                                                              andCompletionBlock:nil];
    
    STAssertNotNil(watcher, @"Should create watcher");
    STAssertEquals(watcher.startingOperationCount, 10, @"Should have correct number of operations");
}

- (void)testRunWatcherProgressBlock {
    
    __block float progressIndicator = 0.0f;
    
    CDProgressObserverProgressBlock progressBlock = ^(float progress) {
        progressIndicator = progress;
    };
    
    CDProgressObserver *watcher = [CDProgressObserver progressObserverWithStartingOperationCount:10
                                                                                   progressBlock:progressBlock
                                                                              andCompletionBlock:nil];
    
    [watcher runProgressBlockWithCurrentOperationCount:@1];
        
    STAssertEqualsWithAccuracy(progressIndicator, 0.9f, 0.000001f, @"Progress block should run correctly");
}

- (void)testRunWatcherCompletionBlock {
    
    __block BOOL completionBlockDidRun = NO;
    
    CDProgressObserverCompletionBlock completionBlock = ^(void) {
        completionBlockDidRun = YES;
    };
    
    CDProgressObserver *watcher = [CDProgressObserver progressObserverWithStartingOperationCount:10
                                                                                   progressBlock:nil
                                                                              andCompletionBlock:completionBlock];
    
    [watcher runCompletionBlock];
    
    STAssertTrue(completionBlockDidRun, @"Completion block should run correctly");
}

- (void)testStartingOperationCount
{
    CDLongRunningTestOperation *op1 = [CDLongRunningTestOperation new];
    CDLongRunningTestOperation *op2 = [CDLongRunningTestOperation new];    
    CDLongRunningTestOperation *op3 = [CDLongRunningTestOperation new];    
    
    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    [testOperationQueue addOperation:op3];
    
    CDProgressObserver *observer = [CDProgressObserver new];
    
    [testOperationQueue addProgressObserver:observer];
    
    NSArray *watchers = [[testOperationQueue progressObservers] allObjects];
    CDProgressObserver *watcher = (CDProgressObserver *)watchers[0];
    
    STAssertEquals(watcher.startingOperationCount, 3, @"Progress watcher should have correct starting operation count");    
}

- (void)testAddToStartingOperationCount
{
    CDLongRunningTestOperation *op1 = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];
    CDLongRunningTestOperation *op2 = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];    
    CDLongRunningTestOperation *op3 = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];    
    CDLongRunningTestOperation *op4 = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];    

    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    [testOperationQueue addOperation:op3];
    
    CDProgressObserver *observer = [CDProgressObserver new];
    
    [testOperationQueue addProgressObserver:observer];

    [testOperationQueue addOperation:op4];
    
    NSArray *watchers = [[testOperationQueue progressObservers] allObjects];
    CDProgressObserver *watcher = (CDProgressObserver *)watchers[0];
    
    STAssertEquals(watcher.startingOperationCount, 4, @"Progress watcher should have correct starting operation count");    
}

- (void)testRunWatcherProgressAndCompletionBlocks
{
    CDTestOperation *op1 = [CDTestOperation new];
    CDTestOperation *op2 = [CDTestOperation new];
    CDTestOperation *op3 = [CDTestOperation new];
    
    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    [testOperationQueue addOperation:op3];
    
    __block float progressIndicator = 0.0f;
    
    CDProgressObserverProgressBlock progressBlock = ^(float progress) {
        progressIndicator = progress;
    };
    
    __block BOOL completionBlockDidRun = NO;
    
    CDProgressObserverCompletionBlock completionBlock = ^(void) {
        completionBlockDidRun = YES;
    };
    
    CDProgressObserver *observer = [CDProgressObserver new];

    observer.progressBlock = progressBlock;
    observer.completionBlock = completionBlock;
    
    [testOperationQueue addProgressObserver:observer];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (testOperationQueue.isExecuting) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    } 
    
    STAssertTrue(completionBlockDidRun, @"Completion block should run");
    STAssertEquals(progressIndicator, 1.0f, @"Progress block should run correctly");
}

@end
