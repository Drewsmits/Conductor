//
//  CDOperationQueueProgressWatcher.m
//  Conductor
//
//  Created by Andrew Smith on 4/30/12.
//  Copyright (c) 2012 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
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


#import "CDProgressObserver.h"

@implementation CDProgressObserver

+ (CDProgressObserver *)progressObserverWithStartingOperationCount:(NSInteger)operationCount
                                                     progressBlock:(CDProgressObserverProgressBlock)progressBlock
                                                andCompletionBlock:(CDProgressObserverCompletionBlock)completionBlock
{    
    CDProgressObserver *observer    = [self new];
    observer.startingOperationCount = operationCount;
    observer.progressBlock          = progressBlock;
    observer.completionBlock        = completionBlock;
    return observer;
}

- (void)runProgressBlockWithCurrentOperationCount:(NSNumber *)operationCount
{
    if (!self.progressBlock) return;
    
    NSAssert(!(self.startingOperationCount <= 0), @"Starting operation count was 0 or less than 0! Initialize the watcher with a operation count of larger than 0.");
    
    // Defensive
    if (self.startingOperationCount <= 0) return;
        
    // Calculate percentage progress
    CGFloat progress = (CGFloat)(self.startingOperationCount - [operationCount intValue]) / self.startingOperationCount;
    
    // If operation count is larger than starting operation count, mark progress
    // as 0.  This shouldn't happen, the starting operation count should be updated
    // as operations are added.
    if (progress < 0) progress = 0.0;
    
    self.progressBlock(progress);
}

- (void)runCompletionBlock
{
    if (self.completionBlock) self.completionBlock();
}

- (void)addToStartingOperationCount:(NSNumber *)numberToAdd
{
    self.startingOperationCount += [numberToAdd intValue];
}

@end
