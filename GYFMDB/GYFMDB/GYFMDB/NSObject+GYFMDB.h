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

@interface NSObject (GYFMDB)

/** 主键 id */
@property (nonatomic, strong)   NSNumber  *    pk;

/*链式语法*/
@property (nonatomic,copy) NSObject*(^select)();
@property (nonatomic,copy) NSObject*(^where)(NSString*);
@property (nonatomic,copy) NSObject*(^limit)(NSString*);
@property (nonatomic,copy) NSObject*(^offset)(NSString*);
@property (nonatomic,copy) NSObject*(^orderby)(NSString*);

@property (nonatomic,copy) NSObject*(^runSql)(NSString*);

/*链式语法*/

//动态获取模型属性列表
-(NSArray *)attributePropertyList;

+ (NSDictionary *)getAllProperties;

+ (BOOL)createTable;

+ (BOOL)isExistInTable;

-(BOOL)save;

+ (BOOL)saveDBArray:(NSArray*)dataArray;

- (BOOL)deleteObject;

+ (BOOL)deleteALLObject;

+ (BOOL)deleteObjectsByCondition:(NSString *)condition;

- (BOOL)update;

- (BOOL)updateByCondition:(NSString *)condition;

+ (NSArray *)findAll;

+ (NSArray *)findByCondition:(NSString *)condition;

+ (NSArray *)findOrderBy:(NSString *)condition ascending:(BOOL)flag;

/*
 Person *person = [Person MR_findFirstByAttribute:@"FirstName"
 withValue:@"Forrest"];
 */
+ (id)findByAttribute:(NSString *)propertyName WithValue:(NSString*)value;

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
