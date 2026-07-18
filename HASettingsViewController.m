#import "HASettingsViewController.h"
#import "HAAuthClient.h"
#import "HAEntityListViewController.h"
#import "HAHomeManager.h"
#import "HAVerificationViewController.h"
#import "HAURLCompatibility.h"

@interface HASettingsViewController () <HAAuthClientDelegate, HAVerificationViewControllerDelegate>
@property(nonatomic, retain) UITextField *baseURLField;
@property(nonatomic, retain) UITextField *homeNameField;
@property(nonatomic, retain) UITextField *usernameField;
@property(nonatomic, retain) UITextField *passwordField;
@property(nonatomic, retain) UIButton *connectButton;
@property(nonatomic, retain) UILabel *statusLabel;
@property(nonatomic, retain) HAAuthClient *authClient;
@property(nonatomic, retain) UINavigationController *verificationNavigationController;
@property(nonatomic, assign) BOOL addingHome;
@end


@implementation HASettingsViewController

@synthesize delegate = _delegate;
@synthesize baseURLField = _baseURLField;
@synthesize homeNameField = _homeNameField;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize connectButton = _connectButton;
@synthesize statusLabel = _statusLabel;
@synthesize authClient = _authClient;
@synthesize verificationNavigationController = _verificationNavigationController;
@synthesize addingHome = _addingHome;

- (id)initForAddingHome {
    self = [super init];
    if (self) {
        self.addingHome = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.addingHome ? @"Add Home" : @"Home Assistant";
    self.view.backgroundColor = [UIColor whiteColor];

    self.homeNameField = [self fieldWithFrame:CGRectZero placeholder:@"Home name"];
    self.baseURLField = [self fieldWithFrame:CGRectZero placeholder:@"https://home.example.com"];
    self.usernameField = [self fieldWithFrame:CGRectZero placeholder:@"Username"];
    self.passwordField = [self fieldWithFrame:CGRectZero placeholder:@"Password"];
    self.passwordField.secureTextEntry = YES;
    if (!self.addingHome) {
        self.baseURLField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"HABaseURL"];
    }
    [self.view addSubview:self.homeNameField];
    [self.view addSubview:self.baseURLField];
    [self.view addSubview:self.usernameField];
    [self.view addSubview:self.passwordField];

    self.connectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.connectButton setTitle:@"Sign in" forState:UIControlStateNormal];
    [self.connectButton addTarget:self action:@selector(connect:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.connectButton];

    self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.statusLabel.backgroundColor = [UIColor clearColor];
    self.statusLabel.font = [UIFont systemFontOfSize:14.0];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat maximumWidth = 560.0;
    CGFloat horizontalMargin = 24.0;
    CGFloat width = MIN(self.view.bounds.size.width - horizontalMargin * 2.0, maximumWidth);
    CGFloat left = floor((self.view.bounds.size.width - width) / 2.0);
    CGFloat top = MAX(24.0, floor((self.view.bounds.size.height - 312.0) / 3.0));
    self.homeNameField.frame = CGRectMake(left, top, width, 42.0);
    self.baseURLField.frame = CGRectMake(left, top + 52.0, width, 42.0);
    self.usernameField.frame = CGRectMake(left, top + 104.0, width, 42.0);
    self.passwordField.frame = CGRectMake(left, top + 156.0, width, 42.0);
    self.connectButton.frame = CGRectMake(left, top + 212.0, width, 48.0);
    self.statusLabel.frame = CGRectMake(left, top + 268.0, width, 44.0);
}

- (UITextField *)fieldWithFrame:(CGRect)frame placeholder:(NSString *)placeholder {
    UITextField *field = [[[UITextField alloc] initWithFrame:frame] autorelease];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.placeholder = placeholder;
    field.delegate = self;
    return field;
}

