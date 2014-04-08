#Conductor

***

##Introduction

Conductor is a useful way to keep track of asynchronous `NSOperation` jobs in an `NSOperationQueue`.

* Change operation priority
* Manage multiple queues
* Track queue progress
* Pause/Resume queues
* Use thread safe `NSManagedObjectContext` objects
* Easily background tasks that run when your app isn't active

Often times in iOS apps there is a need to manage long running tasks. Whether it is downloading images from a server, parsing JSON from an API, or fetching Core Data objects, it's vital to move these tasks off of the main thread for a good user experience.

The iOS SDK offers several ways to run tasks in the background.  CGD is fantastic for one off asynchronous operations.  The `NSOperationQueue` class is a great way to treat tasks as objects using the `NSOperation` class. However, it's not immediately obvious how to subclass `NSOperation`, or how to track queue progress. I use Conductor in pretty much every iOS app I write, often as the starting point for things like network request queues, or image processing tasks. Checkout [Latergram](https://itunes.apple.com/pl/app/latergram/id511356446?mt=8) for an app that uses Conductor to manage long running tasks in the background. All image processing is done using `CDOperation` subclasses.

##Installation

Conductor is built as a static library, based on some of the excellent conventions detailed by Jonah Williams on [Using Open Source Static Libraries in Xcode 4](http://blog.carbonfive.com/2011/04/04/using-open-source-static-libraries-in-xcode-4/). I highly recommend reading this to understand how the installation process works.

1. Add Conductor as a git submodule to your repository. `git submodule add git@github.com:ChazInc/Conductor.git`
2. Add `Conductor.xcodeproj` to your project. `File > Add Files to "MyProject"…`
3. Add Conductor as a target dependency to your app target under the `Build Phases` menu.
4. Link the binary to the Conductor library.
5. Add `$(OBJROOT)/UninstalledProducts/include` to your **User Header Search Paths**, and set **Always Search User Paths** to Yes. This prevents a missing header problem when archiving your app.
6. Make sure your `Other Linker Flags` includes `-ObjC` to properly load categories.
7. Import Conductor with `#import <Conductor/Conductor.h>`
8. Build the project to check and make sure you setup everything correctly.

##Using Conductor

### The CDQueueController

The `CDQueueController` is the main component of Conductor. You will do most of your interaction with this object. It manages multiple `CDOperationQueues` for you, making it convenient and simple to add operations and keep track of queues. You can create and keep track of as many CDQueueControllers as you want, but I usually end up using one and storing it on the App Delegate.

```objective-c
#import <UIKit/UIKit.h>
#import <Conductor/Conductor.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) CDQueueController *mainQueueController;

@end
```

### Building A Queue

After we have a new `CDQueueController`, we can create a queue and add it. For this example we will create a serial queue. I usually do this after the application has finished launching. Give it a meaningful name, that will be useful later on in your logging when you want to know where an error occurred.

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.mainQueueController = [CDQueueController new];
    
    CDOperationQueue *serialQueue = [CDOperationQueue queueWithName:@"com.conductor.serialQueue"];
    [serialQueue setMaxConcurrentOperationCount:1];
    
    [self.mainQueueController addQueue:serialQueue];
    
    return YES;
}
```

### Sublcassing CDOperation

Understanding how to sublcass `NSOperation` can take some time. It's probably a good idea to read Apple's guide on [subclassing NSOperation](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/NSOperation_class/Reference/Reference.html#//apple_ref/doc/uid/TP40004591-RH2-SW18) to understand how the design works.  Subclasses have to properly [respond to the cancel command](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/NSOperation_class/Reference/Reference.html#//apple_ref/doc/uid/TP40004591-RH2-SW18). This topic is a work in progress and probably deserves it's own blog post. 

For starters, let's build an operation that simply sleeps for one second. There are two methods you should be aware of.

* `-(void)work;` : This is where you do task.
* `-(void)cleanup;` : This is where you can optionally run some cleanup after the work is done.

```objective-c
#import "CDOneSecondOperation.h"

