import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'build_test.g.dart';

@Collection()
class Account {
  Account();

  Account.fromFields(
    this.userId,
    this.email,
    this.firstname,
    this.lastname,
    this.birthdate,
  );

  final Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId;
  late String email;
  late String firstname;
  late String lastname;
  late DateTime birthdate;

  @override
  String toString() {
    return '{id: $id, userId: $userId, email: $email, firstname: $firstname, '
        'lastname: $lastname, birthdate: $birthdate}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is Account &&
        other.id == id &&
        other.userId == userId &&
        other.email == email &&
        other.firstname == firstname &&
        other.lastname == lastname &&
        other.birthdate == birthdate;
  }
}

void main() {
  group('Build query', () {
    late Isar isar;

    late Account account0;
    late Account account1;
    late Account account2;
    late Account account3;
    late Account account4;
    late Account account5;
    late Account account6;
    late Account account7;
    late Account account8;
    late Account account9;
    late Account account10;
    late Account account11;
    late Account account12;
    late Account account13;
    late Account account14;
    late Account account15;

    setUp(() async {
      isar = await openTempIsar([AccountSchema]);

      account0 = Account.fromFields(
        'oauth2|00000000',
        'foo0@bar.com',
        'Foo0',
        'Bar',
        DateTime(1955, 6, 8),
      );
      account1 = Account.fromFields(
        'password|00000001',
        'foo1@bar.com',
        'Foo1',
        'Bar',
        DateTime(1990, 3, 17),
      );
      account2 = Account.fromFields(
        'password|00000002',
        'foo2@bar.com',
        'Foo2',
        'Bar',
        DateTime(2008, 11, 3),
      );
      account3 = Account.fromFields(
        'oauth2|00000003',
        'foo3@bar.com',
        'Foo3',
        'Not Bar',
        DateTime(1968, 4, 24),
      );
      account4 = Account.fromFields(
        'oauth2|00000004',
        'foo4@bar.com',
        'Foo4',
        'Bar',
        DateTime(1992, 6, 11),
      );
      account5 = Account.fromFields(
        'oauth2|00000005',
        'foo5@bar.com',
        'Foo5',
        'Bar',
        DateTime(2001, 12, 12),
      );
      account6 = Account.fromFields(
        'password|00000006',
        'foo6@bar.com',
        'Foo6',
        'Not Bar',
        DateTime(1998, 2, 22),
      );
      account7 = Account.fromFields(
        'oauth2|00000007',
        'foo7@bar.com',
        'Foo7',
        'Bar',
        DateTime(1991, 11, 11),
      );
      account8 = Account.fromFields(
        'password|00000008',
        'foo8@bar.com',
        'Foo8',
        'Bar',
        DateTime(1988, 7, 17),
      );
      account9 = Account.fromFields(
        'oauth2|00000009',
        'foo9@bar.com',
        'Foo9',
        'Not Bar',
        DateTime(1980, 4, 24),
      );
      account10 = Account.fromFields(
        'oauth2|0000000A',
        'foo10@bar.com',
        'Foo10',
        'Not Bar',
        DateTime(1971, 9, 24),
      );
      account11 = Account.fromFields(
        'oauth2|0000000B',
        'foo11@bar.com',
        'Foo11',
        'Bar',
        DateTime(1999, 2, 12),
      );
      account12 = Account.fromFields(
        'password|0000000C',
        'foo12@bar.com',
        'Foo12',
        'Bar',
        DateTime(1988, 6, 16),
      );
      account13 = Account.fromFields(
        'password|0000000D',
        'foo13@bar.com',
        'Foo13',
        'Bar',
        DateTime(1993, 3, 13),
      );
      account14 = Account.fromFields(
        'oauth2|0000000E',
        'foo14@bar.com',
        'Foo14',
        'Bar',
        DateTime(1942, 4, 2),
      );
      account15 = Account.fromFields(
        'oauth2|0000000F',
        'foo15@bar.com',
        'Foo15',
        'Not Bar',
        DateTime(1977, 5, 15),
      );

      await isar.tWriteTxn(() async {
        await isar.accounts.tPutAll([
          account0,
          account1,
          account2,
          account3,
          account4,
          account5,
          account6,
          account7,
          account8,
          account9,
          account10,
          account11,
          account12,
          account13,
          account14,
          account15,
        ]);
      });
    });

    isarTest('Simple filter with sort', () async {
      final objs = await isar.accounts.buildQuery<Account>(
        filter: FilterCondition.lessThan(
          property: 'birthdate',
          value: DateTime(1980),
        ),
        sortBy: const [SortProperty(property: 'birthdate', sort: Sort.desc)],
      ).tFindAll();

      expect(objs, [account15, account10, account3, account0, account14]);
    });

    isarTest('Nested filter groups', () async {
      // userId != null
      // &&
      // (
      //    (birthdate >= 2000-01-01 && userId.startsWith("password"))
      //    ||
      //    (birthdate <= 1970-01-01 && userId.startsWith("oauth2"))
      // )
      final objs = await isar.accounts.buildQuery<Account>(
        filter: FilterGroup.and([
          FilterGroup.not(
            const FilterCondition.isNull(property: 'userId'),
          ),
          FilterGroup.or([
            FilterGroup.and([
              FilterGroup.or([
                FilterCondition.equalTo(
                  property: 'birthdate',
                  value: DateTime(2000),
                ),
                FilterCondition.greaterThan(
                  property: 'birthdate',
                  value: DateTime(2000),
                ),
              ]),
              const FilterCondition.startsWith(
                property: 'userId',
                value: 'password',
              ),
            ]),
            FilterGroup.and([
              FilterGroup.or([
                FilterCondition.equalTo(
                  property: 'birthdate',
                  value: DateTime(1970),
                ),
                FilterCondition.lessThan(
                  property: 'birthdate',
                  value: DateTime(1970),
                ),
              ]),
              const FilterCondition.startsWith(
                property: 'userId',
                value: 'oauth2',
              ),
            ]),
          ]),
        ]),
        sortBy: const [
          SortProperty(property: 'firstname', sort: Sort.asc),
          SortProperty(property: 'lastname', sort: Sort.desc),
        ],
      ).tFindAll();

      expect(objs, [account0, account14, account2, account3]);
    });

    isarTest('Nested not filters', () async {
      // !!(!userId.startsWith('password') && !((!(birthdate >= 1997-01-01 &&
      // birthdate <= 2003-01-01)))
      final objs = await isar.accounts.buildQuery<Account>(
        filter: FilterGroup.not(
          FilterGroup.not(
            FilterGroup.and([
              FilterGroup.not(
                FilterGroup.or([
                  FilterGroup.and([
                    FilterGroup.not(
                      FilterCondition.between(
                        property: 'birthdate',
                        lower: DateTime(1997),
                        upper: DateTime(2003),
                      ),
                    ),
                  ]),
                  const FilterCondition.startsWith(
                    property: 'userId',
                    value: 'password',
                  ),
                ]),
              ),
              FilterGroup.not(
                const FilterCondition.startsWith(
                  property: 'userId',
                  value: 'password',
                ),
              ),
            ]),
          ),
        ),
        sortBy: const [SortProperty(property: 'userId', sort: Sort.asc)],
      ).tFindAll();

      expect(objs, [account5, account11]);
    });

    isarTest('Empty filter groups', () async {
      final objs = await isar.accounts.buildQuery<Account>(
        filter: FilterGroup.and([
          FilterGroup.not(
            FilterGroup.and([
              FilterGroup.and([
                FilterGroup.not(
                  FilterCondition.greaterThan(
                    property: 'birthdate',
                    value: DateTime(1999, 2, 12),
                  ),
                ),
              ]),
            ]),
          ),
          const FilterGroup.or([
            FilterGroup.or([]),
          ]),
        ]),
        sortBy: const [SortProperty(property: 'firstname', sort: Sort.desc)],
      ).tFindAll();

      expect(objs, [account5, account2]);
    });

    isarTest('Distinct by', () async {
      final count = await isar.accounts.buildQuery<Account>(
        distinctBy: const [DistinctProperty(property: 'lastname')],
      ).tCount();

      expect(count, 2);
    });

    isarTest('Distinct by with filter', () async {
      final count = await isar.accounts.buildQuery<Account>(
        filter: const FilterCondition.equalTo(
          property: 'lastname',
          value: 'bar',
          caseSensitive: false,
        ),
        distinctBy: const [DistinctProperty(property: 'lastname')],
      ).tCount();

      expect(count, 1);
    });

    isarTest('String property', () async {
      final firstnames = await isar.accounts.buildQuery<String>(
        filter: const FilterCondition.startsWith(
          property: 'userId',
          value: 'password',
        ),
        property: 'firstname',
        sortBy: const [SortProperty(property: 'firstname', sort: Sort.asc)],
      ).tFindAll();

      expect(firstnames, ['Foo1', 'Foo12', 'Foo13', 'Foo2', 'Foo6', 'Foo8']);
    });

    isarTest('Search query', () async {
      const searchQuery = 'oauth2 bar foo 1';
      const searchableProperties = ['userId', 'email', 'firstname', 'lastname'];

      final searchTokens = searchQuery.split(' ');

      // Must match every token to at least one column
      final objs = await isar.accounts.buildQuery<Account>(
        filter: FilterGroup.and([
          for (final searchToken in searchTokens)
            FilterGroup.or([
              for (final property in searchableProperties)
                FilterCondition.contains(
                  property: property,
                  value: searchToken,
                  caseSensitive: false,
                ),
            ]),
        ]),
        sortBy: const [SortProperty(property: 'firstname', sort: Sort.asc)],
      ).tFindAll();

      expect(objs, [account10, account11, account14, account15]);
    });
  });
}
