#import "HAAppDelegate.h"
#import "HAEntityListViewController.h"
#import "HAHomeManager.h"
#import "HASettingsViewController.h"
#import "HAWatchManager.h"

@implementation HAAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    NSDictionary *selectedHome = [HAHomeManager selectedHome];
    NSString *baseURL = [selectedHome objectForKey:HAHomeBaseURLKey];
    NSString *accessToken = [selectedHome objectForKey:HAHomeAccessTokenKey];
    UIViewController *root = nil;
    if ([baseURL length] > 0 && [accessToken length] > 0) {
        root = [[[HAEntityListViewController alloc] initWithBaseURLString:baseURL
                                                              accessToken:accessToken] autorelease];
    } else {
        root = [[[HASettingsViewController alloc] init] autorelease];
    }
    self.navigationController = [[[UINavigationController alloc] initWithRootViewController:root] autorelease];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    [[HAWatchManager sharedManager] start];

    return YES;
}

- (void)dealloc {
    [_navigationController release];
    [_window release];
    [super dealloc];
}

@end
