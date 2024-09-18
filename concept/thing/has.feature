# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Concept Ownership

  Background:
    Given typedb starts
    Given connection opens with default authentication
    Given connection has been opened
    Given connection does not have any database
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    # Write schema for the test scenarios
    Given create attribute type: username
    Given attribute(username) set value type: string
    Given create attribute type: name
    Given attribute(name) set value type: string
    Given attribute(name) set annotation: @independent
    Given create attribute type: birth-date
    Given attribute(birth-date) set value type: date
    Given create attribute type: email
    Given attribute(email) set value type: string
    Given create attribute type: not-owned-string
    Given attribute(not-owned-string) set value type: string
    Given attribute(not-owned-string) set annotation: @independent
    Given create relation type: parentship
    Given relation(parentship) create role: parent
    Given relation(parentship) get role(parent) set annotation: @card(0..)
    Given relation(parentship) set owns: username
    Given relation(parentship) get owns(username) set annotation: @key
    Given relation(parentship) set owns: name
    Given relation(parentship) set owns: birth-date
    Given relation(parentship) set owns: email
    Given relation(parentship) get owns(email) set ordering: ordered
    Given create entity type: person
    Given entity(person) set owns: username
    Given entity(person) get owns(username) set annotation: @key
    Given entity(person) set owns: name
    Given entity(person) set owns: birth-date
    Given entity(person) set owns: email
    Given entity(person) get owns(email) set ordering: ordered
    Given entity(person) set plays: parentship:parent
    Given transaction commits
    Given connection open write transaction for database: typedb

  Scenario: Entity can have an ordered collection of attributes
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt]
    Then transaction commits

  Scenario: Relation can have an ordered collection of attributes
    When $a = entity(person) create new instance with key(username): alice
    When $p = relation(parentship) create new instance with key(username): alice-parentship
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When relation $p add player for role(parent): $a
    When relation $p set has(email[]): [$main, $alt]
    Then transaction commits

  Scenario: Ordered attributes can be retrieved and indexed
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt]
    Then transaction commits
    When connection open read transaction for database: typedb
    Then $emails = entity $a get has(email[])
    Then attribute $emails[0] is $main
    Then attribute $emails[1] is $alt

  Scenario: Ordered attributes can be retrieved as unordered
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt]
    Then transaction commits
    When connection open read transaction for database: typedb
    Then entity $a get has(email) contain: $main
    Then entity $a get has(email) contain: $alt

  Scenario: Ordered attributes can contain the same attribute multiple times
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt, $main, $main, $alt]
    Then transaction commits
    When connection open read transaction for database: typedb
    Then $emails = entity $a get has(email[])
    Then attribute $emails[0] is $main
    Then attribute $emails[1] is $alt
    Then attribute $emails[2] is $main
    Then attribute $emails[3] is $main
    Then attribute $emails[4] is $alt

  Scenario: Ordered attributes can be overwritten
    When $a = entity(person) create new instance with key(username): alice
    When $main = attribute(email) put instance with value: alice@email.com
    When $alt = attribute(email) put instance with value: alice2@email.com
    When entity $a set has(email[]): [$main, $alt]
    Then transaction commits
    When connection open write transaction for database: typedb
    Then $emails = entity $a get has(email[])
    Then attribute $emails[0] is $main
    Then attribute $emails[1] is $alt
    When $alt2 = attribute(email) put instance with value: alice@email.net
    Then entity $a get has(email) contain: $main
    Then entity $a get has(email) contain: $alt
    Then entity $a get has(email) do not contain: $alt2
    When entity $a set has(email[]): [$alt2, $main]
    Then transaction commits
    When connection open read transaction for database: typedb
    Then $emails = entity $a get has(email[])
    Then attribute $emails[0] is $alt2
    Then attribute $emails[1] is $main
    Then entity $a get has(email) contain: $main
    Then entity $a get has(email) do not contain: $alt
    Then entity $a get has(email) contain: $alt2

  Scenario: Non-independent attributes are cleaned up without owners
    When $p = entity(person) create new instance with key(username): "k"
    When $b = attribute(birth-date) put instance with value: 2024-01-15
    When entity $p set has: $b
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(username) get instances is not empty
    When $p = entity(person) get instance with key(username): "k"
    When $b = attribute(birth-date) get instance with value: 2024-01-15
    When entity $p unset has: $b
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(birth-date) get instances is empty

  Scenario: Independent attributes are not cleaned up without owners
    When $p = entity(person) create new instance with key(username): "k"
    When $n = attribute(name) put instance with value: "k"
    When entity $p set has: $n
    When transaction commits
    When connection open write transaction for database: typedb
    Then attribute(name) get instances is not empty
    When $p = entity(person) get instance with key(username): "k"
    When $n = attribute(name) get instance with value: "k"
    When entity $p unset has: $n
    When transaction commits
    When connection open read transaction for database: typedb
    Then attribute(name) get instances is not empty

  Scenario: Cannot set has when object doesn't own the attribute
    When $k = entity(person) create new instance with key(username): "k"
    When $l = relation(parentship) create new instance with key(username): "l"
    When $n = attribute(not-owned-string) put instance with value: "I am not owned"
    Then entity $k set has: $n; fails
    Then relation $l set has: $n; fails

  Scenario: Can set has only for attribute with value type string that satisfies the regular expression on owns
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When entity(person) get owns(name) set annotation: @regex("\S+@\S+\.\S+")
    When entity(person) get owns(email) set annotation: @regex("\S+@\S+\.\S+")
    When attribute(name) set annotation: @independent
    When attribute(email) set annotation: @independent
    When transaction commits
    When connection open write transaction for database: typedb
    When $correct_n = attribute(name) put instance with value: alice@email.com
    When $correct_e = attribute(email) put instance with value: alice@email.com
    When $incorrect_n = attribute(name) put instance with value: alice-email-com
    When $incorrect_e = attribute(email) put instance with value: alice-email-com
    When $p = entity(person) create new instance with key(username): "p"
    Then entity $p set has: $incorrect_n; fails
    When entity $p set has: $correct_n
    Then entity $p set has(email[]): [$incorrect_e]; fails
    When entity $p set has(email[]): [$correct_e]
    When transaction commits
    When connection open read transaction for database: typedb
    When $correct_n = attribute(name) get instance with value: alice@email.com
    When $incorrect_n = attribute(name) get instance with value: alice-email-com
    When $correct_e = attribute(email) get instance with value: alice@email.com
    When $incorrect_e = attribute(email) get instance with value: alice-email-com
    When $p = entity(person) get instance with key(username): "p"
    Then entity $p get has(name) contain: $correct_n
    Then entity $p get has(name) do not contain: $incorrect_n
    Then entity $p get has(email) contain: $correct_e
    Then entity $p get has(email) do not contain: $incorrect_e

  Scenario: Attribute with value type string that does not satisfy the regular expression cannot be set as "has"    Given transaction closes
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When attribute(name) set annotation: @regex("\S+@\S+\.\S+")
    When transaction commits
    When connection open write transaction for database: typedb

  Scenario Outline: Cannot create instances of attribute type of value type <value-type> with values not matching @values(<values-args>) annotation
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: limited-value
    When attribute(limited-value) set value type: <value-type>
    When attribute(limited-value) set annotation: @independent
    When entity(person) set owns: limited-value
    When entity(person) get owns(limited-value) set annotation: @values(<values-args>)
    When transaction commits
    When connection open write transaction for database: typedb
    When $fail = attribute(limited-value) put instance with value: <fail-val>
    When $suc = attribute(limited-value) put instance with value: <suc-val>
    When $p = entity(person) create new instance with key(username): "p"
    Then entity $p set has: $fail; fails
    When entity $p set has: $suc
    When transaction commits
    When connection open read transaction for database: typedb
    When $correct = attribute(email) get instance with value: <fail-val>
    When $incorrect = attribute(email) get instance with value: <suc-val>
    When $p = entity(person) get instance with key(username): "p"
    Then entity $p get has(limited-value) contain: $suc
    Then entity $p get has(limited-value) do not contain: $fail
    Examples:
      | value-type  | values-args                               | fail-val                      | suc-val                       |
      | long        | 1, 5, 4                                   | 2                             | 1                             |
      | long        | 1                                         | 2                             | 1                             |
      | double      | 1.1, 1.5, 0.01                            | 0.1                           | 0.01                          |
      | double      | 0.01                                      | 0.1                           | 0.01                          |
      | double      | 0.01, 0.0001                              | 0.001                         | 0.0001                        |
      | double      | 0.01, 0.0001                              | 1.0                           | 0.01                          |
      | decimal     | -8.0, 88.3, 0.001                         | 0.01                          | 0.001                         |
      | decimal     | 0.001                                     | 0.01                          | 0.001                         |
      | decimal     | 0.01                                      | 0.1                           | 0.01                          |
      | decimal     | 0.01, 0.0001                              | 0.001                         | 0.0001                        |
      | decimal     | 0.01, 0.0001                              | 1.0                           | 0.01                          |
      | string      | "s", "sss", "S"                           | "ss"                          | "sss"                         |
      | string      | "s", "sss"                                | "S"                           | "s"                           |
      | string      | "sss"                                     | "ss"                          | "sss"                         |
      | boolean     | true                                      | false                         | true                          |
      | boolean     | false                                     | true                          | false                         |
      | date        | 2024-05-05, 2024-05-07                    | 2024-05-06                    | 2024-05-05                    |
      | date        | 2024-05-05                                | 2024-05-06                    | 2024-05-05                    |
      | datetime    | 2024-05-05T16:01:59, 2024-05-05T16:01:58  | 2024-05-05T16:01:57           | 2024-05-05T16:01:59           |
      | datetime    | 2024-05-05T16:01:59                       | 2024-05-05T16:01:57           | 2024-05-05T16:01:59           |
      | datetime    | 2024-05-05T16:01:59.123456789             | 2024-05-05T16:01:57.12345678  | 2024-05-05T16:01:59.123456789 |
      | datetime    | 2024-05-05T16:01:59.123456789             | 2024-05-05T16:01:57.123456788 | 2024-05-05T16:01:59.123456789 |
      | datetime    | 2024-05-05T16:01:59.123456789             | 2024-05-05T16:01:57.12345679  | 2024-05-05T16:01:59.123456789 |
      | datetime-tz | 2024-05-05+0100, 2024-05-05T16:31:59+0100 | 2024-05-05+0000               | 2024-05-05T16:31:59+0100      |
      | datetime-tz | 2024-05-05T16:31:59+0100                  | 2024-05-05+0000               | 2024-05-05T16:31:59+0100      |
      | duration    | P1Y, P1Y5M8H                              | P2Y                           | P1Y                           |
      | duration    | P1Y                                       | P2Y                           | P1Y                           |
      | duration    | P1Y, P1Y1M1DT1H1M0.000001S                | P1Y1M1DT1H1M0.00001S          | P1Y1M1DT1H1M0.000001S         |

  Scenario Outline: Cannot create instances of attribute type of value type <value-type> with values not matching @range(<range-args>) annotation
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: limited-value
    When attribute(limited-value) set value type: <value-type>
    When attribute(limited-value) set annotation: @independent
    When entity(person) set owns: limited-value
    When entity(person) get owns(limited-value) set annotation: @range(<range-args>)
    When transaction commits
    When connection open write transaction for database: typedb
    When $fail = attribute(limited-value) put instance with value: <fail-val>
    When $suc = attribute(limited-value) put instance with value: <suc-val>
    When $p = entity(person) create new instance with key(username): "p"
    Then entity $p set has: $fail; fails
    When entity $p set has: $suc
    When transaction commits
    When connection open read transaction for database: typedb
    When $correct = attribute(email) get instance with value: <fail-val>
    When $incorrect = attribute(email) get instance with value: <suc-val>
    When $p = entity(person) get instance with key(username): "p"
    Then entity $p get has(limited-value) contain: $suc
    Then entity $p get has(limited-value) do not contain: $fail
    Examples:
      | value-type  | range-args                                | fail-val            | suc-val                  |
      | long        | 1..3                                      | 0                   | 1                        |
      | long        | 1..3                                      | -1                  | 2                        |
      | long        | 1..3                                      | 4                   | 3                        |
      | long        | -1..1                                     | -2                  | 0                        |
      | long        | -1..1                                     | 2                   | -1                       |
      | double      | 0.01..0.1                                 | 0.001               | 0.01                     |
      | double      | 0.01..0.1                                 | 0.11                | 0.0111111                |
      | double      | -0.01..0.1                                | -0.011              | 0.01                     |
      | double      | -0.01..0.1                                | 0.11                | -0.01                    |
      | double      | 19.337..339.0                             | 19.336              | 78.838482823782          |
      | decimal     | 0.01..0.1                                 | 0.001               | 0.01                     |
      | decimal     | 0.01..0.1                                 | 0.11                | 0.0111111                |
      | decimal     | -0.01..0.1                                | -0.011              | 0.01                     |
      | decimal     | -0.01..0.1                                | 0.11                | -0.01                    |
      | decimal     | 19.337..339.0                             | 19.336              | 78.838482823782          |
      | string      | "1".."3"                                  | "0"                 | "1"                      |
      | string      | "1".."3"                                  | "#"                 | "2"                      |
      | string      | "1".."3"                                  | "4"                 | "3"                      |
      | string      | "s".."sss"                                | "S"                 | "s"                      |
      | string      | "s".."sss"                                | "j"                 | "ss"                     |
      | string      | "s".."sss"                                | "SSS"               | "sss"                    |
      | date        | 2024-05-05..2024-05-07                    | 2024-05-04          | 2024-05-06               |
      | datetime    | 2024-05-05T16:01:57..2024-05-05T16:01:59  | 2024-05-04T16:01:59 | 2024-05-05T16:01:59      |
      | datetime    | 2024-05-05T16:01:57..2024-05-05T16:01:59  | 2024-05-05T16:02:00 | 2024-05-05T16:01:58      |
      | datetime    | 2024-05-05T16:01:57..2024-05-05T16:01:59  | 2025-05-05T16:01:58 | 2024-05-05T16:01:57      |
      | datetime-tz | 2024-05-05+0100..2024-05-05T16:31:59+0100 | 2024-05-04+0000     | 2024-05-05T16:31:00+0100 |
      | datetime-tz | 2024-05-05+0100..2024-05-05T16:31:59+0100 | 2024-05-05+0010     | 2024-05-05+0100          |


  Scenario: Dependent attributes without owners can be seen only before commit
    Given transaction closes
    Given connection open schema transaction for database: typedb
    Given create attribute type: ind-attr
    Given create attribute type: dep-attr
    Given attribute(ind-attr) set annotation: @independent
    Given attribute(ind-attr) set value type: string
    Given attribute(dep-attr) set value type: string
    Given create attribute type: ref
    Given attribute(ref) set value type: string
    Given create entity type: ent
    Given entity(ent) set owns: ind-attr
    Given entity(ent) set owns: dep-attr
    Given entity(ent) set owns: ref
    Given transaction commits
    Given connection open write transaction for database: typedb
    When $ent = entity(ent) create new instance with key(ref): ent
    When $dep1 = attribute(dep-attr) put instance with value: "dep1"
    When $dep2 = attribute(dep-attr) put instance with value: "dep2"
    When $ind1 = attribute(ind-attr) put instance with value: "ind1"
    When $ind2 = attribute(ind-attr) put instance with value: "ind2"
    When entity $ent set has: $dep2
    When entity $ent set has: $ind2
    When $get_dep1 = attribute(dep-attr) get instance with value: "dep1"
    When $get_dep2 = attribute(dep-attr) get instance with value: "dep2"
    When $get_ind1 = attribute(ind-attr) get instance with value: "ind1"
    When $get_ind2 = attribute(ind-attr) get instance with value: "ind2"
    Then attribute $dep1 is none: false
    Then attribute $dep2 is none: false
    Then attribute $ind1 is none: false
    Then attribute $ind2 is none: false
    Then attribute $get_dep1 is none: false
    Then attribute $get_dep2 is none: false
    Then attribute $get_ind1 is none: false
    Then attribute $get_ind2 is none: false
    Then attribute(dep-attr) get instances contain: $dep1
    Then attribute(dep-attr) get instances contain: $dep2
    Then attribute(ind-attr) get instances contain: $ind1
    Then attribute(ind-attr) get instances contain: $ind2
    Then attribute(dep-attr) get instances contain: $get_dep1
    Then attribute(dep-attr) get instances contain: $get_dep2
    Then attribute(ind-attr) get instances contain: $get_ind1
    Then attribute(ind-attr) get instances contain: $get_ind2
    When transaction commits
    When connection open read transaction for database: typedb
    When $dep1 = attribute(dep-attr) get instance with value: "dep1"
    When $dep2 = attribute(dep-attr) get instance with value: "dep2"
    When $ind1 = attribute(ind-attr) get instance with value: "ind1"
    When $ind2 = attribute(ind-attr) get instance with value: "ind2"
    Then attribute $dep1 is none: true
    Then attribute $dep2 is none: false
    Then attribute $ind1 is none: false
    Then attribute $ind2 is none: false
    Then attribute(dep-attr) get instances contain: $dep2
    Then attribute(ind-attr) get instances contain: $ind1
    Then attribute(ind-attr) get instances contain: $ind2
    When transaction closes
    When connection open write transaction for database: typedb
    When $dep1 = attribute(dep-attr) get instance with value: "dep1"
    When $dep2 = attribute(dep-attr) get instance with value: "dep2"
    When $ind1 = attribute(ind-attr) get instance with value: "ind1"
    When $ind2 = attribute(ind-attr) get instance with value: "ind2"
    Then attribute $dep1 is none: true
    Then attribute $dep2 is none: false
    Then attribute $ind1 is none: false
    Then attribute $ind2 is none: false
    Then attribute(dep-attr) get instances contain: $dep2
    Then attribute(ind-attr) get instances contain: $ind1
    Then attribute(ind-attr) get instances contain: $ind2
    When $ent = entity(ent) get instance with key(ref): ent
    When entity $ent unset has: $dep2
    When entity $ent unset has: $ind2
    When $get_dep1 = attribute(dep-attr) get instance with value: "dep1"
    When $get_dep2 = attribute(dep-attr) get instance with value: "dep2"
    When $get_ind1 = attribute(ind-attr) get instance with value: "ind1"
    When $get_ind2 = attribute(ind-attr) get instance with value: "ind2"
    Then attribute $get_dep1 is none: true
    Then attribute $get_dep2 is none: false
    Then attribute $get_ind1 is none: false
    Then attribute $get_ind2 is none: false
    Then attribute(dep-attr) get instances contain: $get_dep2
    Then attribute(ind-attr) get instances contain: $get_ind1
    Then attribute(ind-attr) get instances contain: $get_ind2
    When transaction commits
    When connection open read transaction for database: typedb
    When $dep1 = attribute(dep-attr) get instance with value: "dep1"
    When $dep2 = attribute(dep-attr) get instance with value: "dep2"
    When $ind1 = attribute(ind-attr) get instance with value: "ind1"
    When $ind2 = attribute(ind-attr) get instance with value: "ind2"
    Then attribute $dep1 is none: true
    Then attribute $dep2 is none: true
    Then attribute $ind1 is none: false
    Then attribute $ind2 is none: false
    Then attribute(ind-attr) get instances contain: $ind1
    Then attribute(ind-attr) get instances contain: $ind2

  Scenario: Subtypes of attribute type can be inserted to an owned supertype list
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @abstract
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0
    When create attribute type: attr2
    When attribute(attr2) set supertype: attr0
    When create attribute type: ref
    When attribute(ref) set value type: string
    When create entity type: ent1
    When entity(ent1) set owns: ref
    When entity(ent1) set owns: attr0[]
    When entity(ent1) get owns(attr0) set annotation: @card(0..)
    When transaction commits

    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $attr1_val = attribute(attr1) put instance with value: "val"
    When $attr2_val1 = attribute(attr2) put instance with value: "val1"
    When entity $ent1 set has(attr0[]): [$attr1_val, $attr2_val1]
    Then transaction commits

  Scenario: Owned unique siblings of the same value can be owned by the same object
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @independent
    When attribute(attr0) set annotation: @abstract
    When create attribute type: attr1
    When attribute(attr1) set supertype: attr0
    When create attribute type: attr2
    When attribute(attr2) set supertype: attr0
    When create attribute type: ref
    When attribute(ref) set value type: string
    When create entity type: ent0
    When entity(ent0) set owns: ref
    When entity(ent0) set owns: attr0
    When entity(ent0) get owns(attr0) set annotation: @card(0..)
    When entity(ent0) get owns(attr0) set annotation: @unique
    When create entity type: ent1
    When entity(ent1) set supertype: ent0
    When entity(ent1) set owns: attr1
    When entity(ent1) set owns: attr2
    When transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $attr1 = attribute(attr1) put instance with value: "val"
    When $attr2 = attribute(attr2) put instance with value: "val"
    When entity $ent1 set has: $attr1
    When entity $ent1 set has: $attr2
    Then transaction commits

  Scenario: Owned lists are correctly validated against @unique constraint
    Given transaction closes
    Given connection open schema transaction for database: typedb
    When create attribute type: attr0
    When attribute(attr0) set value type: string
    When attribute(attr0) set annotation: @independent
    When create attribute type: ref
    When attribute(ref) set value type: string
    When create entity type: ent1
    When entity(ent1) set owns: ref
    When entity(ent1) set owns: attr0[]
    When entity(ent1) get owns(attr0) set annotation: @unique
    When transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) create new instance with key(ref): ent1
    When $val1 = attribute(attr0) put instance with value: "val1"
    When $val2 = attribute(attr0) put instance with value: "val2"
    When entity $ent1 set has(attr0[]): [$val1, $val2]
    Then transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $val1 = attribute(attr0) get instance with value: "val1"
    Then entity $ent1 set has(attr0[]): [$val1, $val1]
    Then transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $val2 = attribute(attr0) get instance with value: "val2"
    Then entity $ent1 set has(attr0[]): [$val2, $val2]
    Then transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When entity $ent1 unset has: attr0[]
    Then transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $val1 = attribute(attr0) get instance with value: "val1"
    Then entity $ent1 set has(attr0[]): [$val1, $val1]
    Then transaction commits
    When connection open write transaction for database: typedb
    When $ent1 = entity(ent1) get instance with key(ref): ent1
    When $val2 = attribute(attr0) get instance with value: "val2"
    Then entity $ent1 set has(attr0[]): [$val2, $val2]
    Then transaction commits

    # TODO: Add steps to check what @unique means for lists when it's in the spec
