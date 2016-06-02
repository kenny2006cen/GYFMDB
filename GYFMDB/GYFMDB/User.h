//
//  User.h
//  GYFMDB
//
//  Created by User on 16/5/28.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserType.h"

@interface User : NSObject

@property(nonatomic,strong) NSNumber *userId;

@property(nonatomic,strong) NSString *userName;

@property(nonatomic,assign)BOOL isSend;

@property(nonatomic,assign)NSInteger age;

@property(nonatomic,assign)long long custId;

@property(nonatomic,strong) NSDate *date;

//@property(nonatomic,strong) Detail *detailModel;

@end