@implementation CDOneSecondOperation

- (void)work
{
    sleep(1);
}

- (void)cleanup
{
    NSLog(@"I'm done!");
}

@end
```

Pretty simple, right? CDOperation takes care of wrapping everything you do in an autorelease pool, so no need to worry about that. No need to worry about whether or not you use `-(void)start` or `-(void)main`, or worrying about making sure you have done proper KVO for `isReady` or `isFinished`; that work is done for you. Just worry about running the task you want to run!

### Adding Operations

Once you have a `CDOperation` ready to go, you add it to your queue. Let's imagine we want to start a task from a button press in a `UIViewController`. As far as keeping track of your main `CDQueueController`, that is up to you, but let's imagine we pass in the instance from the `AppDelegate` to our `UIViewController` before we show it.

```objective-c
- (IBAction)start:(id)sender
{
    CDOneSecondOperation *operation = [CDOneSecondOperation new];
    [self.mainQueueController addOperation:operation
                              toQueueNamed:@"com.conductor.serialQueue"];
}
```

`NSOperationQueues` are first-in-first-out, or FIFO.  The operation will start the second it's on the queue, provided there aren't any operations already in the queue.

### Be Responive

Conductor allows you to keep track of specific operations by specifying operation identifier, which you can use to change the priority of an operation in a queue to improve the responsiveness of your app. You can either assign your own identifier to an operations, otherwise it the operation will get a unique string. Imagine that you have 100 operations in your queue. When you hit the start button in your `UIViewController`, the operation will be added and sit there until all 100 of the other operations finish. Let's add a button that increases the operations priority.

```objective-c
- (IBAction)start:(id)sender
{
    CDOneSecondOperation *operation = [CDOneSecondOperation new];
    operation.identifier = @"ImportantOperation";
    [self.mainQueueController addOperation:operation
                              toQueueNamed:@"com.conductor.serialQueue"];
}

- (IBAction)increasePriority:(id)sender
{
    [self.mainQueueController updatePriorityOfOperationWithIdentifier:@"ImportantOperation"
                                                        toNewPriority:NSOperationQueuePriorityVeryHigh];
}
```

While this seems trivial, imagine you have a table view that can display 10 cells at a time. The data source has 100 items in it, where each item has the URL for an image on a server somewhere. You want to download and display these images in each one of the cells. The niave approach would be to start at cell 1 and add 100 `CDOperation` subclasses that download a single image each. But what happens if the user scrolls to the very bottom of the list? Now they have to wait for 90 other images to download and clear out before the content on their screen shows up. That's bad. With Conductor, you can keep track of what cells are displayed on the screen and continually adjust download priority based on what content the user is looking at.

In this case, it's better to be responsive than fast. You could have the fastest image downloader on the planet, but your users will still think you app drags if the content they are looking at isn't loading. While it is trickier, you are way better off properly managing your queue's priority.

### Tracking Progress

Let's add 100 1-second `CDOperations` to our queue. With `CDProgressObserver`, you can keep track of the percent completion of your queue, as well as when it is finished. It's up to you to make sure you add and remove the observers yourself. Let's add 100 operations in our `UIViewController` `viewDidLoad` method.

```objective-c
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CDProgressObserver *observer = [CDProgressObserver new];
    
    observer.progressBlock = ^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Makin progress: %f", progress);            
        })
    };
    
    observer.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"I'm done");
        })
    };
    
    [self.mainQueueController addProgressObserver:observer
                                     toQueueNamed:@"com.conductor.serialQueue"];
}
```

You're probably doing stuff like updating the UI when you track progress, which is why the `dispatch_async` calls are there. Always update the UI on the main thread, otherwise you could see some strange behavior.

```

##Contributing

Forks, patches and other feedback are always welcome. 

### Conductor is brought to you by Egraphs###

Contributors:

* [Andrew B. Smith](http://github.com/drewsmits).
