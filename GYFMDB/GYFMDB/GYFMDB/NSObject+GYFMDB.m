//
//  NSObject+DBRunTimeSave.m
//  GYFMDB
//
//  Created by User on 16/5/28.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import <objc/runtime.h>
#import "GYFMDB.h"
#import "NSObject+GYFMDB.h"

static NSMutableString *gysql;

@implementation NSObject (GYFMDB)
@dynamic pk;

//+(void)initialize{
//
//    [[self class] createTable];
//}
//

/**
 *  返回属性列表 数组
 *
 *  @return @[@"userId",@"userName"]
 */
- (NSArray *)attributePropertyList {
  NSDictionary *dic = [[self class] getAllProperties];
  NSArray *array = [dic objectForKey:@"name"];
  return array;
}
/**
 *
 *
 *  @return 返回属性字典
    @{@"userName":@"NSString"}
 */

#pragma mark - base method
/**
 *  获取该类的所有属性,不包括主键和过滤字段
 */
+ (NSDictionary *)getPropertys {
  NSMutableArray *proNames = [NSMutableArray array];
  NSMutableArray *proTypes = [NSMutableArray array];

  NSArray *theTransients = [[self class] transients];

  unsigned int outCount, i;

  objc_property_t *properties = class_copyPropertyList([self class], &outCount);

  for (i = 0; i < outCount; i++) {
    objc_property_t property = properties[i];
    //获取属性名
    NSString *propertyName =
        [NSString stringWithCString:property_getName(property)
                           encoding:NSUTF8StringEncoding];

    if ([theTransients containsObject:propertyName]) {
      //拦截需要过滤的字段
      continue;
    }
    [proNames addObject:propertyName];
    //获取属性类型等参数
    NSString *propertyType =
        [NSString stringWithCString:property_getAttributes(property)
                           encoding:NSUTF8StringEncoding];
    /*
     c char         C unsigned char
     i int          I unsigned int
     l long         L unsigned long
     s short        S unsigned short
     d double       D unsigned double
     f float        F unsigned float
     q long long    Q unsigned long long
     B BOOL
     @ 对象类型 //指针 对象类型 如NSString 是@“NSString”


     64位下long 和long long 都是Tq
     SQLite 默认支持五种数据类型TEXT、INTEGER、REAL、BLOB、NULL
     */
    if ([propertyType hasPrefix:@"T@"]) {
      [proTypes addObject:SQLTEXT];
    } else if ([propertyType hasPrefix:@"Ti"] ||
               [propertyType hasPrefix:@"TI"] ||
               [propertyType hasPrefix:@"Ts"] ||
               [propertyType hasPrefix:@"TS"] ||
               [propertyType hasPrefix:@"TB"]) {
      [proTypes addObject:SQLINTEGER];
    } else {
      [proTypes addObject:SQLREAL];
    }
  }
  free(properties);

  return [NSDictionary
      dictionaryWithObjectsAndKeys:proNames, @"name", proTypes, @"type", nil];
}

