#import "HADevicePickerViewController.h"

@interface HADevicePickerViewController ()
@property(nonatomic, retain) NSArray *allEntities;
@property(nonatomic, retain) NSArray *visibleEntities;
@property(nonatomic, retain) UISearchBar *searchBar;
@end

@implementation HADevicePickerViewController

@synthesize delegate = _delegate;
@synthesize allEntities = _allEntities;
@synthesize visibleEntities = _visibleEntities;
@synthesize searchBar = _searchBar;

- (id)initWithEntities:(NSArray *)entities {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.allEntities = entities;
        self.visibleEntities = entities;
        self.preferredContentSize = CGSizeMake(540.0, 620.0);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add Devices";
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                             target:self
                             action:@selector(cancel:)] autorelease];
    self.searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)] autorelease];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchBar.placeholder = @"Search devices";
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.visibleEntities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"HADevicePickerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:identifier] autorelease];
    }
    NSDictionary *entity = [self.visibleEntities objectAtIndex:indexPath.row];
    NSDictionary *attributes = [entity objectForKey:@"attributes"];
    cell.textLabel.text = [attributes objectForKey:@"friendly_name"] ?: [entity objectForKey:@"entity_id"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ — %@",
        [entity objectForKey:@"entity_id"], [entity objectForKey:@"state"] ?: @"unknown"];
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    addButton.frame = CGRectMake(0, 0, 44.0, 44.0);
    addButton.tag = indexPath.row;
    [addButton addTarget:self action:@selector(addDevice:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = addButton;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *entityID = [[self.visibleEntities objectAtIndex:indexPath.row] objectForKey:@"entity_id"];
    [self.delegate devicePicker:self didAddEntityID:entityID];
}

- (void)addDevice:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)[self.visibleEntities count]) {
        return;
    }
    NSString *entityID = [[self.visibleEntities objectAtIndex:sender.tag] objectForKey:@"entity_id"];
    [self.delegate devicePicker:self didAddEntityID:entityID];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0) {
        self.visibleEntities = self.allEntities;
    } else {
        NSMutableArray *matches = [NSMutableArray array];
        for (NSDictionary *entity in self.allEntities) {
            NSDictionary *attributes = [entity objectForKey:@"attributes"];
            NSString *name = [attributes objectForKey:@"friendly_name"] ?: @"";
            NSString *entityID = [entity objectForKey:@"entity_id"] ?: @"";
            if ([name rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [entityID rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [matches addObject:entity];
            }
        }
        self.visibleEntities = matches;
    }
    [self.tableView reloadData];
}

- (void)cancel:(id)sender {
    [self.delegate devicePickerDidCancel:self];
}

- (void)dealloc {
    _searchBar.delegate = nil;
    [_searchBar release];
    [_visibleEntities release];
    [_allEntities release];
    [super dealloc];
}

@end
