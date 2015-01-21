//
//  SMInviteToGroupPage.m
//  SMILES
//
//  Created by asepmoels on 8/23/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMInviteToGroupPage.h"
#import "MBProgressHUD.h"
#import "XMPPRosterCoreDataStorage.h"
#import "SMXMPPHandler.h"
#import "XMPPvCardTemp.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPRoom.h"
#import "SMPersistentObject.h"

@interface SMInviteToGroupPage ()<UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UITableView *table;
    
    NSMutableArray *friends;
    MBProgressHUD *loading;
}

-(IBAction)hideKeyboard:(id)sender;
-(IBAction)toggleCheckAll:(id)sender;
-(IBAction)send:(id)sender;
-(IBAction)back:(id)sender;

@end

@implementation SMInviteToGroupPage

@synthesize room;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *temans = [[NSMutableArray alloc] initWithArray:[[XMPPRosterCoreDataStorage sharedInstance] XMPPUserForXMPPStream:[SMXMPPHandler XMPPHandler].stream]];
    
    friends = [[NSMutableArray alloc] init];
    for(XMPPUserCoreDataStorageObject *user in temans){
        XMPPvCardTemp *temp = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:user.jid];
        
        if(([user.subscription isEqualToString:@"from"] || [user.subscription isEqualToString:@"none"]) && [user.ask isEqualToString:@"subscribe"]) // Approval pending...
            continue;
        
        if ([user.subscription isEqualToString:@"to"])  // block
            continue;

        NSString *name = @"";
        if(temp.givenName.length){
            if(temp.middleName.length){
                name = [NSString stringWithFormat:@"%@ %@ %@", temp.givenName, temp.middleName, (temp.familyName)?temp.familyName:@""];
            }else{
                name = [NSString stringWithFormat:@"%@ %@", temp.givenName, (temp.familyName)?temp.familyName:@""];
            }
        }else if(user.nickname.length)
            name = [NSString stringWithFormat:@"%@", user.nickname];
        else
            name = user.jid.user;
        
        UIImage *photo = user.photo;
        
        if(!photo){
            photo = [UIImage imageNamed:@"avatar_male.jpg"];
        }
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:YES], @"selected", photo, @"photo", name, @"name", user.jid, @"jid", nil];
        [friends addObject:dict];
    }
    [table reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - ACtion
-(void)toggleCheckAll:(UIButton *)sender{
    sender.selected = !sender.selected;
    
    for(NSMutableDictionary *dict in friends)
        [dict setValue:[NSNumber numberWithBool:sender.selected] forKey:@"selected"];
    
    [table reloadData];
}

-(void)hideKeyboard:(id)sender{
    //[messageField resignFirstResponder];
}

-(void)send:(id)sender{
    
    NSDictionary *dictInvite = [[SMPersistentObject sharedObject] fetchOnlyInviteAdmin:self.room.roomJID.user bare:self.room.roomJID.bare];

    for(NSMutableDictionary *dict in friends){
        if([[dict valueForKey:@"selected"] boolValue]){
//            NSString *messageBody = @"Please join to group. :)";
//            [self.room inviteUser:[dict valueForKey:@"jid"] withMessage:messageBody];

            XMPPJID *jid = [dict valueForKey:@"jid"];
            if (jid) {
                if (dictInvite && [dictInvite objectForKey:@"adminusername"] && [dictInvite objectForKey:@"onlyinviteadmin"]) {
                    [self.room inviteUser:jid withMessage:[NSString stringWithFormat:@"Please join to group. :)%@", [NSString stringWithFormat:@"info=%@|%d", [dictInvite objectForKey:@"adminusername"], [[dictInvite objectForKey:@"onlyinviteadmin"] boolValue]]]];
                } else {
                    [self.room inviteUser:jid withMessage:[NSString stringWithFormat:@"Please join to group. :)%@", [NSString stringWithFormat:@"info=%@|%d", [SMXMPPHandler XMPPHandler].myJID.user, YES]]];
                }
                
                NSLog(@"sent invitation to %@", jid.user);
            }
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - delegate dan data source table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return friends.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactcell"];
    
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"contactcell"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.font = [cell.textLabel.font fontWithSize:13.];
        
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check-list-unfocus.png"]];
        [imageView setHighlightedImage:[UIImage imageNamed:@"check-list-focus.png"]];
        cell.accessoryView = imageView;
        [imageView release];
    }
    
    NSDictionary *dict = [friends objectAtIndex:indexPath.row];
    cell.textLabel.text = [dict valueForKey:@"name"];
    cell.imageView.image = [dict valueForKey:@"photo"];
    
    UIImageView *img = (UIImageView *) cell.accessoryView;
    img.highlighted = [[dict valueForKey:@"selected"] boolValue];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableDictionary *dict = [friends objectAtIndex:indexPath.row];
    BOOL val = [[dict valueForKey:@"selected"] boolValue];
    [dict setValue:[NSNumber numberWithBool:!val] forKey:@"selected"];
    
    [tableView reloadData];
    [self hideKeyboard:nil];
}

@end
