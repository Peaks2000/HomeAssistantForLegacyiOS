#import "HAAppDelegate.h"
#import "HAEntityListViewController.h"
#import "HASettingsViewController.h"

@implementation HAAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    NSString *baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"HABaseURL"];
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"HAAccessToken"];
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

    return YES;
}

- (void)dealloc {
    [_navigationController release];
    [_window release];
    [super dealloc];
}

@end
