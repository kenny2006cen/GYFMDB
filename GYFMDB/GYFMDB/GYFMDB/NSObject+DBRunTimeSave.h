//
//  NSObject+DBRunTimeSave.h
//  GYFMDB
//
//  Created by User on 16/5/28.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ObjectNULL @"NULL"
#define ObjectINT  @"INTEGER"
#define ObjectREAL @"REAL"
#define ObjectTEXT @"TEXT"
#define ObjectBLOB @"BLOB"
#define ObjectDATETIME @"DATETIME"

#define PRIMARY_KEY     @"Id"

@interface NSObject (DBRunTimeSave)

//动态获取模型属性列表
-(NSArray *)attributePropertyList;

-(NSDictionary*)mapDic;//类型映射字典
@end