/** 获取所有属性，包含主键pk */
+ (NSDictionary *)getAllProperties {
  NSDictionary *dict = [self.class getPropertys];

  NSMutableArray *proNames = [NSMutableArray array];
  NSMutableArray *proTypes = [NSMutableArray array];

  [proNames addObject:primaryId];
  [proTypes
      addObject:[NSString stringWithFormat:@"%@ %@", SQLINTEGER, PrimaryKey]];
  [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
  [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];

  return [NSDictionary
      dictionaryWithObjectsAndKeys:proNames, @"name", proTypes, @"type", nil];
}

#pragma mark - otherMethod
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients {
  return [NSArray arrayWithObject:@"aliasName"];
}

+ (NSString *)aliasName {
  NSString *tableName = NSStringFromClass(self.class);

  NSString *aliasName = tableName.lowercaseString;

  //统一小写全部字符做别名
  return aliasName;
}
// 增加数据映射字典
- (NSDictionary *)mapDic {
  return [NSDictionary new];
}

#pragma mark - DB method
+ (BOOL)createTable {
  FMDatabase *db = [GYFMDB sharedInstance].localDB;

  if (![db open]) {
    NSLog(@"数据库打开失败!");
    return NO;
  }

  NSString *tableName = NSStringFromClass(self.class);
  NSString *columeAndType = [self.class getColumeAndTypeString];
  NSString *sql =
      [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",
                                 tableName, columeAndType];
  if (![db executeUpdate:sql]) {
    return NO;
  }

  NSMutableArray *columns = [NSMutableArray array];
  FMResultSet *resultSet = [db getTableSchema:tableName];

  while ([resultSet next]) {
    NSString *column = [resultSet stringForColumn:@"name"];
    [columns addObject:column];
  }
  NSDictionary *dict = [self.class getAllProperties];

  NSArray *properties = [dict objectForKey:@"name"];

  NSPredicate *filterPredicate =
      [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", columns];
  //过滤数组
  NSArray *resultArray =
      [properties filteredArrayUsingPredicate:filterPredicate];

  for (NSString *column in resultArray) {
    NSUInteger index = [properties indexOfObject:column];
    NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
    NSString *fieldSql = [NSString stringWithFormat:@"%@ %@", column, proType];
    NSString *sql =
        [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",
                                   NSStringFromClass(self.class), fieldSql];
    if (![db executeUpdate:sql]) {
      return NO;
    }
  }
  [db close];
  return YES;
}

/** 数据库中是否存在表 */
+ (BOOL)isExistInTable {
  __block BOOL res = NO;

  GYFMDB *jkDB = [GYFMDB sharedInstance];

  [jkDB.dbQueue inDatabase:^(FMDatabase *db) {

    NSString *tableName = NSStringFromClass(self.class);
    res = [db tableExists:tableName];
  }];
  return res;
}

- (BOOL)save {
  //获取当前类名称，作为默认表名
  NSString *tableName = NSStringFromClass(self.class);

  NSMutableString *keyString = [NSMutableString string];
  NSMutableString *valueString = [NSMutableString string];
  NSMutableArray *insertValues = [NSMutableArray array];

  for (int i = 0; i < self.attributePropertyList.count; i++) {
    NSString *proname = [self.attributePropertyList objectAtIndex:i];

    if ([proname isEqualToString:primaryId]) {
      //插入时忽略主键
      continue;
    }
    [keyString appendFormat:@"%@,", proname];
    [valueString appendString:@"?,"];

    id value = [self valueForKey:proname];
    if (!value || [value isKindOfClass:[NSNull class]]) {
      value = @"";
    }
    [insertValues addObject:value];
  }

  [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1,
                                                 1)];  //删除最后一个符号
  [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];

  GYFMDB *jkDB = [GYFMDB sharedInstance];

  __block BOOL res = NO;

  [jkDB.dbQueue inDatabase:^(FMDatabase *db) {

    NSString *sql =
        [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);",
                                   tableName, keyString, valueString];

    res = [db executeUpdate:sql withArgumentsInArray:insertValues];

    int pk = res ? [NSNumber numberWithLongLong:db.lastInsertRowId].intValue
                 : 0;  //添加之后返回添加的实体的自增ID,db.lastInsertRowId

    self.pk = [NSNumber numberWithInt:pk];

    // self.pk = res?[NSNumber
    // numberWithLongLong:db.lastInsertRowId].intValue:0;//添加之后返回添加的实体的自增ID,db.lastInsertRowId

    NSLog(res ? @"插入成功" : @"插入失败");
  }];
  return res;
}

