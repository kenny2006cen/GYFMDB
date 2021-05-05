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
//@property (nonatomic, strong)   NSString  *    aliasName;//别名

/*链式语法*/
@property (nonatomic,copy) NSObject*(^select)();
@property (nonatomic,copy) NSObject*(^where)(NSString*);
@property (nonatomic,copy) NSObject*(^limit)(NSString*);
@property (nonatomic,copy) NSObject*(^offset)(NSString*);
@property (nonatomic,copy) NSObject*(^orderby)(NSString*);

@property (nonatomic,copy) NSObject*(^groupby)(NSString*);
@property (nonatomic,copy) NSObject*(^having)(NSString*);


@property (nonatomic,copy) NSObject*(^joinWithOn)(NSString*,NSString*);


@property (nonatomic,copy) NSMutableArray*(^runSql)();//默认返回数组

@property (nonatomic,copy) NSObject*(^findSql)();//默认返回一个对象

/*链式语法*/


#pragma mark- 数据库同步方法

+ (BOOL)createTable;

+ (BOOL)isExistInTable;

-(BOOL)save;

+ (BOOL)saveDBArray:(NSArray*)dataArray;

- (BOOL)deleteObject;

+ (BOOL)deleteALLObject;

+ (BOOL)deleteObjectsByCondition:(NSString *)condition;

- (BOOL)update;

- (BOOL)updateByCondition:(NSString *)condition;

#pragma mark- 仿MagicalRecord
+ (NSArray *)findAll;

+ (NSArray *)findByCondition:(NSString *)condition;

+ (NSArray *)findOrderBy:(NSString *)condition ascending:(BOOL)flag;

/*
 Person *person = [Person MR_findFirstByAttribute:@"FirstName"
 withValue:@"Forrest"];
 */
+ (id)findByAttribute:(NSString *)propertyName WithValue:(NSString*)value;

+ (id)findLastInDB;


//表中所有数量数量
+(NSInteger)countsOfItemInDB;
//表中某一字段求累加的和
+(NSInteger)sumOfItemInDB:(NSString*)itemName;

//表中某一字段在特定条件下求累加的和
+(NSInteger)sumOfItemInDB:(NSString*)itemName ByCondition:(NSString*)condition;

#pragma mark - 异步查询方法

/// Description 异步查询全部数据
/// @param block 返回所有当前对象类数组
+ (void)asyncFindAll:(void(^)(NSMutableArray * dbArr))block;

/// Description 异步查询条件数据列表
/// @param format 条件 例如：format = @ "where userId =1";
/// @param block 返回所有符合条件对象类数组
+ (void)asyncFindObjectsWithFormat:(NSString *)format block:(void(^)(NSMutableArray * dbArr))block;

/// 异步条件查询一条数据
/// @param format 查询条件
/// @param block 返回子类模型，需要强转为当前类型

+ (void)asyncFindFirstWithFormat:(NSString *)format block:(void(^)(NSObject * dbModel))block;


/// 根据主键升序查询第一个元素
/// @param block 返回model
+ (void)asyncFindFisrtOne:(void(^)(NSObject * dbModel))block;


/// 根据主键降序查询最后一个元素
/// @param block 返回model
+ (void)asyncFindLastOne:(void(^)(NSObject * dbModel))block;


/// Description 异步根据主键查询一条数据
/// @param pk 主键
/// @param block 返回子类模型，需要强转为当前类型
+ (void)asyncFindByPK:(int)pk block:(void(^)(NSObject * dbModel))block;


/// 异步查询条件下的总数量
/// @param format 格式化条件
/// @param block 返回数量
+ (void)asyncQueryCountOfTableWithFormat:(NSString *)format block:(void(^)(int))block;

/// 异步执行原始sql语句方法
/// @param sql 原始sql语句
/// @param block 返回是否完成，以及转换的sql对应Model
+ (void)asyncFindBySql:(NSString*)sql block:(void(^)(BOOL finished,NSMutableArray<NSObject*>*modelArr))block;


#pragma mark - PrimaryKey method
-(id)pk;
-(void)setPk:(id)pk;




#pragma mark - Base Func Method
//动态获取模型属性列表
-(NSArray *)attributePropertyList;

///动态属性字典
+ (NSDictionary *)getAllProperties;


/// 自定义表名
+ (NSString *)getTableName;

@end
