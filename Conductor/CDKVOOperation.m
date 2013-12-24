//
//  CDThreadOperation.m
//  Conductor
//
//  Created by Andrew Smith on 3/29/13.
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


#import "CDKVOOperation.h"

static inline NSString *StringForCDOperationState(CDOperationState state) {
    switch (state) {
        case CDOperationStateReady:
            return @"isReady";
            break;
        case CDOperationStateExecuting:
            return @"isExecuting";
            break;
        case CDOperationStateFinished:
            return @"isFinished";
            break;
        default:
            return nil;
            break;
    }
}

@interface CDKVOOperation ()
@property (nonatomic, assign) CDOperationState state;
@end

@implementation CDKVOOperation

- (void)start
{
    @autoreleasepool {
        //
        // Flip state, per Apple Docs
        //
        self.state = CDOperationStateExecuting;

        //
        // Respect the cancel
        //
        if (self.isCancelled) {
            [self finish];
            return;
        }
    
        //
        // Do work. Notice that you will have to manually call 'finish' when your work is done. This
        // allows async jobs to continue on the thread without finishing the operation before the
        // callbacks happen.
        //
        [self work];
    }
}

- (void)finish
{
    [super finish];
    
    //
    // Flip state, per Apple Docs
    //
    self.state = CDOperationStateFinished;
}

- (BOOL)isReady
{
    return (self.state == CDOperationStateReady);
}

- (BOOL)isExecuting
{
    return (self.state == CDOperationStateExecuting);
}

- (BOOL)isFinished
{
    return (self.state == CDOperationStateFinished);
}

- (void)setState:(CDOperationState)state
{
    //
    // Ensures KVO complience for changes in NSOperation object state
    //
    
    if (self.state == state) return;
    
    NSString *oldStateString = StringForCDOperationState(self.state);
    NSString *newStateString = StringForCDOperationState(state);
    
    [self willChangeValueForKey:newStateString];
    [self willChangeValueForKey:oldStateString];
    _state = state;
    [self didChangeValueForKey:oldStateString];
    [self didChangeValueForKey:newStateString];
}

@end
