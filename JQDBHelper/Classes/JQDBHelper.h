//
//  JQDBHelper.h
//  JQDBHelper
//
//  Created by zhangjinquan on 2019/11/26.
//

#import <Foundation/Foundation.h>

#import <FMDB.h>
#import "JQDBModel.h"

extern NSString * const jqdb_TEXT;
extern NSString * const jqdb_INTEGER;
extern NSString * const jqdb_REAL;
extern NSString * const jqdb_BIGINT;
extern NSString * const jqdb_BLOB;
extern NSString * const jqdb_BOOL;

extern NSString * const jqdb_PRIMARY_KEY;
extern NSString * const jqdb_NOT_NULL;
extern NSString * const jqdb_UNIQUE;

extern NSString * jqdb_DEFAULT(id value);
extern NSString * jqdb_CHECK(NSString *check);

//////////////////////////////////////////////////////////////////////////////////////////

@class JQDBSqlSelect;
@class JQDBSqlModify;
@class JQDBSqlDelete;

@interface JQDBSql : NSObject

@property (nonatomic, readonly) JQDBSql *(^schema)(NSString *schema);
@property (nonatomic, readonly) JQDBSql *(^where)(NSString *where);
@property (nonatomic, readonly) NSString *(^build)(void);

+ (JQDBSqlSelect *)select;
+ (JQDBSqlDelete *)del;

+ (JQDBSqlModify *)insert;
+ (JQDBSqlModify *)replace;
+ (JQDBSqlModify *)update;

+ (JQDBSqlSelect *)selectModel:(Class)modelClass columes:(NSArray *)columes;
+ (JQDBSqlDelete *)delModel:(Class)modelClass;
+ (JQDBSqlModify *)insertModel:(Class)modelClass;
+ (JQDBSqlModify *)replaceModel:(Class)modelClass;
+ (JQDBSqlModify *)updateModel:(Class)modelClass columes:(NSArray *)columes;

+ (NSString *)sql_createTableOfModel:(Class)modelClass onSchema:(NSString *)schema;
+ (NSString *)sql_createIndexOfModel:(Class)modelClass onSchema:(NSString *)schema;

@end

@interface JQDBSqlDelete : JQDBSql

@property (nonatomic, readonly) JQDBSqlDelete *(^from)(NSString *table);

@end

@interface JQDBSqlSelect : JQDBSql

@property (nonatomic, readonly) JQDBSqlSelect *(^columes)(NSArray *columes);
@property (nonatomic, readonly) JQDBSqlSelect *(^from)(NSArray *tables);
@property (nonatomic, readonly) JQDBSqlSelect *(^groupby)(NSArray *columes);
@property (nonatomic, readonly) JQDBSqlSelect *(^orderby)(NSArray<NSDictionary*>*columes); //key:columes value:顺序:DESC ASC
@property (nonatomic, readonly) JQDBSqlSelect *(^limit)(int offset, int count); // count = 0表明不限制个数

@end

@interface JQDBSqlModify : JQDBSql

@property (nonatomic, readonly) JQDBSqlModify *(^table)(NSString *table);
@property (nonatomic, readonly) JQDBSqlModify *(^columes)(NSArray *columes);
@property (nonatomic, readonly) JQDBSqlModify *(^placeholder)(BOOL use); // 是否使用'?'作为placeholder，默认为NO，即使用:{colume}的方式

@end

//////////////////////////////////////////////////////////////////////////////////////////

@interface FMResultSet (JQDBHelper)

- (NSArray *)jqdb_toArray;
- (NSDictionary *)jqdb_any;
- (void)jqdb_enumerate:(void (^)(NSDictionary *dict, BOOL *stop))blk;
- (void)jqdb_run:(void (^)(FMResultSet *me, BOOL *stop))blk;

- (NSArray *)jqdb_toArrayOfModel:(Class)modelClass;

@end

@interface JQDBHelper : NSObject

- (instancetype)initWithDB:(FMDatabase *)db schema:(NSString *)schema;

- (NSArray *)queryModel:(Class)modelClass where:(NSString *)where params:(NSDictionary *)params;
- (NSArray *)queryModel:(Class)modelClass keys:(NSArray *)keys params:(NSDictionary *)params;

- (BOOL)deleteModel:(Class)modelClass where:(NSString *)where params:(NSDictionary *)params;
- (BOOL)deleteModel:(Class)modelClass keys:(NSArray *)keys params:(NSDictionary *)params;

- (BOOL)createTableOfModel:(Class)modelClass;
- (BOOL)createIndexOfModel:(Class)modelClass;

- (BOOL)insertModel:(Class)modelClass params:(NSDictionary *)params;
- (BOOL)replaceModel:(Class)modelClass params:(NSDictionary *)params;
- (BOOL)insertModel:(Class)modelClass paramsList:(NSArray *)paramsList;
- (BOOL)replaceModel:(Class)modelClass paramsList:(NSArray *)paramsList;

- (BOOL)insertObject:(id<JQDBModel>)object;
- (BOOL)replaceObject:(id<JQDBModel>)object;
- (BOOL)insertModel:(Class)modelClass objects:(NSArray *)objects;
- (BOOL)replaceModel:(Class)modelClass objects:(NSArray *)objects;

- (BOOL)updateModel:(Class)modelClass columes:(NSArray *)columes where:(NSString *)where params:(NSDictionary *)params;
- (BOOL)updateModel:(Class)modelClass columes:(NSArray *)columes keys:(NSArray *)keys params:(NSDictionary *)params;
- (BOOL)updateModel:(Class)modelClass columes:(NSArray *)columes oRkeys:(NSArray *)keys params:(NSDictionary *)params ;
- (BOOL)updateObject:(id<JQDBModel>)object;

/**
 根据提供的modelClass，对比数据库内对应的表的所有列，自动对新增的字段进行add

 @param modelClass
 @return YES is success
 */
- (BOOL)upgradeModel:(Class)modelClass;
- (BOOL)dropTable:(NSString *)table;

@end

@interface FMDatabase (JQDBHelper)

- (JQDBHelper *)jqdb_helper;
- (JQDBHelper *)jqdb_helper:(NSString *)schema;

@end

