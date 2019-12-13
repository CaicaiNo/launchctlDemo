//
//  AppDelegate.m
//  launchctlDemo
//
//  Created by gensee on 2019/12/13.
//  Copyright © 2019年 sheng. All rights reserved.
//


// step 1 : 将com.haocaihaocai.task.plist移动到~/Library/LaunchAgents目录下，并执行sudo chmod 600给该文件添加权限
// step 2 : 将shelltask.sh移动到/tmp/目录下，并添加执行权限 sudo chmod 777
// step 3 : 执行工程

#import "AppDelegate.h"
#import <pwd.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
    NSString *_plistPath;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    BOOL isSandboxed = (nil != NSProcessInfo.processInfo.environment[@"APP_SANDBOX_CONTAINER_ID"]);
    NSString *_userHomeFolderPath;
    if (isSandboxed)
    {
        struct passwd *pw = getpwuid(getuid());
        assert(pw);
        _userHomeFolderPath = [NSString stringWithUTF8String:pw->pw_dir];
    }
    else
    {
        _userHomeFolderPath = NSHomeDirectory();
    }
    _plistPath = [_userHomeFolderPath stringByAppendingPathComponent:@"/Library/LaunchAgents/com.haocaihaocai.task.plist"];
}
- (IBAction)launchctlload:(id)sender {
    [self dolaunchctlCommands:[NSArray arrayWithObjects:@"launchctl",@"load",@"-w",_plistPath, nil]];
}
- (IBAction)launchctlunload:(id)sender {
    [self dolaunchctlCommands:[NSArray arrayWithObjects:@"launchctl",@"unload",@"-w",_plistPath, nil]];
}
- (IBAction)launchctlstart:(id)sender {
    //task is com.haocaihaocai.task in plist file
    [self dolaunchctlCommands:[NSArray arrayWithObjects:@"launchctl",@"start",@"com.haocaihaocai.task", nil]];
}

- (void)dolaunchctlCommands:(NSArray *)commands {
    
    NSString * output = nil;
    NSString * processErrorDescription = nil;
    BOOL success = [self runProcessAsAdministrator:@""
                                     withArguments:commands
                                            output:&output
                                  errorDescription:&processErrorDescription
                                   asAdministrator:NO];
    
    if (!success) // Process failed to run
    {
        // ...look at errorDescription
        NSLog(@"processErrorDescription %@",processErrorDescription.description);
    } else {
        // ...process output
        NSLog(@"output %@",output);
    }
}

//如果你的命令需要管理员权限，则设置isAmin=YES
- (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription
                   asAdministrator:(BOOL)isAdmin{
    
    NSString * allArgs = [arguments componentsJoinedByString:@" "];
    NSString * fullScript = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];
    
    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\" %@", fullScript,isAdmin?@"with administrator privileges":@""];
    
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor * eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    // Check errorInfo
    if (! eventResult)
    {
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber])
        {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }
        
        // Set error message from provided message
        if (*errorDescription == nil)
        {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
                *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        
        return NO;
    }
    else
    {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        
        return YES;
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
