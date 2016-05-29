//
//  NSObject+DBRunTimeSave.h
//  GYFMDB
//
//  Created by User on 16/5/28.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SQLTEXT     @"TEXT"
#define SQLINTEGER  @"INTEGER"
#define SQLREAL     @"REAL"
#define SQLBLOB     @"BLOB"
#define SQLNULL     @"NULL"

#define PrimaryKey  @"primary key"

#define primaryId     @"pk"

@interface NSObject (DBRunTimeSave)

/** 主键 id */
@property (nonatomic, strong)   NSNumber  *    pk;
/** 列名 */
//@property (retain, readonly, nonatomic) NSMutableArray         *columeNames;
///** 列类型 */
//@property (retain, readonly, nonatomic) NSMutableArray         *columeTypes;

//动态获取模型属性列表
-(NSArray *)attributePropertyList;

-(NSString*)getPrimaryId;

-(void)setPrimaryId:(NSString*)idString;

+ (NSDictionary *)getAllProperties;

-(BOOL)save;

- (BOOL)deleteObject;

+ (NSArray *)findAll;

/** 通过主键查询 */
+ (instancetype)findByPK:(int)inPk;

-(id)pk;
-(void)setPk:(id)pk;
@end
