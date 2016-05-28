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

-(NSMutableDictionary *)attributeProrertyDic{
    unsigned int count = 0;
  
    Ivar *ivars = class_copyIvarList([self class], &count);
    
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (int i = 0; i<count; i++) {
        
        // 取出i位置对应的成员变量
        Ivar ivar = ivars[i];
        
        // 查看成员变量
        const char *name = ivar_getName(ivar);
       
       const char *type = ivar_getTypeEncoding(ivar);
                // 归档
        NSString *key = [NSString stringWithUTF8String:name];
        
        NSLog(@"属性名称:%s ,属性类型名称:%s",name,type);

        //type字段:nsinter ,long long属性,返回类型q,bool 类型返回B ，其他返回正常字符串如NSNumber,NSDate
        id value = [self valueForKey:key];
      
        if ([value isKindOfClass:[NSNull class]] || value == nil) {
          //  value = @"";
            value = [NSString stringWithUTF8String:type];
        }
        NSString *realKey = [key substringFromIndex:1];
        
        [dic setObject:value forKey:realKey];
    }
    
    free(ivars);
    
//    // 属性操作

    return dic;
}

/**
 *  返回属性列表 数组
 *
 *  @return @[@"userId",@"userName"]
 */
-(NSArray *)attributePropertyList{
    
    NSDictionary *dic = [self attributeProrertyDic];
    NSArray *array = [dic allKeys];
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

-(BOOL)save{
    
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    
    
    for (int i = 0; i < self.attributePropertyList.count; i++) {
        NSString *proname = [self.attributePropertyList objectAtIndex:i];
        
        if ([proname isEqualToString:primaryId]) {
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

static const void * externVariableKey =&externVariableKey;

-(id)pk{

    return objc_getAssociatedObject(self, externVariableKey);

}
-(void)setPk:(id)pk{

    objc_setAssociatedObject(self, externVariableKey, pk, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

@end
