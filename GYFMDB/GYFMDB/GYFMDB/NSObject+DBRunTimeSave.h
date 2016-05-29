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

#define primaryId     @"pk" //主键字段

@interface NSObject (DBRunTimeSave)

/** 主键 id */
@property (nonatomic, strong)   NSNumber  *    pk;
/** 列名 */
//@property (retain, readonly, nonatomic) NSMutableArray         *columeNames;
///** 列类型 */
//@property (retain, readonly, nonatomic) NSMutableArray         *columeTypes;

//动态获取模型属性列表
-(NSArray *)attributePropertyList;

+ (NSDictionary *)getAllProperties;

+ (BOOL)createTable;

-(BOOL)save;

+ (BOOL)saveDBArray:(NSArray*)dataArray;

- (BOOL)deleteObject;

+ (BOOL)deleteALLObject;

+ (BOOL)deleteObjectsByCondition:(NSString *)condition;

- (BOOL)update;

+ (NSArray *)findAll;

+ (NSArray *)findByCondition:(NSString *)condition;

+ (id)findLastInDB;

//为属性增加索引
+(void)addIndex:(NSString*)propertyName;

//表中所有数量数量
+(NSInteger)countsOfItemInDB;
//表中某一字段求累加的和
+(NSInteger)sumOfItemInDB:(NSString*)itemName;

//表中某一字段在特定条件下求累加的和
+(NSInteger)sumOfItemInDB:(NSString*)itemName ByCondition:(NSString*)condition;

-(id)pk;
-(void)setPk:(id)pk;
@end
