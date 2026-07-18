#import "HAHomesViewController.h"
#import "HAHomeManager.h"
#import "HASettingsViewController.h"

@interface HAHomesViewController () <HASettingsViewControllerDelegate>
@property(nonatomic, retain) NSArray *homes;
@end

@implementation HAHomesViewController

@synthesize delegate = _delegate;
@synthesize homes = _homes;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Homes";
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(done:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                             target:self
                             action:@selector(addHome:)] autorelease];
    self.homes = [HAHomeManager homes];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.homes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"HAHomeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:identifier] autorelease];
    }
    NSDictionary *home = [self.homes objectAtIndex:indexPath.row];
    cell.textLabel.text = [home objectForKey:HAHomeNameKey];
    cell.detailTextLabel.text = [home objectForKey:HAHomeBaseURLKey];
    cell.accessoryType = [[[HAHomeManager selectedHome] objectForKey:HAHomeIdentifierKey]
        isEqualToString:[home objectForKey:HAHomeIdentifierKey]]
        ? UITableViewCellAccessoryCheckmark
        : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *home = [self.homes objectAtIndex:indexPath.row];
    [HAHomeManager selectHomeWithIdentifier:[home objectForKey:HAHomeIdentifierKey]];
    [self.delegate homesViewControllerDidChooseHome:[HAHomeManager selectedHome]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    NSDictionary *removedHome = [self.homes objectAtIndex:indexPath.row];
    BOOL removedSelectedHome = [[removedHome objectForKey:HAHomeIdentifierKey]
        isEqualToString:[[HAHomeManager selectedHome] objectForKey:HAHomeIdentifierKey]];
    [HAHomeManager removeHomeWithIdentifier:[removedHome objectForKey:HAHomeIdentifierKey]];
    self.homes = [HAHomeManager homes];
    [self.tableView reloadData];
    if (removedSelectedHome) {
        [self.delegate homesViewControllerDidChooseHome:[HAHomeManager selectedHome]];
    }
}

- (void)addHome:(id)sender {
    HASettingsViewController *settings = [[[HASettingsViewController alloc] initForAddingHome] autorelease];
    settings.delegate = self;
    [self.navigationController pushViewController:settings animated:YES];
}

- (void)settingsViewController:(HASettingsViewController *)controller didAddHome:(NSDictionary *)home {
    self.homes = [HAHomeManager homes];
    [self.delegate homesViewControllerDidChooseHome:home];
}

- (void)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [_homes release];
    [super dealloc];
}

@end
