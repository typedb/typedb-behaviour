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
      struct my_struct {
        my_field: string,
      };
      attribute my_struct_attr @independent,
        value my_struct;
      """
    Given transaction commits


  Scenario: A struct value can be created and retrieved
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $s = my_struct { my_field: "hello" };
      """
    Then uniquely identify answer concepts
      | sf                 | s                                            |
      | value:string:world | value:struct:my_struct { my_field: "hello" } |


  Scenario: A struct value can be created using a variable
    Given connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $f = "hello";
        let $s = my_struct { my_field: $f };
      """
    Then uniquely identify answer concepts
      | s                                            |
      | value:struct:my_struct { my_field: "hello" } |


  Scenario: An attribute with a struct value can be created from a literal
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $a isa my_struct_attr my_struct { my_field: "hello" };
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my_struct_attr:my_struct { my_field: "hello" } |
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $a isa my_struct_attr;
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my_struct_attr:my_struct { my_field: "hello" } |


  Scenario: An attribute with a struct value can be created from a value variable
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match let $s = my_struct { my_field: "hello" };
      insert $a isa my_struct_attr == $s;
      """
    Then uniquely identify answer concepts
      | s                                            | a                                                   |
      | value:struct:my_struct { my_field: "hello" } | attr:my_struct_attr:my_struct { my_field: "hello" } |
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $a isa my_struct_attr;
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my_struct_attr:my_struct { my_field: "hello" } |


  Scenario: A struct value's and a struct attribute's field can be accessed directly
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $a isa my_struct_attr my_struct { my_field: "world" };
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my_struct_attr:my_struct { my_field: "world" } |
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $s = my_struct { my_field: "world" };
        $a isa my_struct_attr;
        let $sf = $s.my_field;
        let $af = $a.my_field;
      """
    Then uniquely identify answer concepts
      | a                                                   | s                                            | af                 | sf                 |
      | attr:my_struct_attr:my_struct { my_field: "hello" } | value:struct:my_struct { my_field: "world" } | value:string:hello | value:string:world |


  Scenario: A field of an inner struct can be accessed directly
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      struct test_struct {
        inner: inner_struct,
      };
      struct inner_struct {
        field: integer,
      };
      """
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      let $s = test_struct { inner: inner_struct { field: 314 } };
      let $f = $s.inner.field;
      """
    Then uniquely identify answer concepts
      | s                                                               | f                 |
      | value:struct:test_struct { inner: inner_struct { field: 314 } } | value:integer:314 |


  Scenario: A field of a struct literal can be accessed directly
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
      let $f = my_struct { my_field: "hello" }.my_field;
      """
    Then uniquely identify answer concepts
      | f                  |
      | value:string:hello |


  Scenario: A struct value's and a struct attribute field can be deconstructed
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $a isa my_struct_attr my_struct { my_field: "world" };
      """
    Then uniquely identify answer concepts
      | a                                                   |
      | attr:my_struct_attr:my_struct { my_field: "world" } |
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $s = my_struct { my_field: "world" };
        $a isa my_struct_attr;
        let my_struct { my_field: $sf } = $s;
        let my_struct { my_field: $af } = $a;
      """
    Then uniquely identify answer concepts
      | a                                                   | s                                            | af                 | sf                 |
      | attr:my_struct_attr:my_struct { my_field: "hello" } | value:struct:my_struct { my_field: "world" } | value:string:hello | value:string:world |


  Scenario Outline: A struct can have a <value_type> valued field
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      struct test_struct {
        field: <value_type>,
      };
      """
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $s = test_struct { field: <value> };
      """
    Then uniquely identify answer concepts
      | s                                           |
      | value:struct:test_struct { field: <value> } |

    Examples:
      | value_type  | value                              |
      | boolean     | true                               |
      | integer     | 21                                 |
      | double      | 123.456                            |
      | decimal     | 123.456dec                         |
      | string      | "alice"                            |
      | date        | 1990-01-01                         |
      | datetime    | 1990-01-01T11:22:33.123456789      |
      | datetime-tz | 1990-01-01T11:22:33 Asia/Kathmandu |
      | duration    | P1Y2M3DT4H5M6.789S                 |
      | my_struct   | my_struct { my_field: "hello" }    |


  Scenario Outline: A struct can have an optional <value_type> valued field
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      struct test_struct {
        field: <value_type>?,
      };
      """
    Then transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $s = test_struct { field: <value> };
        let $p = test_struct { field: None };
        let $q = test_struct {};
      """
    Then uniquely identify answer concepts
      | s                                           | p                           | q                           |
      | value:struct:test_struct { field: <value> } | value:struct:test_struct {} | value:struct:test_struct {} |

    Examples:
      | value_type  | value                              |
      | boolean     | true                               |
      | integer     | 21                                 |
      | double      | 123.456                            |
      | decimal     | 123.456dec                         |
      | string      | "alice"                            |
      | date        | 1990-01-01                         |
      | datetime    | 1990-01-01T11:22:33.123456789      |
      | datetime-tz | 1990-01-01T11:22:33 Asia/Kathmandu |
      | duration    | P1Y2M3DT4H5M6.789S                 |
      | my_struct   | my_struct { my_field: "hello" }    |