- (void)connect:(id)sender {
    NSURL *url = HAURLWithString(self.baseURLField.text);
    if (url == nil || [url scheme] == nil || [url host] == nil) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Invalid URL"
                                                        message:@"Enter a complete http:// or https:// URL."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] autorelease];
        [alert show];
        return;
    }
    if ([self.usernameField.text length] == 0 || [self.passwordField.text length] == 0) {
        self.statusLabel.textColor = [UIColor redColor];
        self.statusLabel.text = @"Enter your Home Assistant username and password.";
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.baseURLField.text forKey:@"HABaseURL"];
    [defaults removeObjectForKey:@"HAToken"];
    [defaults removeObjectForKey:@"HANotificationURL"];
    [defaults synchronize];
    self.connectButton.enabled = NO;
    self.statusLabel.textColor = [UIColor darkGrayColor];
    self.statusLabel.text = @"Signing in…";
    self.authClient = [[[HAAuthClient alloc] initWithBaseURLString:self.baseURLField.text] autorelease];
    self.authClient.delegate = self;
    [self.authClient authenticateUsername:self.usernameField.text password:self.passwordField.text];
}

- (void)authClient:(HAAuthClient *)client didAuthenticateWithAccessToken:(NSString *)accessToken {
    self.passwordField.text = nil;
    self.connectButton.enabled = YES;
    self.statusLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.1 alpha:1.0];
    self.statusLabel.text = @"Signed in successfully.";
    NSDictionary *home = [HAHomeManager saveHomeWithName:self.homeNameField.text
                                           baseURLString:self.baseURLField.text
                                             accessToken:accessToken
                                            refreshToken:[[NSUserDefaults standardUserDefaults]
                                                stringForKey:@"HARefreshToken"]];
    if (self.addingHome) {
        [self.delegate settingsViewController:self didAddHome:home];
    } else {
        HAEntityListViewController *controller = [[[HAEntityListViewController alloc]
            initWithBaseURLString:self.baseURLField.text accessToken:accessToken] autorelease];
        [self.navigationController setViewControllers:[NSArray arrayWithObject:controller] animated:YES];
    }
}

- (void)authClient:(HAAuthClient *)client didRequestVerificationCodeWithMessage:(NSString *)message {
    self.statusLabel.text = @"Waiting for two-factor verification…";
    HAVerificationViewController *controller = [[[HAVerificationViewController alloc]
        initWithMessage:message] autorelease];
    controller.delegate = self;
    self.verificationNavigationController = [[[UINavigationController alloc]
        initWithRootViewController:controller] autorelease];
    self.verificationNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:self.verificationNavigationController animated:YES completion:nil];
}

- (void)verificationViewController:(HAVerificationViewController *)controller
                     didSubmitCode:(NSString *)code {
    self.statusLabel.text = @"Verifying code…";
    [self dismissViewControllerAnimated:YES completion:nil];
    self.verificationNavigationController = nil;
    [self.authClient submitVerificationCode:code];
}

- (void)verificationViewControllerDidCancel:(HAVerificationViewController *)controller {
    self.connectButton.enabled = YES;
    self.statusLabel.text = @"Sign-in cancelled.";
    [self dismissViewControllerAnimated:YES completion:nil];
    self.verificationNavigationController = nil;
    self.authClient = nil;
}

- (void)authClient:(HAAuthClient *)client didFailWithMessage:(NSString *)message {
    self.passwordField.text = nil;
    self.connectButton.enabled = YES;
    self.statusLabel.textColor = [UIColor redColor];
    self.statusLabel.text = message;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)dealloc {
    [_homeNameField release];
    [_baseURLField release];
    [_usernameField release];
    [_passwordField release];
    [_connectButton release];
    [_statusLabel release];
    HAVerificationViewController *verificationController =
        (HAVerificationViewController *)[_verificationNavigationController topViewController];
    verificationController.delegate = nil;
    [_verificationNavigationController release];
    _authClient.delegate = nil;
    [_authClient release];
    [super dealloc];
}

@end
