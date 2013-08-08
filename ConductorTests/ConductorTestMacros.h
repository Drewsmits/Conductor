//
//  ConductorTestMacros.h
//  Conductor
//
//  Created by Andrew Smith on 6/25/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#ifndef Conductor_ConductorTestMacros_h
#define Conductor_ConductorTestMacros_h

#import "CDTest.h"

static NSURL *DataModelURL(void) {
    
    NSBundle *testBundle = [NSBundle bundleForClass:[CDTest class]];
    
    NSString *path = [testBundle pathForResource:@"ConductorTestDataModel" 
                                          ofType:@"momd"];
    return [NSURL URLWithString:path];
}

static NSURL *DataStoreURL(void) {
    
    NSBundle *testBundle = [NSBundle bundleForClass:[CDTest class]];
    
    NSURL *storeURL = [[testBundle resourceURL] URLByAppendingPathComponent:@"ConductorTests.sqlite"];
    
    return storeURL;
}

static void DeleteDataStore(void) {
    
    NSURL *url = DataStoreURL();
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (url) {
        [fileManager removeItemAtURL:url error:NULL];
    }
}

#define WAIT_ON_BOOL(value) NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];\
while (value == NO) {\
[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];\
}\

#endif
