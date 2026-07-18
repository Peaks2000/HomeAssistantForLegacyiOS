#import "HAEntityDetailViewController.h"
#import "HACameraViewController.h"
#import "HAHomeManager.h"
#import "HAURLCompatibility.h"

@interface HAEntityDetailViewController () <NSURLConnectionDataDelegate>
@property(nonatomic, retain) NSDictionary *entity;
@property(nonatomic, copy) NSString *baseURLString;
@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, retain) UILabel *stateLabel;
@property(nonatomic, retain) UISlider *brightnessSlider;
@property(nonatomic, retain) NSMutableData *responseData;
@property(nonatomic, retain) NSURLConnection *connection;
@end

@implementation HAEntityDetailViewController

@synthesize entity = _entity;
@synthesize baseURLString = _baseURLString;
@synthesize accessToken = _accessToken;
@synthesize stateLabel = _stateLabel;
@synthesize brightnessSlider = _brightnessSlider;
@synthesize responseData = _responseData;
@synthesize connection = _connection;

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
    self.view.backgroundColor = [UIColor whiteColor];
    NSDictionary *attributes = [self.entity objectForKey:@"attributes"];
    self.title = [attributes objectForKey:@"friendly_name"] ?: [self.entity objectForKey:@"entity_id"];
    self.stateLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.stateLabel.textAlignment = NSTextAlignmentCenter;
    self.stateLabel.font = [UIFont boldSystemFontOfSize:22.0];
    self.stateLabel.text = [NSString stringWithFormat:@"State: %@", [self.entity objectForKey:@"state"] ?: @"unknown"];
    [self.view addSubview:self.stateLabel];
    [self buildControlsForDomain:[self entityDomain]];
}

- (void)buildControlsForDomain:(NSString *)domain {
    if ([domain isEqualToString:@"camera"]) {
        [self addButtonWithTitle:@"View Camera" action:@selector(viewCamera:) tag:0];
        return;
    }
    if ([domain isEqualToString:@"cover"]) {
        [self addButtonWithTitle:@"Open" action:@selector(coverAction:) tag:1];
        [self addButtonWithTitle:@"Stop" action:@selector(coverAction:) tag:2];
        [self addButtonWithTitle:@"Close" action:@selector(coverAction:) tag:3];
        return;
    }
    if ([domain isEqualToString:@"lock"]) {
        [self addButtonWithTitle:@"Lock" action:@selector(lockAction:) tag:1];
        [self addButtonWithTitle:@"Unlock" action:@selector(lockAction:) tag:2];
        return;
    }
    if ([domain isEqualToString:@"light"]) {
        [self addButtonWithTitle:@"Turn On / Off" action:@selector(toggle:) tag:0];
        self.brightnessSlider = [[[UISlider alloc] initWithFrame:CGRectZero] autorelease];
        self.brightnessSlider.minimumValue = 1.0;
        self.brightnessSlider.maximumValue = 100.0;
        id brightness = [[self.entity objectForKey:@"attributes"] objectForKey:@"brightness"];
        self.brightnessSlider.value = [brightness respondsToSelector:@selector(floatValue)]
            ? [brightness floatValue] * 100.0 / 255.0
            : 50.0;
        [self.brightnessSlider addTarget:self action:@selector(brightnessChanged:)
                        forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        [self.view addSubview:self.brightnessSlider];
        [self addButtonWithTitle:@"Red" action:@selector(colorSelected:) tag:1];
        [self addButtonWithTitle:@"Green" action:@selector(colorSelected:) tag:2];
        [self addButtonWithTitle:@"Blue" action:@selector(colorSelected:) tag:3];
        [self addButtonWithTitle:@"White" action:@selector(colorSelected:) tag:4];
        return;
    }
    if ([domain isEqualToString:@"scene"] || [domain isEqualToString:@"script"] ||
        [domain isEqualToString:@"button"] || [domain isEqualToString:@"automation"]) {
        [self addButtonWithTitle:@"Run" action:@selector(runAction:) tag:0];
        return;
    }
    [self addButtonWithTitle:@"Turn On / Off" action:@selector(toggle:) tag:0];
}

- (UIButton *)addButtonWithTitle:(NSString *)title action:(SEL)action tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.tag = tag;
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    return button;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = MIN(self.view.bounds.size.width - 48.0, 560.0);
    CGFloat left = floor((self.view.bounds.size.width - width) / 2.0);
    self.stateLabel.frame = CGRectMake(left, 80, width, 40);
    CGFloat top = 140.0;
    for (UIView *view in self.view.subviews) {
        if (view == self.stateLabel) continue;
        view.frame = CGRectMake(left, top, width, [view isKindOfClass:[UISlider class]] ? 44.0 : 48.0);
        top += 58.0;
    }
}

