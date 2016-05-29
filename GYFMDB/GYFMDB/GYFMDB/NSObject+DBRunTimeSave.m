//
//  NSObject+DBRunTimeSave.m
//  GYFMDB
//
//  Created by User on 16/5/28.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import "NSObject+DBRunTimeSave.h"
#import <objc/runtime.h>
#import "GYFMDB.h"

@implementation NSObject (DBRunTimeSave)
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
-(NSArray *)attributePropertyList{
    
    NSDictionary *dic = [[self class]getAllProperties];
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
+ (NSDictionary *)getPropertys
{
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
   
    NSArray *theTransients = [[self class] transients];
   
    unsigned int outCount, i;
   
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
    
        objc_property_t property = properties[i];
        //获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
    
        if ([theTransients containsObject:propertyName]) {
            continue;
        }
        [proNames addObject:propertyName];
        //获取属性类型等参数
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
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
        }
        else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]) {
            [proTypes addObject:SQLINTEGER];
        }
        else {
            [proTypes addObject:SQLREAL];
        }
        
    }
    free(properties);
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
}

/** 获取所有属性，包含主键pk */
+ (NSDictionary *)getAllProperties
{
    NSDictionary *dict = [self.class getPropertys];
    
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
   
    [proNames addObject:primaryId];
    [proTypes addObject:[NSString stringWithFormat:@"%@ %@",SQLINTEGER,PrimaryKey]];
    [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
}

#pragma mark - must be override method
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients
{
    return [NSArray array];
}

#pragma mark - DB method
+ (BOOL)createTable
{
    FMDatabase *db = [GYFMDB sharedInstance].localDB;
    
    if (![db open]) {
        NSLog(@"数据库打开失败!");
        return NO;
    }
    
    NSString *tableName = NSStringFromClass(self.class);
    NSString *columeAndType = [self.class getColumeAndTypeString];
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",tableName,columeAndType];
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
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
    //过滤数组
    NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
    
    for (NSString *column in resultArray) {
        NSUInteger index = [properties indexOfObject:column];
        NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
        NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass(self.class),fieldSql];
        if (![db executeUpdate:sql]) {
            return NO;
        }
    }
    [db close];
    return YES;
}


-(BOOL)save{
    
    NSString *tableName = NSStringFromClass(self.class);
  
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    
    
    for (int i = 0; i < self.attributePropertyList.count; i++) {
        NSString *proname = [self.attributePropertyList objectAtIndex:i];
        
        if ([proname isEqualToString:primaryId]) {
            //插入时忽略主键
            continue;
        }
        [keyString appendFormat:@"%@,", proname];
        [valueString appendString:@"?,"];
     
        id value = [self valueForKey:proname];
        if (!value||[value isKindOfClass:[NSNull class]]) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];//删除最后一个符号
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    GYFMDB *jkDB = [GYFMDB sharedInstance];
  
    __block BOOL res = NO;
   
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
      
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
     
        res = [db executeUpdate:sql withArgumentsInArray:insertValues];
     
        int pk = res?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;//添加之后返回添加的实体的自增ID,db.lastInsertRowId
       
        self.pk =[NSNumber numberWithInt:pk];
        
       // self.pk = res?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;//添加之后返回添加的实体的自增ID,db.lastInsertRowId
        
        NSLog(res?@"插入成功":@"插入失败");
    }];
    return res;

}

- (BOOL)update
{
    GYFMDB *gydb = [GYFMDB sharedInstance];
    
    __block BOOL res = NO;
    
    [gydb.dbQueue inDatabase:^(FMDatabase *db) {
     
        NSString *tableName = NSStringFromClass(self.class);
     
        id primaryValue = [self valueForKey:primaryId];
     
        if (!primaryValue || primaryValue <= 0) {
            NSLog(@"没有主键值，无法更新!");
            
            return ;
        }
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *updateValues = [NSMutableArray  array];
       
        for (int i = 0; i <self.attributePropertyList.count; i++) {
          
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
    
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;", tableName, keyString, primaryId];
        [updateValues addObject:primaryValue];
      
        NSError *error;
        
        res = [db executeUpdate:sql values:updateValues error:&error];
        
     //   res = [db executeUpdate:sql withArgumentsInArray:updateValues];
        
        NSLog(res?@"更新成功":@"更新失败");
    }];
    return res;
}

- (BOOL)deleteObject
{
    GYFMDB *gydb = [GYFMDB sharedInstance];
    
    __block BOOL res = NO;
    
    [gydb.dbQueue inDatabase:^(FMDatabase *db) {
     
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:primaryId];
      
        if (!primaryValue || primaryValue <= 0) {
            NSLog(@"没有主键，无法删除!");
            return ;
        }
//        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
        NSError *error;
        
       res =[db executeUpdate:sql values:@[primaryValue] error:&error];
        
      //  res = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
      
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}


+(NSArray*)findAll{
    
    GYFMDB *gydb = [GYFMDB sharedInstance];
    
    NSMutableArray *users = [NSMutableArray array];
    
    [gydb.dbQueue inDatabase:^(FMDatabase *db) {
      
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        FMResultSet *resultSet = [db executeQuery:sql];
     
        while ([resultSet next]) {
            
            id model = [[self.class alloc] init];
       
            NSDictionary *dic =[[self class]getAllProperties];
            
           NSMutableArray* columeNames = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
            NSMutableArray* columeTypes = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
            
            for (int i=0; i< columeNames.count; i++) {
                
                NSString *columeName = [columeNames objectAtIndex:i];
                NSString *columeType = [columeTypes objectAtIndex:i];
                
                if ([columeType isEqualToString:SQLTEXT]) {
                   
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                } else {
                  
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
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
+ (NSArray *)findByCondition:(NSString *)condition{

    GYFMDB *gydb = [GYFMDB sharedInstance];
    
    NSMutableArray *users = [NSMutableArray array];
   
    [gydb.dbQueue inDatabase:^(FMDatabase *db) {
        
            NSString *tableName = NSStringFromClass(self.class);
            NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,condition];

        NSDictionary *dic =[[self class]getAllProperties];

        NSMutableArray* columeNames = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
        NSMutableArray* columeTypes = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
        
        FMResultSet *resultSet = [db executeQuery:sql];
        
        while ([resultSet next]) {
                id model = [[self.class alloc] init];
                
                for (int i=0; i< columeNames.count; i++) {
                    NSString *columeName = [columeNames objectAtIndex:i];
                    NSString *columeType = [columeTypes objectAtIndex:i];
                    if ([columeType isEqualToString:SQLTEXT]) {
                        [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                    } else {
                        [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                    }
                }
                [users addObject:model];
                FMDBRelease(model);
            }
        }];
        
        return users;

}

#pragma mark - util method
+ (NSString *)getColumeAndTypeString
{
    NSMutableString* pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllProperties];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i=0; i< proNames.count; i++) {
        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if(i+1 != proNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}


static const void * externVariableKey =&externVariableKey;
#pragma mark - RunTime set
-(id)pk{
    return objc_getAssociatedObject(self, externVariableKey);
}
-(void)setPk:(id)pk{
    objc_setAssociatedObject(self, externVariableKey, pk, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
