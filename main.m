#import <UIKit/UIKit.h>
#import "HAAppDelegate.h"

static void HARecordUncaughtException(NSException *exception) {
    NSString *report = [NSString stringWithFormat:@"Name: %@\nReason: %@\nStack: %@\n",
        [exception name], [exception reason], [[exception callStackSymbols] componentsJoinedByString:@"\n"]];
    [report writeToFile:@"/tmp/HALegacy-last-exception.txt"
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:nil];
}

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSSetUncaughtExceptionHandler(&HARecordUncaughtException);
    int result = UIApplicationMain(argc, argv, nil, NSStringFromClass([HAAppDelegate class]));
    [pool drain];
    return result;
}
