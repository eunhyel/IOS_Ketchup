// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_app_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAppSettingsCollection on Isar {
  IsarCollection<IsarAppSettings> get isarAppSettings => this.collection();
}

const IsarAppSettingsSchema = CollectionSchema(
  name: r'IsarAppSettings',
  id: -9223260734181630302,
  properties: {
    r'fontName': PropertySchema(
      id: 0,
      name: r'fontName',
      type: IsarType.string,
    ),
    r'useCloudSync': PropertySchema(
      id: 1,
      name: r'useCloudSync',
      type: IsarType.bool,
    ),
    r'useIcloudSync': PropertySchema(
      id: 2,
      name: r'useIcloudSync',
      type: IsarType.bool,
    ),
    r'useLock': PropertySchema(
      id: 3,
      name: r'useLock',
      type: IsarType.bool,
    )
  },
  estimateSize: _isarAppSettingsEstimateSize,
  serialize: _isarAppSettingsSerialize,
  deserialize: _isarAppSettingsDeserialize,
  deserializeProp: _isarAppSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _isarAppSettingsGetId,
  getLinks: _isarAppSettingsGetLinks,
  attach: _isarAppSettingsAttach,
  version: '3.1.0+1',
);

int _isarAppSettingsEstimateSize(
  IsarAppSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fontName.length * 3;
  return bytesCount;
}

void _isarAppSettingsSerialize(
  IsarAppSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.fontName);
  writer.writeBool(offsets[1], object.useCloudSync);
  writer.writeBool(offsets[2], object.useIcloudSync);
  writer.writeBool(offsets[3], object.useLock);
}

IsarAppSettings _isarAppSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAppSettings();
  object.fontName = reader.readString(offsets[0]);
  object.id = id;
  object.useCloudSync = reader.readBoolOrNull(offsets[1]);
  object.useIcloudSync = reader.readBoolOrNull(offsets[2]);
  object.useLock = reader.readBool(offsets[3]);
  return object;
}

P _isarAppSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset)) as P;
    case 2:
      return (reader.readBoolOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAppSettingsGetId(IsarAppSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarAppSettingsGetLinks(IsarAppSettings object) {
  return [];
}

void _isarAppSettingsAttach(
    IsarCollection<dynamic> col, Id id, IsarAppSettings object) {
  object.id = id;
}

extension IsarAppSettingsQueryWhereSort
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QWhere> {
  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarAppSettingsQueryWhere
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QWhereClause> {
  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterWhereClause>
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

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterWhereClause> idBetween(
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

extension IsarAppSettingsQueryFilter
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QFilterCondition> {
  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fontName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fontName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fontName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fontName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      fontNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fontName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
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

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
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

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
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

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      useCloudSyncIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'useCloudSync',
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      useCloudSyncIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'useCloudSync',
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      useCloudSyncEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useCloudSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      useIcloudSyncIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'useIcloudSync',
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      useIcloudSyncIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'useIcloudSync',
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      useIcloudSyncEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useIcloudSync',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterFilterCondition>
      useLockEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useLock',
        value: value,
      ));
    });
  }
}

extension IsarAppSettingsQueryObject
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QFilterCondition> {}

extension IsarAppSettingsQueryLinks
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QFilterCondition> {}

extension IsarAppSettingsQuerySortBy
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QSortBy> {
  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      sortByFontName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontName', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      sortByFontNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontName', Sort.desc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      sortByUseCloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCloudSync', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      sortByUseCloudSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCloudSync', Sort.desc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      sortByUseIcloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useIcloudSync', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      sortByUseIcloudSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useIcloudSync', Sort.desc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy> sortByUseLock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useLock', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      sortByUseLockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useLock', Sort.desc);
    });
  }
}

extension IsarAppSettingsQuerySortThenBy
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QSortThenBy> {
  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      thenByFontName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontName', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      thenByFontNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontName', Sort.desc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      thenByUseCloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCloudSync', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      thenByUseCloudSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCloudSync', Sort.desc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      thenByUseIcloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useIcloudSync', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      thenByUseIcloudSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useIcloudSync', Sort.desc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy> thenByUseLock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useLock', Sort.asc);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QAfterSortBy>
      thenByUseLockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useLock', Sort.desc);
    });
  }
}

extension IsarAppSettingsQueryWhereDistinct
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QDistinct> {
  QueryBuilder<IsarAppSettings, IsarAppSettings, QDistinct> distinctByFontName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fontName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QDistinct>
      distinctByUseCloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useCloudSync');
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QDistinct>
      distinctByUseIcloudSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useIcloudSync');
    });
  }

  QueryBuilder<IsarAppSettings, IsarAppSettings, QDistinct>
      distinctByUseLock() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useLock');
    });
  }
}

extension IsarAppSettingsQueryProperty
    on QueryBuilder<IsarAppSettings, IsarAppSettings, QQueryProperty> {
  QueryBuilder<IsarAppSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAppSettings, String, QQueryOperations> fontNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fontName');
    });
  }

  QueryBuilder<IsarAppSettings, bool?, QQueryOperations>
      useCloudSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useCloudSync');
    });
  }

  QueryBuilder<IsarAppSettings, bool?, QQueryOperations>
      useIcloudSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useIcloudSync');
    });
  }

  QueryBuilder<IsarAppSettings, bool, QQueryOperations> useLockProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useLock');
    });
  }
}
