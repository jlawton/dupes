//
//  ForkExecTask.m
//  dupes
//
//  Created by James Lawton on 4/1/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>

#import "ForkExecTask.h"

@interface ForkExecTask () {
    BOOL _launched;
}
@end

static char **alloc_argv(NSArray <NSString *>*arguments);
static void free_argv(char **argv);

@implementation ForkExecTask

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
        exit(0);
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
        if (WIFEXITED(_terminationStatus)) {
            _terminationReason = NSTaskTerminationReasonExit;
        } else if (WIFSIGNALED(_terminationStatus)) {
            _terminationReason = NSTaskTerminationReasonUncaughtSignal;
        }
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

@end

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

@implementation ForkExecTask (Convenience)

+ (instancetype)launchVimWithArguments:(NSArray<NSString *> *)arguments {
    if (!isatty(fileno(stdin)) || !isatty(fileno(stdout))) {
        return nil;
    }

    ForkExecTask *task = [self launchedTaskWithLaunchPath:@"/usr/bin/vim" arguments:arguments];
    if (task.isRunning) {
        return task;
    }
    return nil;
}

@end


