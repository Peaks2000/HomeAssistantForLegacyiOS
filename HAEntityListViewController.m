#import "HAEntityListViewController.h"
#import "HADevicePickerViewController.h"
#import "HACameraViewController.h"
#import "HAEntityDetailViewController.h"
#import "HAHomeManager.h"
#import "HAHomesViewController.h"
#import "HASettingsViewController.h"
#import "HAURLCompatibility.h"

@interface HAEntityListViewController () <NSURLConnectionDataDelegate, UISearchBarDelegate,
    HADevicePickerViewControllerDelegate, HAHomesViewControllerDelegate>
@property(nonatomic, copy) NSString *baseURLString;
@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, retain) NSArray *entities;
@property(nonatomic, retain) NSArray *allEntities;
@property(nonatomic, retain) UISegmentedControl *viewSelector;
@property(nonatomic, retain) UISearchBar *searchBar;
@property(nonatomic, copy) NSString *searchText;
@property(nonatomic, retain) UINavigationController *devicePickerNavigationController;
@property(nonatomic, retain) UINavigationController *homesNavigationController;
@property(nonatomic, retain) NSMutableData *responseData;
@property(nonatomic, retain) NSURLConnection *connection;
@property(nonatomic, assign) NSInteger statusCode;
@end

@implementation HAEntityListViewController

@synthesize baseURLString = _baseURLString;
@synthesize accessToken = _accessToken;
@synthesize entities = _entities;
@synthesize allEntities = _allEntities;
@synthesize viewSelector = _viewSelector;
@synthesize searchBar = _searchBar;
@synthesize searchText = _searchText;
@synthesize devicePickerNavigationController = _devicePickerNavigationController;
@synthesize homesNavigationController = _homesNavigationController;
@synthesize responseData = _responseData;
@synthesize connection = _connection;
@synthesize statusCode = _statusCode;

- (id)initWithBaseURLString:(NSString *)baseURLString accessToken:(NSString *)accessToken {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        while ([baseURLString hasSuffix:@"/"]) {
            baseURLString = [baseURLString substringToIndex:[baseURLString length] - 1];
        }
        self.baseURLString = baseURLString;
        self.accessToken = accessToken;
        self.entities = [NSArray array];
        self.allEntities = [NSArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Home Assistant";
    self.viewSelector = [[[UISegmentedControl alloc] initWithItems:
        [NSArray arrayWithObjects:@"My Devices", @"All Devices", nil]] autorelease];
    self.viewSelector.selectedSegmentIndex = 0;
    [self.viewSelector addTarget:self action:@selector(viewSelectionChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.viewSelector;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"⌂"
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(showHomes:)] autorelease];
    [self updateNavigationButton];
    self.searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)] autorelease];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchBar.placeholder = @"Search all devices";
    self.searchBar.delegate = self;
    [self refresh:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateVisibleEntities];
}

- (void)refresh:(id)sender {
    [self.connection cancel];
    NSURL *url = HAURLWithString([self.baseURLString stringByAppendingString:@"/api/states"]);
    NSMutableURLRequest *request = HAMutableURLRequestWithURL(url);
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken]
        forHTTPHeaderField:@"Authorization"];
    self.responseData = [NSMutableData data];
    self.connection = HAStartURLConnection(request, self);
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.responseData setLength:0];
    self.statusCode = [response respondsToSelector:@selector(statusCode)]
        ? [(id)response statusCode]
        : 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.connection = nil;
    if (self.statusCode == 401) {
        [self showError:@"Your session expired. Sign in again."];
        return;
    }
    NSError *error = nil;
    id response = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&error];
    self.responseData = nil;
    if (![response isKindOfClass:[NSArray class]]) {
        [self showError:@"Home Assistant returned an unreadable entity list."];
        return;
    }
    self.allEntities = [response sortedArrayUsingComparator:^NSComparisonResult(id first, id second) {
        return [[self displayNameForEntity:first] localizedCaseInsensitiveCompare:[self displayNameForEntity:second]];
    }];
    [self updateVisibleEntities];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.connection = nil;
    self.responseData = nil;
    [self showError:[NSString stringWithFormat:@"Connection failed: %@", [error localizedDescription]]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.entities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"HAEntityCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:identifier] autorelease];
    }
    NSDictionary *entity = [self.entities objectAtIndex:indexPath.row];
    cell.textLabel.text = [self displayNameForEntity:entity];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ — %@",
        [entity objectForKey:@"entity_id"] ?: @"Unknown entity",
        [entity objectForKey:@"state"] ?: @"unknown"];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.viewSelector.selectedSegmentIndex == 0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.viewSelector.selectedSegmentIndex == 0
        ? UITableViewCellEditingStyleDelete
        : UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete ||
        self.viewSelector.selectedSegmentIndex != 0 ||
        indexPath.row >= (NSInteger)[self.entities count]) {
        return;
    }
    NSString *entityID = [[self.entities objectAtIndex:indexPath.row] objectForKey:@"entity_id"];
    NSMutableArray *selectedIDs = [NSMutableArray arrayWithArray:[HAHomeManager selectedEntityIDs]];
    [selectedIDs removeObject:entityID];
    [HAHomeManager setSelectedEntityIDs:selectedIDs];
    [self updateVisibleEntities];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *entity = [self.entities objectAtIndex:indexPath.row];
    NSString *entityID = [entity objectForKey:@"entity_id"];
    if ([entityID hasPrefix:@"camera."]) {
        HACameraViewController *camera = [[[HACameraViewController alloc]
            initWithEntity:entity baseURLString:self.baseURLString accessToken:self.accessToken] autorelease];
        [self.navigationController pushViewController:camera animated:YES];
        return;
    }
    HAEntityDetailViewController *controller = [[[HAEntityDetailViewController alloc]
        initWithEntity:entity baseURLString:self.baseURLString accessToken:self.accessToken] autorelease];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)viewSelectionChanged:(UISegmentedControl *)sender {
    [self updateNavigationButton];
    self.tableView.tableHeaderView = sender.selectedSegmentIndex == 1 ? self.searchBar : nil;
    if (sender.selectedSegmentIndex == 0) {
        self.searchText = nil;
        self.searchBar.text = nil;
    }
    [self updateVisibleEntities];
}

