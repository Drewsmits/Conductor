//
//  CDOperationQueueProgressWatcher.h
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


#import <Foundation/Foundation.h>

typedef void (^CDProgressObserverProgressBlock)(CGFloat progress);
typedef void (^CDProgressObserverCompletionBlock)(void);

@interface CDProgressObserver : NSObject

@property (nonatomic, assign) NSInteger startingOperationCount;

@property (nonatomic, copy) CDProgressObserverProgressBlock progressBlock;

@property (nonatomic, copy) CDProgressObserverCompletionBlock completionBlock;

+ (CDProgressObserver *)progressObserverWithStartingOperationCount:(NSInteger)operationCount
                                                     progressBlock:(CDProgressObserverProgressBlock)progressBlock
                                                andCompletionBlock:(CDProgressObserverCompletionBlock)completionBlock;

/**
 Runs the observers progress block
 */
- (void)runProgressBlockWithCurrentOperationCount:(NSNumber *)operationCount;

/**
 Runs the observers completion block
 */
- (void)runCompletionBlock;

/**
 Adds to the starting operation count.  Say you start with 10 operations,
 then add 5 more, use this to add to the count so that progress can be properly
 adjusted and calculated.
 */
- (void)addToStartingOperationCount:(NSNumber *)numberToAdd;

@end
