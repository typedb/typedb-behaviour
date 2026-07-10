# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL Query with Expressions

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb

    Given typeql schema query
      """
      define
      struct my-struct:
        my-field value string;
      attribute my-struct-attr @independent,
        value my-struct;
      """
    Given transaction commits


  Scenario: A struct value can be created and retrieved
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $s = my-struct { my-field: "hello" };
      """
    Then uniquely identify answer concepts
      | sf                 | s                                            |
      | value:string:world | value:struct:my-struct { my-field: "hello" } |


  Scenario: A struct value can be created using a variable
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $f = "hello";
        let $s = my-struct { my-field: $f };
      """
    Then uniquely identify answer concepts
      | s                                            |
      | value:struct:my-struct { my-field: "hello" } |


  Scenario: An attribute with a struct value can be created from a literal
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $a isa my-struct-attr my-struct { my-field: "hello" };
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my-struct-attr:my-struct { my-field: "hello" } |
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $a isa my-struct-attr;
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my-struct-attr:my-struct { my-field: "hello" } |


  Scenario: An attribute with a struct value can be created from a value variable
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match let $s = my-struct { my-field: "hello" };
      insert $a isa my-struct-attr == $s;
      """
    Then uniquely identify answer concepts
      | s                                            | a                                                   |
      | value:struct:my-struct { my-field: "hello" } | attr:my-struct-attr:my-struct { my-field: "hello" } |
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $a isa my-struct-attr;
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my-struct-attr:my-struct { my-field: "hello" } |


  Scenario: A struct value's and a struct attribute's field can be accessed directly
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $a isa my-struct-attr my-struct { my-field: "world" };
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my-struct-attr:my-struct { my-field: "world" } |
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $s = my-struct { my-field: "world" };
        $a isa my-struct-attr;
        let $sf = $s.my-field;
        let $af = $a.my-field;
      """
    Then uniquely identify answer concepts
      | a                                                   | s                                            | af                 | sf                 |
      | attr:my-struct-attr:my-struct { my-field: "hello" } | value:struct:my-struct { my-field: "world" } | value:string:hello | value:string:world |


  Scenario: A field of an inner struct can be accessed directly
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      struct test-struct:
        inner value inner-struct;
      struct inner-struct:
        field value integer;
      """
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      let $s = test-struct { inner: inner-struct { field: 314 } };
      let $f = $s.inner.field;
      """
    Then uniquely identify answer concepts
      | s                                                               | f                 |
      | value:struct:test-struct { inner: inner-struct { field: 314 } } | value:integer:314 |


  Scenario: A field of a struct literal can be accessed directly
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      let $f = my-struct { my-field: "hello" }.my-field;
      """
    Then uniquely identify answer concepts
      | f                  |
      | value:string:hello |


  Scenario: A struct value's and a struct attribute field can be deconstructed
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $a isa my-struct-attr my-struct { my-field: "world" };
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my-struct-attr:my-struct { my-field: "world" } |
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $s = my-struct { my-field: "world" };
        $a isa my-struct-attr;
        let my-struct { my-field: $sf } = $s;
        let my-struct { my-field: $af } = $a;
      """
    Then uniquely identify answer concepts
      | a                                                   | s                                            | af                 | sf                 |
      | attr:my-struct-attr:my-struct { my-field: "hello" } | value:struct:my-struct { my-field: "world" } | value:string:hello | value:string:world |


  Scenario Outline: A struct can have a <value-type> valued field
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      struct test-struct:
        field value <value-type>;
      """
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $s = test-struct { field: <value> };
      """
    Then uniquely identify answer concepts
      | s                                           |
      | value:struct:test-struct { field: <value> } |

    Examples:
      | value-type  | value                              |
      | boolean     | true                               |
      | integer     | 21                                 |
      | double      | 123.456                            |
      | decimal     | 123.456dec                         |
      | string      | "alice"                            |
      | date        | 1990-01-01                         |
      | datetime    | 1990-01-01T11:22:33.123456789      |
      | datetime-tz | 1990-01-01T11:22:33 Asia/Kathmandu |
      | duration    | P1Y2M3DT4H5M6.789S                 |
      | struct      | my-struct { my-field: "hello" }    |


  Scenario Outline: A struct can have an optional <value-type> valued field
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      struct test-struct:
        field value <value-type>?;
      """
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $s = test-struct { field: <value> };
        let $p = test-struct { field: None };
        let $q = test-struct {};
      """
    Then uniquely identify answer concepts
      | s                                           | p                           | q                           |
      | value:struct:test-struct { field: <value> } | value:struct:test-struct {} | value:struct:test-struct {} |

    Examples:
      | value-type  | value                              |
      | boolean     | true                               |
      | integer     | 21                                 |
      | double      | 123.456                            |
      | decimal     | 123.456dec                         |
      | string      | "alice"                            |
      | date        | 1990-01-01                         |
      | datetime    | 1990-01-01T11:22:33.123456789      |
      | datetime-tz | 1990-01-01T11:22:33 Asia/Kathmandu |
      | duration    | P1Y2M3DT4H5M6.789S                 |
      | struct      | my-struct { my-field: "hello" }    |