- (void)addDevice:(id)sender {
    NSArray *favorites = [HAHomeManager selectedEntityIDs];
    NSMutableArray *available = [NSMutableArray array];
    for (NSDictionary *entity in self.allEntities) {
        if (![favorites containsObject:[entity objectForKey:@"entity_id"]]) {
            [available addObject:entity];
        }
    }
    HADevicePickerViewController *picker = [[[HADevicePickerViewController alloc]
        initWithEntities:available] autorelease];
    picker.delegate = self;
    self.devicePickerNavigationController = [[[UINavigationController alloc]
        initWithRootViewController:picker] autorelease];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.devicePickerNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    } else {
        self.devicePickerNavigationController.modalPresentationStyle = UIModalPresentationPageSheet;
        self.devicePickerNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    [self presentViewController:self.devicePickerNavigationController animated:YES completion:nil];
}

- (void)devicePicker:(HADevicePickerViewController *)picker didAddEntityID:(NSString *)entityID {
    NSMutableArray *favorites = [NSMutableArray arrayWithArray:[HAHomeManager selectedEntityIDs]];
    if (![favorites containsObject:entityID]) {
        [favorites addObject:entityID];
        [HAHomeManager setSelectedEntityIDs:favorites];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    self.devicePickerNavigationController = nil;
    [self updateVisibleEntities];
}

- (void)devicePickerDidCancel:(HADevicePickerViewController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.devicePickerNavigationController = nil;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchText = searchText;
    [self updateVisibleEntities];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)updateNavigationButton {
    if (self.viewSelector.selectedSegmentIndex == 0) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                 target:self
                                 action:@selector(addDevice:)] autorelease];
    } else {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                 target:self
                                 action:@selector(refresh:)] autorelease];
    }
}

- (void)updateVisibleEntities {
    if (self.viewSelector.selectedSegmentIndex == 1) {
        if ([self.searchText length] == 0) {
            self.entities = self.allEntities;
        } else {
            NSMutableArray *matches = [NSMutableArray array];
            for (NSDictionary *entity in self.allEntities) {
                NSDictionary *attributes = [entity objectForKey:@"attributes"];
                NSString *name = [attributes objectForKey:@"friendly_name"] ?: @"";
                NSString *entityID = [entity objectForKey:@"entity_id"] ?: @"";
                if ([name rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound ||
                    [entityID rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    [matches addObject:entity];
                }
            }
            self.entities = matches;
        }
    } else {
        NSArray *favorites = [HAHomeManager selectedEntityIDs];
        NSMutableArray *selected = [NSMutableArray array];
        for (NSDictionary *entity in self.allEntities) {
            if ([favorites containsObject:[entity objectForKey:@"entity_id"]]) {
                [selected addObject:entity];
            }
        }
        self.entities = selected;
    }
    [self.tableView reloadData];
}

- (NSString *)displayNameForEntity:(NSDictionary *)entity {
    NSDictionary *attributes = [entity objectForKey:@"attributes"];
    NSString *friendlyName = [attributes objectForKey:@"friendly_name"];
    return [friendlyName length] > 0 ? friendlyName : [entity objectForKey:@"entity_id"];
}

- (void)showHomes:(id)sender {
    HAHomesViewController *homes = [[[HAHomesViewController alloc] initWithStyle:UITableViewStyleGrouped]
        autorelease];
    homes.delegate = self;
    self.homesNavigationController = [[[UINavigationController alloc]
        initWithRootViewController:homes] autorelease];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.homesNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    } else {
        self.homesNavigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    [self presentViewController:self.homesNavigationController animated:YES completion:nil];
}

- (void)homesViewControllerDidChooseHome:(NSDictionary *)home {
    [self dismissViewControllerAnimated:YES completion:nil];
    HAHomesViewController *homes = (HAHomesViewController *)
        [[self.homesNavigationController viewControllers] objectAtIndex:0];
    homes.delegate = nil;
    self.homesNavigationController = nil;
    UIViewController *controller = nil;
    if (home == nil) {
        controller = [[[HASettingsViewController alloc] init] autorelease];
    } else {
        controller = [[[HAEntityListViewController alloc]
            initWithBaseURLString:[home objectForKey:HAHomeBaseURLKey]
                      accessToken:[home objectForKey:HAHomeAccessTokenKey]] autorelease];
    }
    [self.navigationController setViewControllers:[NSArray arrayWithObject:controller] animated:NO];
}

- (void)showError:(NSString *)message {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Home Assistant"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil] autorelease];
    [alert show];
}

- (void)dealloc {
    [_connection cancel];
    [_connection release];
    [_responseData release];
    [_entities release];
    [_allEntities release];
    [_viewSelector release];
    _searchBar.delegate = nil;
    [_searchBar release];
    [_searchText release];
    HADevicePickerViewController *picker =
        (HADevicePickerViewController *)[_devicePickerNavigationController topViewController];
    picker.delegate = nil;
    [_devicePickerNavigationController release];
    HAHomesViewController *homes = (HAHomesViewController *)
        [[_homesNavigationController viewControllers] objectAtIndex:0];
    homes.delegate = nil;
    [_homesNavigationController release];
    [_baseURLString release];
    [_accessToken release];
    [super dealloc];
}

@end
