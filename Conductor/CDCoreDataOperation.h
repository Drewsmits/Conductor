//
//  CDCoreDataOperation.h
//  Conductor
//
//  Created by Andrew Smith on 6/17/12.
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


#import "CDOperation.h"
#import <CoreData/CoreData.h>

@interface CDCoreDataOperation : CDOperation

@property (nonatomic, strong) NSManagedObjectContext *mainContext;

/**
 This will get created in the main method, which supports thread confinment
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *backgroundContext;

+ (CDCoreDataOperation *)operationWithMainContext:(NSManagedObjectContext *)mainContext;

/**
 Queue and wait on a save on the background context. Waiting prevents bailing on the NSOperation before
 the save happens. The parent context is the main context, which means that when the background context
 is saved, the results are pushed to the main context.
 */
- (BOOL)saveBackgroundContext;

/**
 Optionally, you can queue up a save on the main context when you are done. This isn't necessary for
 changes to show up on the main queue, but it is necessary for objects to be persisted to the persistent
 store.
 */
- (void)queueMainContextSave;

@end