- (NSString *)entityDomain {
    return [[[self.entity objectForKey:@"entity_id"] componentsSeparatedByString:@"."] objectAtIndex:0];
}

- (void)toggle:(id)sender {
    [self callService:@"toggle" domain:@"homeassistant" additionalData:nil];
}

- (void)coverAction:(UIButton *)sender {
    NSArray *services = [NSArray arrayWithObjects:@"", @"open_cover", @"stop_cover", @"close_cover", nil];
    [self callService:[services objectAtIndex:sender.tag] domain:@"cover" additionalData:nil];
}

- (void)lockAction:(UIButton *)sender {
    [self callService:sender.tag == 1 ? @"lock" : @"unlock" domain:@"lock" additionalData:nil];
}

- (void)runAction:(id)sender {
    NSString *domain = [self entityDomain];
    [self callService:[domain isEqualToString:@"button"] ? @"press" : @"turn_on" domain:domain additionalData:nil];
}

- (void)brightnessChanged:(UISlider *)slider {
    [self callService:@"turn_on" domain:@"light" additionalData:
        [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:(int)slider.value] forKey:@"brightness_pct"]];
}

- (void)colorSelected:(UIButton *)sender {
    NSArray *colors = [NSArray arrayWithObjects:
        [NSArray arrayWithObjects:@255, @0, @0, nil],
        [NSArray arrayWithObjects:@0, @255, @0, nil],
        [NSArray arrayWithObjects:@0, @0, @255, nil],
        [NSArray arrayWithObjects:@255, @255, @255, nil], nil];
    [self callService:@"turn_on" domain:@"light" additionalData:
        [NSDictionary dictionaryWithObject:[colors objectAtIndex:sender.tag - 1] forKey:@"rgb_color"]];
}

- (void)viewCamera:(id)sender {
    HACameraViewController *controller = [[[HACameraViewController alloc]
        initWithEntity:self.entity baseURLString:self.baseURLString accessToken:self.accessToken] autorelease];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)callService:(NSString *)service domain:(NSString *)domain additionalData:(NSDictionary *)additionalData {
    NSString *savedAccessToken = [HAHomeManager accessTokenForBaseURLString:self.baseURLString];
    if ([savedAccessToken length] > 0) {
        self.accessToken = savedAccessToken;
    }
    NSString *path = [NSString stringWithFormat:@"/api/services/%@/%@", domain, service];
    NSMutableURLRequest *request = HAMutableURLRequestWithURL(
        HAURLWithString([self.baseURLString stringByAppendingString:path]));
    request.HTTPMethod = @"POST";
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithObject:[self.entity objectForKey:@"entity_id"]
                                                                    forKey:@"entity_id"];
    if (additionalData != nil) {
        [body addEntriesFromDictionary:additionalData];
    }
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken]
        forHTTPHeaderField:@"Authorization"];
    self.responseData = [NSMutableData data];
    self.connection = HAStartURLConnection(request, self);
    self.stateLabel.text = @"Sending command…";
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.connection = nil;
    self.responseData = nil;
    self.stateLabel.text = @"Command sent";
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.connection = nil;
    self.responseData = nil;
    self.stateLabel.text = [NSString stringWithFormat:@"Failed: %@", [error localizedDescription]];
}

- (void)dealloc {
    [_connection cancel];
    [_connection release];
    [_responseData release];
    [_brightnessSlider release];
    [_stateLabel release];
    [_entity release];
    [_baseURLString release];
    [_accessToken release];
    [super dealloc];
}

@end
