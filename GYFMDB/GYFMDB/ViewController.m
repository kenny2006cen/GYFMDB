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
#import "NSObject+DBRunTimeSave.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
   // [[GYFMDB sharedInstance]createTableWithName:@"User" ColumnNameFromModel:[User new]];
}
- (IBAction)insert:(id)sender {
    
    User *user =[[User alloc]init];
    
    user.userId=@2;
    user.userName=@"jack33";
    
    [user save];
    
   // [[GYFMDB sharedInstance]insertModel:user ToTable:@"User"];
    
    //获取绑定的 Model 并 保存 Model 的属性信息
  
}
- (IBAction)delete:(id)sender {
    
    User *user =[[User alloc]init];
    
   //  user.userId=@1;
  //   user.userName=@"jack222";
    user.pk = @2;
    
    [user deleteObject];
    
  //  [[GYFMDB sharedInstance]deleteModel:user FromTable:@"User" ByCondition:@"userName" EqualsTo:@"jack222"];
}
- (IBAction)select:(id)sender {
    
  NSArray* array=[User findAll];
    
    for ( User *user in array) {
    
        NSLog(@"主键:%@",user.pk);
    }
    
//  NSArray *array = [[GYFMDB sharedInstance]queryModels:[User class] FromTable:@"User"];
//    
//    for ( User *user in array) {
//        
//        NSLog(@"user.userName =%@",user.userName);
//    }
}
- (IBAction)selectByKey:(id)sender {
    
    NSLog(@"property Dic =%@",[User getAllProperties]);
    
    User *user =[[User alloc]init];
    
    //  user.userId=@1;
    user.userName=@"jack888";
    
    [user save];

}

- (IBAction)update:(id)sender {
    
    User *user =[[User alloc]init];
    
  //  user.userId=@1;
    user.userName=@"jack333";
    
    [[GYFMDB sharedInstance]updateModel:user FromTable:@"User" ByCondition:@"userName" EqualsTo:@"jack222"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