+ (BOOL)saveDBArray:(NSArray *)dataArray {
  __block BOOL res = NO;

  GYFMDB *jkDB = [GYFMDB sharedInstance];

  // 事务批量插入
  [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {

    for (id model in dataArray) {
      NSString *tableName = NSStringFromClass(self.class);
      NSMutableString *keyString = [NSMutableString string];
      NSMutableString *valueString = [NSMutableString string];
      NSMutableArray *insertValues = [NSMutableArray array];
      for (int i = 0; i < [[self class] columeNames].count; i++) {
        NSString *proname = [[[self class] columeNames] objectAtIndex:i];
        if ([proname isEqualToString:primaryId]) {
          continue;
        }
        [keyString appendFormat:@"%@,", proname];
        [valueString appendString:@"?,"];
        id value = [model valueForKey:proname];
        if (!value) {
          value = @"";
        }
        [insertValues addObject:value];
      }
      [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
      [valueString
          deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];

      NSString *sql =
          [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);",
                                     tableName, keyString, valueString];

      NSError *error;
      BOOL flag = [db executeUpdate:sql values:insertValues error:&error];

      //   BOOL flag = [db executeUpdate:sql withArgumentsInArray:insertValues];

      int pk =
          flag ? [NSNumber numberWithLongLong:db.lastInsertRowId].intValue : 0;

      self.pk = [NSNumber numberWithInt:pk];

      NSLog(flag ? @"批量插入成功" : @"批量插入失败");
      if (!flag) {
        res = NO;
        *rollback = YES;
        return;
      }
    }
  }];
  return res;
}

- (BOOL)update {
  GYFMDB *gydb = [GYFMDB sharedInstance];

  __block BOOL res = NO;

  [gydb.dbQueue inDatabase:^(FMDatabase *db) {

    NSString *tableName = NSStringFromClass(self.class);

    id primaryValue = [self valueForKey:primaryId];

    if (!primaryValue || primaryValue <= 0) {
      NSLog(@"没有主键值，无法更新!");

      return;
    }
    NSMutableString *keyString = [NSMutableString string];
    NSMutableArray *updateValues = [NSMutableArray array];

    for (int i = 0; i < self.attributePropertyList.count; i++) {
      NSString *proname = [self.attributePropertyList objectAtIndex:i];

      if ([proname isEqualToString:primaryId]) {
        continue;
      }
      [keyString appendFormat:@" %@=?,", proname];
      id value = [self valueForKey:proname];
      if (!value) {
        value = @"";
      }
      [updateValues addObject:value];
    }

    //删除最后那个逗号
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];

    NSString *sql =
        [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;", tableName,
                                   keyString, primaryId];
    [updateValues addObject:primaryValue];

    NSError *error;

    res = [db executeUpdate:sql values:updateValues error:&error];

    //   res = [db executeUpdate:sql withArgumentsInArray:updateValues];

    NSLog(res ? @"更新成功" : @"更新失败");
  }];
  return res;
}

