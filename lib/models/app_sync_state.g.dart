// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_sync_state.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppSyncStateCollection on Isar {
  IsarCollection<AppSyncState> get appSyncStates => this.collection();
}

const AppSyncStateSchema = CollectionSchema(
  name: r'AppSyncState',
  id: 6147271329718351770,
  properties: {
    r'hasCompletedInitialSync': PropertySchema(
      id: 0,
      name: r'hasCompletedInitialSync',
      type: IsarType.bool,
    ),
    r'syncedUserId': PropertySchema(
      id: 1,
      name: r'syncedUserId',
      type: IsarType.string,
    )
  },
  estimateSize: _appSyncStateEstimateSize,
  serialize: _appSyncStateSerialize,
  deserialize: _appSyncStateDeserialize,
  deserializeProp: _appSyncStateDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appSyncStateGetId,
  getLinks: _appSyncStateGetLinks,
  attach: _appSyncStateAttach,
  version: '3.1.0+1',
);

int _appSyncStateEstimateSize(
  AppSyncState object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.syncedUserId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _appSyncStateSerialize(
  AppSyncState object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.hasCompletedInitialSync);
  writer.writeString(offsets[1], object.syncedUserId);
}

AppSyncState _appSyncStateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppSyncState();
  object.hasCompletedInitialSync = reader.readBool(offsets[0]);
  object.id = id;
  object.syncedUserId = reader.readStringOrNull(offsets[1]);
  return object;
}

P _appSyncStateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appSyncStateGetId(AppSyncState object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appSyncStateGetLinks(AppSyncState object) {
  return [];
}

void _appSyncStateAttach(
    IsarCollection<dynamic> col, Id id, AppSyncState object) {
  object.id = id;
}

extension AppSyncStateQueryWhereSort
    on QueryBuilder<AppSyncState, AppSyncState, QWhere> {
  QueryBuilder<AppSyncState, AppSyncState, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppSyncStateQueryWhere
    on QueryBuilder<AppSyncState, AppSyncState, QWhereClause> {
  QueryBuilder<AppSyncState, AppSyncState, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AppSyncStateQueryFilter
    on QueryBuilder<AppSyncState, AppSyncState, QFilterCondition> {
  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      hasCompletedInitialSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasCompletedInitialSync',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'syncedUserId',
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'syncedUserId',
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedUserId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncedUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncedUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncedUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncedUserId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterFilterCondition>
      syncedUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncedUserId',
        value: '',
      ));
    });
  }
}

extension AppSyncStateQueryObject
    on QueryBuilder<AppSyncState, AppSyncState, QFilterCondition> {}

extension AppSyncStateQueryLinks
    on QueryBuilder<AppSyncState, AppSyncState, QFilterCondition> {}

extension AppSyncStateQuerySortBy
    on QueryBuilder<AppSyncState, AppSyncState, QSortBy> {
  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy>
      sortByHasCompletedInitialSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompletedInitialSync', Sort.asc);
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy>
      sortByHasCompletedInitialSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompletedInitialSync', Sort.desc);
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy> sortBySyncedUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedUserId', Sort.asc);
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy>
      sortBySyncedUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedUserId', Sort.desc);
    });
  }
}

extension AppSyncStateQuerySortThenBy
    on QueryBuilder<AppSyncState, AppSyncState, QSortThenBy> {
  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy>
      thenByHasCompletedInitialSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompletedInitialSync', Sort.asc);
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy>
      thenByHasCompletedInitialSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompletedInitialSync', Sort.desc);
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy> thenBySyncedUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedUserId', Sort.asc);
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QAfterSortBy>
      thenBySyncedUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedUserId', Sort.desc);
    });
  }
}

extension AppSyncStateQueryWhereDistinct
    on QueryBuilder<AppSyncState, AppSyncState, QDistinct> {
  QueryBuilder<AppSyncState, AppSyncState, QDistinct>
      distinctByHasCompletedInitialSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasCompletedInitialSync');
    });
  }

  QueryBuilder<AppSyncState, AppSyncState, QDistinct> distinctBySyncedUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedUserId', caseSensitive: caseSensitive);
    });
  }
}

extension AppSyncStateQueryProperty
    on QueryBuilder<AppSyncState, AppSyncState, QQueryProperty> {
  QueryBuilder<AppSyncState, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppSyncState, bool, QQueryOperations>
      hasCompletedInitialSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasCompletedInitialSync');
    });
  }

  QueryBuilder<AppSyncState, String?, QQueryOperations> syncedUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedUserId');
    });
  }
}
