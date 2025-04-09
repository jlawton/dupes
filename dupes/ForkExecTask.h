//
//  ForkExecTask.h
//  dupes
//
//  Created by James Lawton on 4/1/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ForkExecTask : NSObject

+ (instancetype)launchedTaskWithLaunchPath:(NSString *)path arguments:(NSArray<NSString *> *)arguments;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

// these methods can only be set before a launch
@property (nullable, copy) NSString *launchPath;
@property (nullable, copy) NSArray<NSString *> *arguments;
//@property (nullable, copy) NSDictionary<NSString *, NSString *> *environment; // if not set, use current
//@property (copy) NSString *currentDirectoryPath; // if not set, use current
@property (nonatomic) BOOL reopenTTY;

// actions
- (void)launch;

- (void)waitUntilExit;

// status
@property (readonly) int processIdentifier;
@property (readonly, getter=isRunning) BOOL running;

// WARNING: These are only valid if you waitUntilExit or the task has otherwise
// completed.
@property (readonly) int terminationStatus;
@property (readonly) NSTaskTerminationReason terminationReason;

@end

@interface ForkExecTask (Convenience)

// This will return `nil` if we're not in a Terminal, have redirected input or
// output, or if vim isn't found or fails to launch.
+ (nullable instancetype)launchVimWithArguments:(NSArray<NSString *> *)arguments reopenTTY:(BOOL)reopenTTY;

@end

BOOL reopenStandardInputTTY(void);

NS_ASSUME_NONNULL_END
