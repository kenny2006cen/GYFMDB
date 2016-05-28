//
//  ViewController.m
//  GYFMDB
//
//  Created by User on 16/5/27.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import "ViewController.h"
#import "GYFMDB/GYFMDB.h"
#import "User.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    User *user =[[User alloc]init];
    
    user.userId=@1;
    user.userName=@"jack";
    
    
    [[GYFMDB sharedInstance]createTableWithName:@"User" ColumnNameFromModel:user];
}
- (IBAction)insert:(id)sender {
}
- (IBAction)delete:(id)sender {
}
- (IBAction)select:(id)sender {
}
- (IBAction)selectByKey:(id)sender {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