- (BOOL)deleteObject {
  GYFMDB *gydb = [GYFMDB sharedInstance];

  __block BOOL res = NO;

  [gydb.dbQueue inDatabase:^(FMDatabase *db) {

    NSString *tableName = NSStringFromClass(self.class);
    id primaryValue = [self valueForKey:primaryId];

    if (!primaryValue || primaryValue <= 0) {
      NSLog(@"没有主键，无法删除!");
      return;
    }

    NSString *sql = [NSString
        stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", tableName, primaryId];
    NSError *error;

    res = [db executeUpdate:sql values:@[ primaryValue ] error:&error];

    NSLog(res ? @"删除成功" : @"删除失败");
  }];
  return res;
}

+ (BOOL)deleteObjectsByCondition:(NSString *)condition {
  return YES;
}

+ (BOOL)deleteALLObject {
  __block BOOL res = YES;

  GYFMDB *jkDB = [GYFMDB sharedInstance];
  // 如果要支持事务
  [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {

    NSString *tableName = NSStringFromClass(self.class);

    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", tableName];

    NSError *error;
    BOOL flag = [db executeUpdate:sql withErrorAndBindings:&error];

    NSLog(flag ? @"全部删除成功" : @"全部删除失败");
    if (!flag) {
      res = NO;
      *rollback = YES;
      return;
    }
  }];
  return res;
}

+ (NSArray *)findAll {
  GYFMDB *gydb = [GYFMDB sharedInstance];

  NSMutableArray *users = [NSMutableArray array];

  [gydb.dbQueue inDatabase:^(FMDatabase *db) {

    NSString *tableName = NSStringFromClass(self.class);
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
    FMResultSet *resultSet = [db executeQuery:sql];

    while ([resultSet next]) {
      id model = [[self.class alloc] init];

      NSDictionary *dic = [[self class] getAllProperties];

      NSMutableArray *columeNames =
          [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
      NSMutableArray *columeTypes =
          [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];

      for (int i = 0; i < columeNames.count; i++) {
        NSString *columeName = [columeNames objectAtIndex:i];
        NSString *columeType = [columeTypes objectAtIndex:i];

        if ([columeType isEqualToString:SQLTEXT]) {
          [model setValue:[resultSet stringForColumn:columeName]
                   forKey:columeName];
        } else {
          [model setValue:[NSNumber
                              numberWithLongLong:
                                  [resultSet longLongIntForColumn:columeName]]
                   forKey:columeName];
        }
      }
      [users addObject:model];
      FMDBRelease(model);
    }
  }];

  return users;
}
/**
 *
 *
 *  @param condition @"where pk =1 limit 1"
 *
 *  @return ModelArray
 */
+ (NSArray *)findByCondition:(NSString *)condition {
  GYFMDB *gydb = [GYFMDB sharedInstance];

  NSMutableArray *users = [NSMutableArray array];

  [gydb.dbQueue inDatabase:^(FMDatabase *db) {

    NSString *tableName = NSStringFromClass(self.class);
    NSString *sql = [NSString
        stringWithFormat:@"SELECT * FROM %@ %@", tableName, condition];

    NSDictionary *dic = [[self class] getAllProperties];

    NSMutableArray *columeNames =
        [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
    NSMutableArray *columeTypes =
        [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];

    FMResultSet *resultSet = [db executeQuery:sql];

    while ([resultSet next]) {
      id model = [[self.class alloc] init];

      for (int i = 0; i < columeNames.count; i++) {
        NSString *columeName = [columeNames objectAtIndex:i];
        NSString *columeType = [columeTypes objectAtIndex:i];
        if ([columeType isEqualToString:SQLTEXT]) {
          [model setValue:[resultSet stringForColumn:columeName]
                   forKey:columeName];
        } else {
          [model setValue:[NSNumber
                              numberWithLongLong:
                                  [resultSet longLongIntForColumn:columeName]]
                   forKey:columeName];
        }
      }
      [users addObject:model];
      FMDBRelease(model);
    }
  }];

  return users;
}

//默认按id找到最后一条
+ (id)findLastInDB {
  GYFMDB *gydb = [GYFMDB sharedInstance];

  NSMutableArray *users = [NSMutableArray array];

  id user = nil;

  [gydb.dbQueue inDatabase:^(FMDatabase *db) {

    NSString *tableName = NSStringFromClass(self.class);
    NSString *sql =
        [NSString stringWithFormat:@"SELECT * FROM %@ order by %@ desc limit 1",
                                   tableName, primaryId];

    FMResultSet *resultSet = [db executeQuery:sql];

    while ([resultSet next]) {
      id model = [[self.class alloc] init];

      NSDictionary *dic = [[self class] getAllProperties];

      NSMutableArray *columeNames =
          [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
      NSMutableArray *columeTypes =
          [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];

      for (int i = 0; i < columeNames.count; i++) {
        NSString *columeName = [columeNames objectAtIndex:i];
        NSString *columeType = [columeTypes objectAtIndex:i];

        if ([columeType isEqualToString:SQLTEXT]) {
          [model setValue:[resultSet stringForColumn:columeName]
                   forKey:columeName];
        } else {
          [model setValue:[NSNumber
                              numberWithLongLong:
                                  [resultSet longLongIntForColumn:columeName]]
                   forKey:columeName];
        }
      }
      [users addObject:model];
      FMDBRelease(model);
    }
  }];
  if (users.count > 0) {
    user = users[0];
  }
  return user;
}

+ (NSInteger)countsOfItemInDB {
  NSString *tableName = NSStringFromClass(self.class);

  NSString *sql =
      [NSString stringWithFormat:@"SELECT count(*) FROM %@", tableName];

  GYFMDB *gydb = [GYFMDB sharedInstance];

  __block NSInteger count = 0;

  [gydb.dbQueue inDatabase:^(FMDatabase *db) {

    count = [db intForQuery:sql];

  }];

  return count;
}

+ (NSInteger)sumOfItemInDB:(NSString *)itemName {
  NSString *tableName = NSStringFromClass(self.class);

  NSString *sql = [NSString
      stringWithFormat:@"SELECT sum(%@) FROM %@", itemName, tableName];

  GYFMDB *gydb = [GYFMDB sharedInstance];

  __block NSInteger count = 0;

  [gydb.dbQueue inDatabase:^(FMDatabase *db) {

    count = [db intForQuery:sql];

  }];

  return count;
}

+ (NSInteger)sumOfItemInDB:(NSString *)itemName
               ByCondition:(NSString *)condition {
  NSString *tableName = NSStringFromClass(self.class);

  NSString *sql = [NSString stringWithFormat:@"SELECT sum(%@) FROM %@ %@",
                                             itemName, tableName, condition];

  GYFMDB *gydb = [GYFMDB sharedInstance];

  __block NSInteger count = 0;

  [gydb.dbQueue inDatabase:^(FMDatabase *db) {

    count = [db intForQuery:sql];

  }];

  return count;
}

#pragma mark - Block method
- (NSObject * (^)())select {
  return ^() {
    //
    @synchronized(self) {
      if (!gysql || gysql.length > 0) {
        gysql = [NSMutableString new];
      }

      NSString *tableName = NSStringFromClass(self.class);

      //表的别名
      NSString *aliasName = [[self class] aliasName];
      // const char *  str= class_getName(self);

      // NSString * aliasName =
      NSString *sql = [NSString
          stringWithFormat:@"SELECT * FROM %@ %@ ", tableName, aliasName];

      [gysql appendString:sql];

      return self;
    }
  };
}

- (NSObject * (^)(NSString *))where {
  return ^(NSString *string) {
    //

    [gysql appendFormat:@" where %@", string];

    return self;
  };
}
- (NSObject * (^)(NSString *))limit {
  return ^(NSString *string) {
    //
    [gysql appendFormat:@" limit %@", string];

    return self;
  };
}

- (NSObject * (^)(NSString *))offset {
  return ^(NSString *string) {
    //
    [gysql appendFormat:@" limit %@", string];

    return self;
  };
}

- (NSObject * (^)(NSString *))orderby {
  return ^(NSString *string) {
    //
    [gysql appendFormat:@" orderby %@", string];

    return self;
  };
}
- (NSObject * (^)(NSString *))groupby {
  return ^(NSString *string) {
    //
    [gysql appendFormat:@" group %@", string];

    return self;
  };
}

- (NSObject * (^)(NSString *))having {
  return ^(NSString *string) {
    //
    [gysql appendFormat:@" having %@", string];

    return self;
  };
}
/*
- (NSObject*(^)(NSString*))join{

    return ^(NSString *string){
        //
      //  NSString *string =NSStringFromClass(class.class);

        Class joinClass = NSClassFromString(string);

        //默认小写返回别名
        NSString *joinClassAliasName = [joinClass aliasName];

        [gysql appendFormat:@"join %@ %@",string,joinClassAliasName];

        return self;
    };
}
*/
//暂时做2表连接
- (NSObject * (^)(NSString *, NSString *))joinWithOn {
  return ^(NSString *string, NSString *condition) {
    //
    //  NSString *string =NSStringFromClass(class.class);

    //连接的表名转换为类,调用类的别名生产方法
    Class joinClass = NSClassFromString(string);

    //默认小写返回别名
    NSString *joinClassAliasName = [joinClass aliasName];

    NSString *currentClassAliasName = [[self class] aliasName];

    NSArray *conditionArray = [condition componentsSeparatedByString:@"="];

    if (conditionArray.count <= 0) {
      NSLog(@"表达式条件错误");
      //表达式错误
      return self;
    }

    if (conditionArray.count > 2) {
      NSLog(@"暂不支持2张以上的表连接!");
      return self;
    }

    NSString *leftColumnName = conditionArray[0];
    NSString *rightColumnName = conditionArray[1];

    NSString *completeOnCondition = [NSString
        stringWithFormat:@"%@.%@=%@.%@", currentClassAliasName, leftColumnName,
                         joinClassAliasName, rightColumnName];

    [gysql appendFormat:@"join %@ %@ on %@", string, joinClassAliasName,
                        completeOnCondition];

    return self;
  };
}

/*
- (NSObject*(^)(NSString*))on{

    return ^(NSString *string){
        //
        [gysql appendFormat:@" on %@",string];

        return self;
    };
}
*/
- (NSMutableArray * (^)())runSql {
  return ^() {

    GYFMDB *gydb = [GYFMDB sharedInstance];

    __block NSMutableArray *users = [NSMutableArray array];

    [gydb.dbQueue inDatabase:^(FMDatabase *db) {

      NSString *sql = [NSString stringWithFormat:@"%@", gysql];

      NSDictionary *dic = [[self class] getAllProperties];

      NSMutableArray *columeNames =
          [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
      NSMutableArray *columeTypes =
          [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];

      FMResultSet *resultSet = [db executeQuery:sql];

      while ([resultSet next]) {
        id model = [[self.class alloc] init];

        for (int i = 0; i < columeNames.count; i++) {
          NSString *columeName = [columeNames objectAtIndex:i];
          NSString *columeType = [columeTypes objectAtIndex:i];

          if ([columeType isEqualToString:SQLTEXT]) {
            [model setValue:[resultSet stringForColumn:columeName]
                     forKey:columeName];
          } else {
            [model setValue:[NSNumber
                                numberWithLongLong:
                                    [resultSet longLongIntForColumn:columeName]]
                     forKey:columeName];
          }
        }
        [users addObject:model];
        FMDBRelease(model);
      }
    }];

    return users;
  };
}

#pragma mark - method
+ (NSString *)getColumeAndTypeString {
  NSMutableString *pars = [NSMutableString string];
  NSDictionary *dict = [self.class getAllProperties];

  NSMutableArray *proNames = [dict objectForKey:@"name"];
  NSMutableArray *proTypes = [dict objectForKey:@"type"];

  for (int i = 0; i < proNames.count; i++) {
    [pars appendFormat:@"%@ %@", [proNames objectAtIndex:i],
                       [proTypes objectAtIndex:i]];
    if (i + 1 != proNames.count) {
      [pars appendString:@","];
    }
  }
  return pars;
}

+ (NSArray *)columeNames {
  NSDictionary *dic = [[self class] getAllProperties];

  NSMutableArray *columeNames =
      [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];

  return columeNames;
}
+ (NSArray *)columeTypes {
  NSDictionary *dic = [[self class] getAllProperties];

  NSMutableArray *columeTypes =
      [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
  return columeTypes;
}

static const void *externVariableKey = &externVariableKey;
#pragma mark - RunTime set
- (id)pk {
  return objc_getAssociatedObject(self, externVariableKey);
}
- (void)setPk:(id)pk {
  objc_setAssociatedObject(self, externVariableKey, pk,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
