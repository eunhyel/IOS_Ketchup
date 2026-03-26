// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_diary_sync_meta.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarDiarySyncMetaCollection on Isar {
  IsarCollection<IsarDiarySyncMeta> get isarDiarySyncMetas => this.collection();
}

const IsarDiarySyncMetaSchema = CollectionSchema(
  name: r'IsarDiarySyncMeta',
  id: 6428783226665826125,
  properties: {
    r'syncKey': PropertySchema(
      id: 0,
      name: r'syncKey',
      type: IsarType.string,
    )
  },
  estimateSize: _isarDiarySyncMetaEstimateSize,
  serialize: _isarDiarySyncMetaSerialize,
  deserialize: _isarDiarySyncMetaDeserialize,
  deserializeProp: _isarDiarySyncMetaDeserializeProp,
  idName: r'id',
  indexes: {
    r'syncKey': IndexSchema(
      id: -4971009725215132130,
      name: r'syncKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarDiarySyncMetaGetId,
  getLinks: _isarDiarySyncMetaGetLinks,
  attach: _isarDiarySyncMetaAttach,
  version: '3.1.0+1',
);

int _isarDiarySyncMetaEstimateSize(
  IsarDiarySyncMeta object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.syncKey.length * 3;
  return bytesCount;
}

void _isarDiarySyncMetaSerialize(
  IsarDiarySyncMeta object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.syncKey);
}

IsarDiarySyncMeta _isarDiarySyncMetaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarDiarySyncMeta();
  object.id = id;
  object.syncKey = reader.readString(offsets[0]);
  return object;
}

P _isarDiarySyncMetaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarDiarySyncMetaGetId(IsarDiarySyncMeta object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarDiarySyncMetaGetLinks(
    IsarDiarySyncMeta object) {
  return [];
}

void _isarDiarySyncMetaAttach(
    IsarCollection<dynamic> col, Id id, IsarDiarySyncMeta object) {
  object.id = id;
}

extension IsarDiarySyncMetaByIndex on IsarCollection<IsarDiarySyncMeta> {
  Future<IsarDiarySyncMeta?> getBySyncKey(String syncKey) {
    return getByIndex(r'syncKey', [syncKey]);
  }

  IsarDiarySyncMeta? getBySyncKeySync(String syncKey) {
    return getByIndexSync(r'syncKey', [syncKey]);
  }

  Future<bool> deleteBySyncKey(String syncKey) {
    return deleteByIndex(r'syncKey', [syncKey]);
  }

  bool deleteBySyncKeySync(String syncKey) {
    return deleteByIndexSync(r'syncKey', [syncKey]);
  }

  Future<List<IsarDiarySyncMeta?>> getAllBySyncKey(List<String> syncKeyValues) {
    final values = syncKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'syncKey', values);
  }

  List<IsarDiarySyncMeta?> getAllBySyncKeySync(List<String> syncKeyValues) {
    final values = syncKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'syncKey', values);
  }

  Future<int> deleteAllBySyncKey(List<String> syncKeyValues) {
    final values = syncKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'syncKey', values);
  }

  int deleteAllBySyncKeySync(List<String> syncKeyValues) {
    final values = syncKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'syncKey', values);
  }

  Future<Id> putBySyncKey(IsarDiarySyncMeta object) {
    return putByIndex(r'syncKey', object);
  }

  Id putBySyncKeySync(IsarDiarySyncMeta object, {bool saveLinks = true}) {
    return putByIndexSync(r'syncKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySyncKey(List<IsarDiarySyncMeta> objects) {
    return putAllByIndex(r'syncKey', objects);
  }

  List<Id> putAllBySyncKeySync(List<IsarDiarySyncMeta> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'syncKey', objects, saveLinks: saveLinks);
  }
}

extension IsarDiarySyncMetaQueryWhereSort
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QWhere> {
  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarDiarySyncMetaQueryWhere
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QWhereClause> {
  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterWhereClause>
      syncKeyEqualTo(String syncKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncKey',
        value: [syncKey],
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterWhereClause>
      syncKeyNotEqualTo(String syncKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncKey',
              lower: [],
              upper: [syncKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncKey',
              lower: [syncKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncKey',
              lower: [syncKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncKey',
              lower: [],
              upper: [syncKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarDiarySyncMetaQueryFilter
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QFilterCondition> {
  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterFilterCondition>
      syncKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncKey',
        value: '',
      ));
    });
  }
}

extension IsarDiarySyncMetaQueryObject
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QFilterCondition> {}

extension IsarDiarySyncMetaQueryLinks
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QFilterCondition> {}

extension IsarDiarySyncMetaQuerySortBy
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QSortBy> {
  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterSortBy>
      sortBySyncKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncKey', Sort.asc);
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterSortBy>
      sortBySyncKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncKey', Sort.desc);
    });
  }
}

extension IsarDiarySyncMetaQuerySortThenBy
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QSortThenBy> {
  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterSortBy>
      thenBySyncKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncKey', Sort.asc);
    });
  }

  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QAfterSortBy>
      thenBySyncKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncKey', Sort.desc);
    });
  }
}

extension IsarDiarySyncMetaQueryWhereDistinct
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QDistinct> {
  QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QDistinct>
      distinctBySyncKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncKey', caseSensitive: caseSensitive);
    });
  }
}

extension IsarDiarySyncMetaQueryProperty
    on QueryBuilder<IsarDiarySyncMeta, IsarDiarySyncMeta, QQueryProperty> {
  QueryBuilder<IsarDiarySyncMeta, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarDiarySyncMeta, String, QQueryOperations> syncKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncKey');
    });
  }
}
