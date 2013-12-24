//
//  CDCoreDataOperation.m
//  Conductor
//
//  Created by Andrew Smith on 6/25/12.
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



#import "CDCoreDataOperationTests.h"
#import "Conductor.h"

#import "CDCoreDataOperation.h"
#import "CDTestCoreDataOperation.h"
#import "ConductorTestMacros.h"

@implementation CDCoreDataOperationTests

- (void)setUp
{
    [super setUp];
    
    DeleteDataStore();
    
    // Build Model
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:DataModelURL()];
    
    XCTAssertNotNil(model, @"Managed Object Model should exist");
    
    // Build persistent store coordinator
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    // Build Store
    NSError *error = nil;
    store = [coord addPersistentStoreWithType:NSSQLiteStoreType
                                configuration:nil
                                          URL:DataStoreURL()
                                      options:nil 
                                        error:&error];
    
    // Build context
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [context setPersistentStoreCoordinator:coord];
}

- (void)tearDown
{
    NSError *error = nil;
    XCTAssertTrue([coord removePersistentStore:store error:&error], 
                 @"couldn't remove persistent store: %@", error);
        
    [super tearDown];
}

- (void)testStart
{
    CDCoreDataOperation *operation = [CDCoreDataOperation operationWithMainContext:context];
    
    [operation start];
    
    XCTAssertNotNil(operation.backgroundContext, @"Operation background context should not be nil!");
}

- (void)testBackgroundContextDidSave
{    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Employee" inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"1 = 1"]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    XCTAssertEqual([results count], 0U, @"Should only have one employee");

    __block BOOL hasFinished = NO;
    void (^completionBlock)(void) = ^(void) {
        hasFinished = YES;
    };
    
    
    CDTestCoreDataOperation *operation = (CDTestCoreDataOperation *)[CDTestCoreDataOperation operationWithMainContext:context];
    operation.completionBlock = completionBlock;
    
    [conductor addOperation:operation toQueueNamed:CONDUCTOR_TEST_QUEUE];
        
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    [conductor waitForQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    results = [context executeFetchRequest:request error:&error];
    
    NSManagedObject *employee = [results lastObject];

    XCTAssertEqual([results count], 1U, @"Should only have one employee");
    XCTAssertEqualObjects([employee valueForKey:@"employeeID"], @1, @"Employee should have correct ID");
}

@end
