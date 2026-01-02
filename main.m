// Copyright (c) 2026 by Tad McCorkle
// Licensed under the MIT license.

#import <Cocoa/Cocoa.h>

#define CFG_PATH @".config/launchguard/launchguard.conf"

@interface LaunchGuard : NSObject
- (void)handleApplicationLaunch:(NSNotification *)notification;
@end

@implementation LaunchGuard

- (void)handleApplicationLaunch:(NSNotification *)notification {
  NSRunningApplication *app  = notification.userInfo[NSWorkspaceApplicationKey];
  NSString *bundleIdentifier = [app bundleIdentifier];

  NSError *error           = nil;
  NSString *configPath     = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), CFG_PATH];
  NSString *configContents = [NSString stringWithContentsOfFile:configPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];

  if (error) {
    NSLog(@"launchguard: Failed to read config. %@", error);
    return;
  }

  NSMutableSet *blockedApps = [NSMutableSet set];
  NSArray *lines            = [configContents componentsSeparatedByString:@"\n"];
  NSCharacterSet *ws        = [NSCharacterSet whitespaceAndNewlineCharacterSet];

  for (NSString *line in lines) {
    NSString *trimmed = [line stringByTrimmingCharactersInSet:ws];
    if ([trimmed length] > 0 && ![trimmed hasPrefix:@"#"]) {
      [blockedApps addObject:trimmed];
    }
  }

  if ([blockedApps containsObject:bundleIdentifier]) {
    [app forceTerminate];
  }
}

@end

int
main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSWorkspace *ws          = [NSWorkspace sharedWorkspace];
    NSNotificationCenter *nc = [ws notificationCenter];
    LaunchGuard *launchguard = [[LaunchGuard alloc] init];

    [nc addObserver:launchguard
           selector:@selector(handleApplicationLaunch:)
               name:NSWorkspaceWillLaunchApplicationNotification
             object:nil];

    [[NSRunLoop currentRunLoop] run];
  }

  return 0;
}
