#import "HAVerificationViewController.h"

@interface HAVerificationViewController ()
@property(nonatomic, copy) NSString *verificationMessage;
@property(nonatomic, retain) UILabel *messageLabel;
@property(nonatomic, retain) UITextField *codeField;
@property(nonatomic, retain) UIButton *verifyButton;
@end


@implementation HAVerificationViewController

@synthesize delegate = _delegate;
@synthesize verificationMessage = _verificationMessage;
@synthesize messageLabel = _messageLabel;
@synthesize codeField = _codeField;
@synthesize verifyButton = _verifyButton;

- (id)initWithMessage:(NSString *)message {
    self = [super init];
    if (self) {
        self.verificationMessage = message;
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Verification";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                             target:self
                             action:@selector(cancel:)] autorelease];

    self.messageLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.messageLabel.backgroundColor = [UIColor clearColor];
    self.messageLabel.font = [UIFont systemFontOfSize:17.0];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.text = self.verificationMessage;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.messageLabel];

    self.codeField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
    self.codeField.borderStyle = UITextBorderStyleRoundedRect;
    self.codeField.font = [UIFont systemFontOfSize:24.0];
    self.codeField.keyboardType = UIKeyboardTypeNumberPad;
    self.codeField.placeholder = @"Verification code";
    self.codeField.textAlignment = NSTextAlignmentCenter;
    self.codeField.delegate = self;
    [self.view addSubview:self.codeField];

    self.verifyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.verifyButton setTitle:@"Verify" forState:UIControlStateNormal];
    [self.verifyButton addTarget:self action:@selector(verify:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.verifyButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.codeField becomeFirstResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = MIN(self.view.bounds.size.width - 48.0, 420.0);
    CGFloat left = floor((self.view.bounds.size.width - width) / 2.0);
    CGFloat top = MAX(28.0, floor((self.view.bounds.size.height - 210.0) / 3.0));
    self.messageLabel.frame = CGRectMake(left, top, width, 70.0);
    self.codeField.frame = CGRectMake(left, top + 82.0, width, 52.0);
    self.verifyButton.frame = CGRectMake(left, top + 148.0, width, 48.0);
}

- (void)verify:(id)sender {
    if ([self.codeField.text length] == 0) {
        return;
    }
    [self.delegate verificationViewController:self didSubmitCode:self.codeField.text];
}

- (void)cancel:(id)sender {
    [self.delegate verificationViewControllerDidCancel:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self verify:textField];
    return YES;
}

- (void)dealloc {
    _codeField.delegate = nil;
    [_codeField release];
    [_messageLabel release];
    [_verifyButton release];
    [_verificationMessage release];
    [super dealloc];
}

@end
