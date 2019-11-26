//
//  JQDBModel.h
//  JQDBHelper
//
//  Created by zhangjinquan on 2019/11/26.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>

@protocol JQDBModel <NSObject>

/**
 描述类所对应的模型名字，用于给表命名

 @return 返回表的名字
 */
+ (NSString *)jqdb_tableName;

/**
 用于描述表的colume，如类型、约束等，如果是继承，需添加superClass的colume描述

 @return 返回形如：
    {
        "name": ["TEXT", "default 'Jack'"] // 多个描述用数组
        "id": ["INTEGER", "default 0", "PRIMARY KEY"],
        "alias": "TEXT" // 单个描述可以不用数组
    }
 */
+ (NSDictionary *)jqdb_columeDefines;

@optional

/**
 用于描述表的版本号，若不指定，默认为0
 
 @return 返回版本号的int值
 */
+ (int)jqdb_tableVersion;

/**
 用于描述表的主键

 @return 返回内容是colume名字的数组
 */
+ (NSArray *)jqdb_tablePrimaryKeys;

/**
 用于建立表的索引

 @return 返回内容是colume名字的数组
 */
+ (NSArray *)jqdb_indexKeys;

+ (NSArray *)jqdb_columesEmbededAsBlob;

/**
 @return 要存对象的Class及列名。 内部实现了将对象转换为json放入db，从db取出自动转换为对象。
 @discuss 如果某个属性是对象，你又希望直接存入数据库使用
 @todo:当Class是NSArrary，NSDictionary等集合 且这些集合内部又包含非基础对象时，不能完全解析成对象。有待完善。
 */
+ (NSDictionary<NSString *, Class> *)jqdb_columesEmbededAsJson;

+ (NSDictionary<NSString *, Class> *)jqdb_embededModelMapper;

/**
 数据库升级，针对该表进行升级

 @param db : db对象
 @param version : 从该版本号升级
 @return 该方法在transaction中被调用，如果返回NO，则需要回滚
 */
+ (BOOL)jqdb_upgrade:(FMDatabase *)db fromVersion:(int)version;

+ (NSArray *)jqdb_allColumes;

@end

@interface NSObject (JQDBModel)

+ (NSArray *)jqdb_allColumes;

- (NSDictionary *)jqdb_modelToDictionary;
+ (instancetype)jqdb_modelWithDictionary:(NSDictionary *)dictionary;

- (NSData *)blobData;

@end

@interface NSArray (JQDBModel)

- (NSArray *)jqdb_modelToDictionarys;
- (NSArray *)jqdb_dictionaryToModelsOfClass:(Class)modelClass;

@end
