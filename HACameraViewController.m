#import "HACameraViewController.h"
#import "HAURLCompatibility.h"

@interface HACameraViewController ()
@property(nonatomic, retain) NSDictionary *entity;
@property(nonatomic, copy) NSString *baseURLString;
@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, retain) UIImageView *imageView;
@property(nonatomic, retain) UILabel *statusLabel;
@property(nonatomic, retain) NSTimer *refreshTimer;
@property(nonatomic, retain) NSURLConnection *connection;
@property(nonatomic, retain) NSMutableData *imageData;
@end

@implementation HACameraViewController

@synthesize entity = _entity;
@synthesize baseURLString = _baseURLString;
@synthesize accessToken = _accessToken;
@synthesize imageView = _imageView;
@synthesize statusLabel = _statusLabel;
@synthesize refreshTimer = _refreshTimer;
@synthesize connection = _connection;
@synthesize imageData = _imageData;

- (id)initWithEntity:(NSDictionary *)entity baseURLString:(NSString *)baseURLString
          accessToken:(NSString *)accessToken {
    self = [super init];
    if (self) {
        self.entity = entity;
        self.baseURLString = baseURLString;
        self.accessToken = accessToken;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.title = [[self.entity objectForKey:@"attributes"] objectForKey:@"friendly_name"] ?: @"Camera";
    self.imageView = [[[UIImageView alloc] initWithFrame:self.view.bounds] autorelease];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    self.statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)] autorelease];
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.text = @"Connecting to camera…";
    [self.view addSubview:self.statusLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadFrame:nil];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self
        selector:@selector(loadFrame:) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
    [self.connection cancel];
    self.connection = nil;
}

- (void)loadFrame:(NSTimer *)timer {
    if (self.connection != nil) return;
    NSString *entityID = [self.entity objectForKey:@"entity_id"];
    NSString *path = [NSString stringWithFormat:@"/api/camera_proxy/%@?time=%.0f", entityID,
        [[NSDate date] timeIntervalSince1970] * 1000.0];
    NSMutableURLRequest *request = HAMutableURLRequestWithURL(
        HAURLWithString([self.baseURLString stringByAppendingString:path]));
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken]
        forHTTPHeaderField:@"Authorization"];
    self.imageData = [NSMutableData data];
    self.connection = HAStartURLConnection(request, self);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    UIImage *image = [UIImage imageWithData:self.imageData];
    if (image != nil) {
        self.imageView.image = image;
        self.statusLabel.hidden = YES;
    } else {
        self.statusLabel.text = @"Camera image unavailable";
    }
    self.connection = nil;
    self.imageData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.statusLabel.hidden = NO;
    self.statusLabel.text = [NSString stringWithFormat:@"Camera failed: %@", [error localizedDescription]];
    self.connection = nil;
    self.imageData = nil;
}

- (void)dealloc {
    [_refreshTimer invalidate];
    [_refreshTimer release];
    [_connection cancel];
    [_connection release];
    [_imageData release];
    [_imageView release];
    [_statusLabel release];
    [_entity release];
    [_baseURLString release];
    [_accessToken release];
    [super dealloc];
}

@end
