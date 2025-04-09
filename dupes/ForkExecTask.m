//
//  ForkExecTask.m
//  dupes
//
//  Created by James Lawton on 4/1/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

@import Darwin;

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>

#import "ForkExecTask.h"

#ifndef _PATH_TTY
#  define _PATH_TTY "/dev/tty"
#endif

static BOOL isDebuggerAttached(void);

@interface ForkExecTask () {
    BOOL _launched;
}
@end

static char **alloc_argv(NSArray <NSString *>*arguments);
static void free_argv(char **argv);

@implementation ForkExecTask
@synthesize terminationStatus = _terminationStatus;

- (instancetype)init {
    return [super init];
}

+ (instancetype)launchedTaskWithLaunchPath:(NSString *)path arguments:(NSArray<NSString *> *)arguments {
    ForkExecTask *task = [[self alloc] init];
    task.launchPath = path;
    task.arguments = arguments;
    [task launch];
    return task;
}

#pragma mark Actions

- (void)launch {
    if (_launchPath == nil || _launched) return;
    _launched = YES;

    // Spawn child process
    pid_t pid = fork();

    if (pid == 0) {  // We're in the child

        if (self.reopenTTY) {
            if (!reopenStandardInputTTY()) {
                exit(1);
            }
        }

        // Build arguments
        NSArray *arguments = [@[ _launchPath ] arrayByAddingObjectsFromArray:_arguments];
        char *program = strdup(_launchPath.UTF8String);
        char **argv = alloc_argv(arguments);

        // Replace process
        execv(program, argv);

        // We only get here on error
        perror("Exec error");
        free(program);
        free_argv(argv);
        exit(1);
    } else if (pid < 0) { // There was an error
        perror("Fork error");
    } else { // We're in the parent
        _processIdentifier = pid;
    }
}

- (void)collectTerminationStatus:(BOOL)wait {
    if (_processIdentifier <= 0) return;

    int flags = wait ? 0 : WNOHANG;
    pid_t pid = waitpid(_processIdentifier, &_terminationStatus, flags);

    if (pid > 0) {
        _processIdentifier = 0;
    }
}

- (void)waitUntilExit {
    [self collectTerminationStatus:YES];
}

#pragma mark Status

- (BOOL)isRunning {
    if (!_launched) return NO;
    int status = kill(_processIdentifier, 0);
    return (status == 0);
}

- (int)terminationStatus {
    [self collectTerminationStatus:NO];
    return _terminationStatus;
}

- (NSTaskTerminationReason)terminationReason {
    if (WIFEXITED(_terminationStatus)) {
        return NSTaskTerminationReasonExit;
    } else if (WIFSIGNALED(_terminationStatus)) {
        return NSTaskTerminationReasonUncaughtSignal;
    }
    return 0;
}

@end

BOOL reopenStandardInputTTY(void) {
    int fd = open(_PATH_TTY, O_RDONLY);
    if (fd == -1) {
        perror("Failed to open TTY");
        return NO;
    } else {
        if (dup2(fd, STDIN_FILENO) == -1) {
            perror("Can't dup2 to stdin");
            close(fd);
            return NO;
        }
        close(fd);
        return YES;
    }
}

static char **alloc_argv(NSArray <NSString *>*arguments) {
    char **argv = calloc(arguments.count + 1, sizeof(char *));

    int i = 0;
    for (NSString *arg in arguments) {
        argv[i] = strdup(arg.UTF8String);
        i++;
    }

    return argv;
}

static void free_argv(char **argv) {
    if (argv == NULL) return;
    for (char **s = argv; *s != NULL; s++) {
        free(*s);
    }
    free(argv);
}

/**
 * Check if the debugger is attached
 *
 * Taken from https://github.com/plausiblelabs/plcrashreporter/blob/2dd862ce049e6f43feb355308dfc710f3af54c4d/Source/Crash%20Demo/main.m#L96
 *
 * @return `YES` if the debugger is attached to the current process, `NO` otherwise
 */
static BOOL isDebuggerAttached(void) {
    static BOOL debuggerIsAttached = NO;

    static dispatch_once_t debuggerPredicate;
    dispatch_once(&debuggerPredicate, ^{
        struct kinfo_proc info;
        size_t info_size = sizeof(info);
        int name[4];

        name[0] = CTL_KERN;
        name[1] = KERN_PROC;
        name[2] = KERN_PROC_PID;
        name[3] = getpid();

        if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
            //perror("Checking for a running debugger via sysctl() failed");
            debuggerIsAttached = NO;
        }

        if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
            debuggerIsAttached = YES;
    });

    return debuggerIsAttached;
}

@implementation ForkExecTask (Convenience)

+ (instancetype)launchVimWithArguments:(NSArray<NSString *> *)arguments reopenTTY:(BOOL)reopenTTY {
    BOOL hasTTY = isatty(fileno(stdin)) || reopenTTY;
    if (isDebuggerAttached() || !hasTTY) {
        return nil;
    }

    ForkExecTask *task = [[self alloc] init];
    task.launchPath = @"/usr/bin/vim";
    task.arguments = arguments;
    task.reopenTTY = reopenTTY;
    [task launch];

    if (task.isRunning) {
        return task;
    }
    return nil;
}

@end


