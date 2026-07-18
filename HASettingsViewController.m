#import "HASettingsViewController.h"
#import "HAAuthClient.h"
#import "HAEntityListViewController.h"
#import "HAVerificationViewController.h"

@interface HASettingsViewController () <HAAuthClientDelegate, HAVerificationViewControllerDelegate>
@property(nonatomic, retain) UITextField *baseURLField;
@property(nonatomic, retain) UITextField *usernameField;
@property(nonatomic, retain) UITextField *passwordField;
@property(nonatomic, retain) UIButton *connectButton;
@property(nonatomic, retain) UILabel *statusLabel;
@property(nonatomic, retain) HAAuthClient *authClient;
@property(nonatomic, retain) UINavigationController *verificationNavigationController;
@end


@implementation HASettingsViewController

@synthesize baseURLField = _baseURLField;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize connectButton = _connectButton;
@synthesize statusLabel = _statusLabel;
@synthesize authClient = _authClient;
@synthesize verificationNavigationController = _verificationNavigationController;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Home Assistant";
    self.view.backgroundColor = [UIColor whiteColor];

    self.baseURLField = [self fieldWithFrame:CGRectZero placeholder:@"https://home.example.com"];
    self.usernameField = [self fieldWithFrame:CGRectZero placeholder:@"Username"];
    self.passwordField = [self fieldWithFrame:CGRectZero placeholder:@"Password"];
    self.passwordField.secureTextEntry = YES;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.baseURLField.text = [defaults stringForKey:@"HABaseURL"];
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
    CGFloat top = MAX(32.0, floor((self.view.bounds.size.height - 260.0) / 3.0));
    self.baseURLField.frame = CGRectMake(left, top, width, 42.0);
    self.usernameField.frame = CGRectMake(left, top + 52.0, width, 42.0);
    self.passwordField.frame = CGRectMake(left, top + 104.0, width, 42.0);
    self.connectButton.frame = CGRectMake(left, top + 160.0, width, 48.0);
    self.statusLabel.frame = CGRectMake(left, top + 216.0, width, 44.0);
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
    NSURL *url = [NSURL URLWithString:self.baseURLField.text];
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
    HAEntityListViewController *controller = [[[HAEntityListViewController alloc]
        initWithBaseURLString:self.baseURLField.text accessToken:accessToken] autorelease];
    [self.navigationController setViewControllers:[NSArray arrayWithObject:controller] animated:YES];
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
