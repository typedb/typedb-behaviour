# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required query functionality of TypeDB drivers. The files in this package
# can be used to test any client application which aims to support all the operations presented in this file for the
# complete user experience. The following steps are suitable and strongly recommended for both CORE and CLOUD drivers.
# NOTE: for complete guarantees, all the drivers are also expected to cover the `connection` package.

#noinspection CucumberUndefinedStep
Feature: Driver Query

  Background: Open connection, create driver, create database
    Given typedb starts
    Given connection is open: false
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection has database: typedb

  #################
  # QUERY OPTIONS #
  #################

  Scenario: Read rows queries can include and exclude instance types
    # Does not affect
    Given set query option include_instance_types to: false
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity person, owns name, plays friendship:friend;
        relation friendship, relates friend;
        attribute name value string;
      """
    Given typeql write query
      """
      insert
        $p isa person, has name "John";
        $f isa friendship, links ($p);
      """
    Given transaction commits

    When set query option include_instance_types to: true
    Then transaction is open: false
    When connection open read transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql read query
      """
      match
        $e isa person;
        $a isa name;
        $r isa friendship;
      """
    Then answer size is: 1
    Then answer get row(0) get variable(e) try get label is not none
    Then answer get row(0) get entity(e) get type get label: person
    Then answer get row(0) get variable(a) try get label is not none
    Then answer get row(0) get attribute(a) get type get label: name
    Then answer get row(0) get variable(r) try get label is not none
    Then answer get row(0) get relation(r) get type get label: friendship
    When transaction closes

    When set query option include_instance_types to: false
    Then transaction is open: false
    When connection open read transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql read query
      """
      match
        $e isa person;
        $a isa name;
        $r isa friendship;
      """
    Then answer size is: 1
    Then answer get row(0) get variable(e) try get label is none
    Then answer get row(0) get variable(a) try get label is none
    Then answer get row(0) get variable(r) try get label is none


  Scenario: Write rows queries can include and exclude instance types
    # Does not affect
    Given set query option include_instance_types to: false
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity person, owns name, plays friendship:friend;
        relation friendship, relates friend;
        attribute name value string;
      """
    Given transaction commits

    When set query option include_instance_types to: true
    Then transaction is open: false
    When connection open write transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql write query
      """
      insert
        $e isa person, has name $a;
        $a isa name "John";
        $r isa friendship, links ($e);
      """
    Then answer size is: 1
    Then answer get row(0) get variable(e) try get label is not none
    Then answer get row(0) get entity(e) get type get label: person
    Then answer get row(0) get variable(a) try get label is not none
    Then answer get row(0) get attribute(a) get type get label: name
    Then answer get row(0) get variable(r) try get label is not none
    Then answer get row(0) get relation(r) get type get label: friendship
    When transaction closes

    When set query option include_instance_types to: false
    Then transaction is open: false
    When connection open write transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql write query
      """
      insert
        $e isa person, has name $a;
        $a isa name "John";
        $r isa friendship, links ($e);
      """
    Then answer size is: 1
    Then answer get row(0) get variable(e) try get label is none
    Then answer get row(0) get variable(a) try get label is none
    Then answer get row(0) get variable(r) try get label is none


  Scenario: Read document queries are not controlled by the include_instance_types option
    # Does not affect
    Given set query option include_instance_types to: false
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity person, owns name; attribute name value string;
      """
    Given typeql write query
      """
      insert $p isa person, has name "John";
      """
    Given transaction commits

    When set query option include_instance_types to: true
    Then transaction is open: false
    When connection open read transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql read query
      """
      match
        attribute $type;
        $instance isa $type;
      fetch {
        "instance": $instance,
        "type": $type,
      };
      """
    Then answer size is: 1
    Then answer contains document:
    """
    {
        "instance": "John",
        "type": {
            "kind": "attribute",
            "label": "name",
            "valueType": "string"
        }
    }
    """
    When transaction closes

    When set query option include_instance_types to: false
    Then transaction is open: false
    When connection open read transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql read query
      """
      match
        attribute $type;
        $instance isa $type;
      fetch {
        "instance": $instance,
        "type": $type,
      };
      """
    Then answer size is: 1
    Then answer contains document:
    """
    {
        "instance": "John",
        "type": {
            "kind": "attribute",
            "label": "name",
            "valueType": "string"
        }
    }
    """


  Scenario: Write documents queries are not controlled by the include_instance_types option
    # Does not affect
    Given set query option include_instance_types to: false
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity person, owns name;
        attribute name value string;
      """
    Given transaction commits

    When set query option include_instance_types to: true
    Then transaction is open: false
    When connection open write transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql write query
      """
      match
        attribute $type;
      insert
        $instance isa $type "John";
      fetch {
        "instance": $instance,
        "type": $type,
      };
      """
    Then answer size is: 1
    Then answer contains document:
    """
    {
        "instance": "John",
        "type": {
            "kind": "attribute",
            "label": "name",
            "valueType": "string"
        }
    }
    """
    When transaction closes

    When set query option include_instance_types to: false
    Then transaction is open: false
    When connection open write transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql write query
      """
      match
        attribute $type;
      insert
        $instance isa $type "John";
      fetch {
        "instance": $instance,
        "type": $type,
      };
      """
    Then answer size is: 1
    Then answer contains document:
    """
    {
        "instance": "John",
        "type": {
            "kind": "attribute",
            "label": "name",
            "valueType": "string"
        }
    }
    """

  @ignore-typedb-http
  Scenario: Query option prefetch_size should be >= 1
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When set query option prefetch_size to: 0

    Then typeql write query; fails with a message containing: "Invalid query option: prefetch size"
      """
      insert $p isa person;
      """
    Then typeql read query; fails with a message containing: "Invalid query option: prefetch size"
      """
      insert $p isa person;
      """
    Then typeql write query; fails with a message containing: "Invalid query option: prefetch size"
      """
      match $pt label person;
      insert $p isa $pt;
      fetch {"pt": $pt};
      """
    Then typeql read query; fails with a message containing: "Invalid query option: prefetch size"
      """
      match $pt label person;
      fetch {"pt": $pt};
      """

  @ignore-typedb-http
  Scenario: Row queries work the same with different prefetch_size options
    Given set query option prefetch_size to: 1
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity person, owns name;
        attribute name value string;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert
        $alice isa name "Alice";
        $p isa person, has $alice;
        $p2 isa person, has name "Bob";
      """
    Then answer size is: 1
    Then answer get row(0) get attribute(alice) get type get label: name
    Then answer get row(0) get attribute(alice) get value is: "Alice"
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa person, has $n;
      sort $n;
      """
    Then answer size is: 2
    Then answer get row(0) get attribute(n) get value is: "Alice"
    Then answer get row(1) get attribute(n) get value is: "Bob"
    When transaction closes

    When set query option prefetch_size to: 100000

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
        $p isa person;
      insert
        $charlie isa name "Charlie";
        $p2 isa person, has $charlie;
      """
    Then answer size is: 2
    Then answer get row(0) get attribute(charlie) get type get label: name
    Then answer get row(0) get attribute(charlie) get value is: "Charlie"
    Then answer get row(1) get attribute(charlie) get type get label: name
    Then answer get row(1) get attribute(charlie) get value is: "Charlie"
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa person, has $n;
      sort $n;
      """
    Then answer size is: 4
    Then answer get row(0) get attribute(n) get value is: "Alice"
    Then answer get row(1) get attribute(n) get value is: "Bob"
    Then answer get row(2) get attribute(n) get value is: "Charlie"
    Then answer get row(3) get attribute(n) get value is: "Charlie"
    When transaction closes

    When set query option prefetch_size to: 2

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
        $p isa person;
      insert
        $donald isa name "Donald";
        $p2 isa person, has $donald;
      """
    Then answer size is: 4
    Then answer get row(0) get attribute(donald) get value is: "Donald"
    Then answer get row(1) get attribute(donald) get value is: "Donald"
    Then answer get row(2) get attribute(donald) get value is: "Donald"
    Then answer get row(3) get attribute(donald) get value is: "Donald"
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa person, has $n;
      sort $n;
      """
    Then answer size is: 8
    Then answer get row(0) get attribute(n) get value is: "Alice"
    Then answer get row(1) get attribute(n) get value is: "Bob"
    Then answer get row(2) get attribute(n) get value is: "Charlie"
    Then answer get row(3) get attribute(n) get value is: "Charlie"
    Then answer get row(4) get attribute(n) get value is: "Donald"
    Then answer get row(5) get attribute(n) get value is: "Donald"
    Then answer get row(6) get attribute(n) get value is: "Donald"
    Then answer get row(7) get attribute(n) get value is: "Donald"


  @ignore-typedb-http
  Scenario: Document queries work the same with different prefetch_size options
    Given set query option prefetch_size to: 1
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity person, owns name;
        attribute name value string;
      """
    Given transaction commits

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert
        $alice isa name "Alice";
        $p isa person, has $alice;
        $p2 isa person, has name "Bob";
      fetch {
        "alice": $alice
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      { "alice": "Alice" }
      """
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa person, has $n;
      sort $n;
      fetch {
        "n": $n
      };
      """
    Then answer size is: 2
    Then answer contains document:
      """
      { "n": "Alice" }
      """
    Then answer contains document:
      """
      { "n": "Bob" }
      """
    When transaction closes

    When set query option prefetch_size to: 100000

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
        $p isa person;
      insert
        $charlie isa name "Charlie";
        $p2 isa person, has $charlie;
      fetch {
        "charlie": $charlie
      };
      """
    Then answer size is: 2
    Then answer contains document:
      """
      { "charlie": "Charlie" }
      """
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa person, has $n;
      sort $n;
      fetch {
        "n": $n
      };
      """
    Then answer size is: 4
    Then answer contains document:
      """
      { "n": "Alice" }
      """
    Then answer contains document:
      """
      { "n": "Bob" }
      """
    Then answer contains document:
      """
      { "n": "Charlie" }
      """
    When transaction closes

    When set query option prefetch_size to: 2

    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      match
        $p isa person;
      insert
        $donald isa name "Donald";
        $p2 isa person, has $donald;
      fetch {
        "donald": $donald
      };
      """
    Then answer size is: 4
    Then answer contains document:
      """
      { "donald": "Donald" }
      """
    When transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $p isa person, has $n;
      sort $n;
      fetch {
        "n": $n
      };
      """
    Then answer size is: 8
    Then answer contains document:
      """
      { "n": "Alice" }
      """
    Then answer contains document:
      """
      { "n": "Bob" }
      """
    Then answer contains document:
      """
      { "n": "Charlie" }
      """
    Then answer contains document:
      """
      { "n": "Donald" }
      """


  Scenario: Row queries can request the query structure to be included in response
    Given set query option include_query_structure to: true
    When connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match let $x = 1;
    """
    Then answers have query structure:
    """
    Pipeline([
      Match([
        Expression(let $x = 1, $x, [])
      ])
    ])
    """
    Given transaction closes


  ###########
  # QUERIES #
  ###########

  Scenario: Driver processes ok query answers correctly
    Given connection open schema transaction for database: typedb
    When get answers of typeql schema query
      """
      define entity person;
      """
    Then answer type is: ok
    Then answer type is not: concept rows
    Then answer type is not: concept documents
    Then answer unwraps as ok
    Then transaction commits


    # TODO: Test optionals when introduced
  Scenario: Driver processes concept row query answers correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person owns name @key; attribute name, value string;
      """
    When get answers of typeql read query
      """
      match entity $p;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept documents
    Then answer unwraps as concept rows
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 1
    Then answer column names are:
      | p |
    Then answer get row(0) query type is: read
    Then answer get row(0) query type is not: schema
    Then answer get row(0) query type is not: write
    Then answer get row(0) get concepts size is: 1
    Then answer get row(0) get entity type(p) get label: person
    Then answer get row(0) get entity type by index of variable(p) get label: person

    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 1
    Then answer column names are:
      | p |
      | n |
    Then answer get row(0) get concepts size is: 2
    Then answer get row(0) get entity type(p) get label: person
    Then answer get row(0) get attribute type(n) get label: name
    Then answer get row(0) get entity type by index of variable(p) get label: person
    Then answer get row(0) get attribute type by index of variable(n) get label: name

    When typeql schema query
      """
      define attribute age, value integer;
      """
    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 2
    Then answer column names are:
      | p |
      | n |
    Then answer get row(0) query type is: read
    Then answer get row(0) query type is not: schema
    Then answer get row(0) query type is not: write
    Then answer get row(0) get concepts size is: 2
    Then answer get row(0) get entity type(p) get label: person
    Then answer get row(0) get attribute type(n) get label: name
    Then answer get row(0) get entity type by index of variable(p) get label: person
    Then answer get row(0) get attribute type by index of variable(n) get label: name
    Then answer get row(1) query type is: read
    Then answer get row(1) query type is not: schema
    Then answer get row(1) query type is not: write
    Then answer get row(1) get concepts size is: 2
    Then answer get row(1) get entity type(p) get label: person
    Then answer get row(1) get attribute type(n) get label: age
    Then answer get row(1) get entity type by index of variable(p) get label: person
    Then answer get row(1) get attribute type by index of variable(n) get label: age
    Then transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match entity $p; attribute $n;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 2
    Then answer column names are:
      | p |
      | n |
    Then answer get row(0) get concepts size is: 2
    Then answer get row(0) get entity type(p) get label: person
    Then answer get row(0) get attribute type(n) get label: name
    Then answer get row(0) get entity type by index of variable(p) get label: person
    Then answer get row(0) get attribute type by index of variable(n) get label: name
    Then answer get row(1) get concepts size is: 2
    Then answer get row(1) get entity type(p) get label: person
    Then answer get row(1) get attribute type(n) get label: age
    Then answer get row(1) get entity type by index of variable(p) get label: person
    Then answer get row(1) get attribute type by index of variable(n) get label: age

    When get answers of typeql read query
      """
      match $p isa person;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept documents
    Then answer size is: 0

    When transaction closes
    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $p isa person, has name "John";
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept documents
    Then answer query type is: write
    Then answer query type is not: schema
    Then answer query type is not: read
    Then answer size is: 1
    Then answer column names are:
      | p |
    Then answer get row(0) query type is: write
    Then answer get row(0) query type is not: schema
    Then answer get row(0) query type is not: read
    Then answer get row(0) get concepts size is: 1
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get entity by index of variable(p) get type get label: person

    When get answers of typeql read query
      """
      match $p isa person, has name $a;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 1
    Then answer column names are:
      | p |
      | a |
    Then answer get row(0) get concepts size is: 2
    Then answer get row(0) get entity(p) get type get label: person
    Then answer get row(0) get entity by index of variable(p) get type get label: person
    Then answer get row(0) get attribute(a) get type get label: name
    Then answer get row(0) get attribute(a) get value is: "John"
    Then answer get row(0) get attribute by index of variable(a) get type get label: name
    Then answer get row(0) get attribute by index of variable(a) get value is: "John"
    Then transaction commits


  Scenario: Driver processes concept document query answers from read queries correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity person owns id @key, owns name @card(0..);
      entity empty-person;
      entity nameless-person, owns name;
      attribute id, value integer;
      attribute name, value string;
      """
    When get answers of typeql read query
      """
      match
        $x isa! person;
      fetch {
        "all attributes": { $x.* },
      };
      """
    Then answer type is: concept documents
    Then answer type is not: ok
    Then answer type is not: concept rows
    Then answer unwraps as concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 0
    When transaction commits

    When connection open write transaction for database: typedb
    When typeql write query
    """
    insert
    $z isa person, has id 1;
    $y isa person, has id 2, has name "Yan";
    $x isa person, has id 3, has name "Xena", has name "Warrior Princess";
    $e isa empty-person;
    $n isa nameless-person;
    """
    When get answers of typeql read query
      """
      match
        $x isa! person;
      fetch {
        "all attributes": { $x.* },
      };
      """
    Then answer type is: concept documents
    Then answer type is not: ok
    Then answer type is not: concept rows
    Then answer unwraps as concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 3
    Then answer contains document:
    """
    { "all attributes": { "id": 1 } }
    """
    Then answer contains document:
    """
    {
      "all attributes": {
        "id": 2,
        "name": [ "Yan" ]
      }
    }
    """
    Then answer contains document:
    """
    {
        "all attributes": {
            "id": 3,
            "name": [
                "Warrior Princess",
                "Xena"
            ]
        }
    }
    """
    Then answer does not contain document:
    """
    { "all attributes": { "id": 2 } }
    """
    Then answer does not contain document:
    """
    {
      "all attributes": {
        "id": 2,
        "name": [
            "Warrior Princess",
            "Xena"
        ]
      }
    }
    """
    When transaction commits
    When connection open read transaction for database: typedb

    When get answers of typeql read query
      """
      match
        $x isa! person, has $a;
        $a isa! $t;
      fetch {
        "single attribute type": $t,
        "single attribute": $a,
      };
      """
    Then answer type is: concept documents
    Then answer type is not: ok
    Then answer type is not: concept rows
    Then answer unwraps as concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 6
    Then answer contains document:
    """
    {
        "single attribute": "Yan",
        "single attribute type": {
            "kind": "attribute",
            "label": "name",
            "valueType": "string"
        }
    }
    """
    Then answer contains document:
    """
    {
        "single attribute": 1,
        "single attribute type": {
            "kind": "attribute",
            "label": "id",
            "valueType": "integer"
        }
    }
    """

    When get answers of typeql read query
      """
      match
        $x isa! empty-person;
      fetch {
        "empty-result": { $x.* },
      };
      """
    Then answer type is: concept documents
    Then answer type is not: ok
    Then answer type is not: concept rows
    Then answer unwraps as concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 1
    Then answer contains document:
    """
    {
        "empty-result": { }
    }
    """

    When get answers of typeql read query
      """
      match
        $x isa! nameless-person;
      fetch {
        "null-result": $x.name,
      };
      """
    Then answer type is: concept documents
    Then answer type is not: ok
    Then answer type is not: concept rows
    Then answer unwraps as concept documents
    Then answer query type is: read
    Then answer query type is not: schema
    Then answer query type is not: write
    Then answer size is: 1
    Then answer contains document:
    """
    {
        "null-result": null
    }
    """


  Scenario: Driver processes concept document query answers from write queries correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person owns name @card(1); attribute name, value string; attribute age @abstract;
      """
    Given transaction commits
    When connection open write transaction for database: typedb
    When get answers of typeql write query
      """
      insert $p isa person, has name "John";
      fetch {
        "name": $p.name,
        "sub fetch": {
          "all attributes": { $p.* },
        }
      };
      """
    Then answer type is: concept documents
    Then answer type is not: ok
    Then answer type is not: concept rows
    Then answer query type is: write
    Then answer query type is not: schema
    Then answer query type is not: read
    Then answer size is: 1
    Then answer contains document:
    """
    {
      "name": "John",
      "sub fetch": {
        "all attributes": {
          "name": "John"
        }
      }
    }
    """
    When get answers of typeql write query
      """
      match
      attribute $a;
      insert
      $p1 isa person, has name "Alice";
      $p2 isa person, has name "Bob";
      fetch {
        "Alice's name": $p1.name,
        "sub fetch": {
          "Bob's all": { $p2.* },
        }
      };
      """
    Then answer type is: concept documents
    Then answer type is not: ok
    Then answer type is not: concept rows
    Then answer query type is: write
    Then answer query type is not: schema
    Then answer query type is not: read
    Then answer size is: 2
    Then answer contains document:
    """
    {
      "Alice's name": "Alice",
      "sub fetch": {
        "Bob's all": {
          "name": "Bob"
        }
      }
    }
    """
    Then answer does not contain document:
    """
    {
      "Alice's name": "Bob",
      "sub fetch": {
        "Bob's all": {
          "name": "Alice"
        }
      }
    }
    """


  Scenario: Driver processes query structure correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute ref value integer;
      attribute name value string;
      relation friendship, relates friend @card(2);
      entity person,
        owns name, owns ref @key,
        plays friendship:friend;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql analyze
      """
      with fun n_pi($n: integer) -> double:
        match let $n_pi = $n * 3.14; # close enough?
      return first $n_pi;

      with fun sum_refs() -> integer:
        match $r isa ref;
      return sum($r);

      match
        $p1 isa! person, has name $n1;
        $n1 contains "son";
        $f isa friendship, links (friend: $p1, $p2);
        $p1 is $p2;
        $p2 iid 0x1234567890112345678901;
        let $three = 3;
        let $x = ceil(2 * n_pi($three));
    """

    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match([
        IsaExact($p1, person), Has($p1, $n1), Isa($n1, name),
        Comparison($n1, "son", contains),
        Isa($f, friendship), Links($f, $p1, friend), Links($f, $p2, $_),
        Is($p1, $p2),
        Iid($p2, 0x1234567890112345678901),
        expression(let $three = 3, $three, []),
        FunctionCall(n_pi($three), [$_], [$three]),
        Expression(let $x = ceil(2 * n_pi($three)), $x, [$_])
      ])
    ])
    """
    Then analyzed query preamble contains:
    """
    Function(
      [$n],
      Single(first, [$n_pi]),
      Pipeline([
        Match([
          Expression(let $n_pi = $n * 3.14, $n_pi, [$n])
        ])
      ])
    )
    """
    Then analyzed query preamble contains:
    """
    Function(
      [],
      Reduce([Reducer(sum,[$r])]),
      Pipeline([
        Match([
          Isa($r, ref)
        ])
      ])
    )
    """
    When get answers of typeql analyze
      """
      match
        entity $p1;
        $p1 sub! person, owns $n1;
        $n1 label name;
        $n1 value string;
        $f sub friendship, relates friend;
        $p1 plays friendship:friend;
        $p2 plays $role;
      """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match([
        Kind(entity, $p1),
        SubExact($p1, person), Owns($p1, $n1),
        Label($n1, name),
        Value($n1, string),
        Sub($f, friendship), Relates($f, friend),
        Plays($p1, friendship:friend),
        Plays($p2, $role)
      ])
    ])
    """
    When get answers of typeql analyze
      """
      match
        $p isa person;
        { $p has name $id; } or { $p has ref $id; };
        not { $id == 5; };
        try { $f isa friendship, links (friend: $p); };
      """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match([
        Isa($p, person),
        Or([
          [Has($p, $id), Isa($id, name)],
          [Has($p, $id), Isa($id, ref)]
        ]),
        not([Comparison($id, 5, ==)]),
        Try([Isa($f, friendship), Links($f, $p, friend)])
      ])
    ])
    """

    When get answers of typeql analyze
    """
    match
     $p isa person;
     $q isa person;
     $n isa name == "John";
    insert
     $p has $n;
    delete
      has $n of $p;
      $q;
    update
      $p has $n;
    put
      $p has $n;
    distinct;
    match
      try { $p has ref $ref; };
    require $ref;
    select $ref, $n;
    reduce $ref_sum = sum($ref) groupby $n;
    sort $n desc;
    offset 1;
    limit 1;
    """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match(
        [Isa($p, person), Isa($q, person), Isa($n, name), Comparison($n, "John", ==)]
      ),
      Insert([Has($p, $n)]),
      Delete([$q], [Has($p, $n)]),
      Update([Has($p, $n)]),
      Put([Has($p, $n)]),
      Distinct(),
      Match([
        Try([Has($p, $ref), Isa($ref, ref)])
      ]),
      Require([$ref]),
      Select([$n, $ref]),
      Reduce(
        [ReduceAssign($ref_sum, Reducer(sum, [$ref]))],
        [$n]
      ),
      Sort([desc($n)]),
      Offset(1),
      Limit(1)
    ])
    """
    Given transaction closes


  Scenario: Analyze returns the annotations of variables in the query
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      attribute ref value integer;
      attribute name value string;
      entity dummy;
      entity subdummy sub dummy;
      relation friendship, relates friend @card(2);
      entity person,
        owns name, owns ref @key,
        plays friendship:friend;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql analyze
      """
      match
        $x isa person, has name $n, has ref $r;
        { $r == 2; } or { $r == 3; };
      select $n, $x;
      delete $n;
      insert $x has name "John";
      match $n1 isa name == "J";
      put $x has name $n1;
      """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And(
          { $n: instance([name]), $r: instance([ref]), $x: instance([person]) },
          [
            Or([
              And({ $r: instance([ref]) }, []),
              And({ $r: instance([ref]) }, [])
            ])
          ]
        )
      ),
      Select(),
      Delete(
        And({ $n: instance([name]), $x: instance([person]) }, [])
      ),
      Insert(
        And({ $_: instance([name]), $x: instance([person]) }, [])
      ),
      Match(
        And({ $n1:instance([name]), $x: instance([person]) }, [])
      ),
      Put(
        And({ $n1:instance([name]), $x: instance([person]) }, [])
      )
    ])
    """
    When get answers of typeql analyze
      """
      with
      fun names_of($p: person) -> { name }:
      match $p has name $n;
      return { $n };

      match
        $p isa person, has ref $r;
      fetch {
        "ref": $r,
        "names": [names_of($p)],
        "friends": [
          match $_ isa friendship, links (friend: $p, friend: $f);
          fetch {
            "name": (match $f has name $nf; return first $nf;)
          };
        ]
      };
      """
    Then analyzed preamble annotations contains:
      """
      Function(
        [instance([person])],
        stream([instance([name])]),
        Pipeline([
          Match(
            And({ $n: instance([name]), $p: instance([person]) }, [])
          )
        ])
      )
      """
    Then analyzed query pipeline annotations are:
      """
      Pipeline([
        Match(
          And({ $p: instance([person]), $r: instance([ref]) }, [])
        )
      ])
      """
    Then analyzed fetch annotations are:
    """
      {
        friends: List({
          name: [string]
        }),
        names: List([string]),
        ref: [integer]
      }
    """


  Scenario: Analyze handles unsatisfiable schema queries and errors properly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      entity person;
      relation friendship, relates friend;
      relation new-relation, relates new-role;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql analyze
    """
    match
     $p sub! person;
    """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match(
        [SubExact($p, person)]
      )
    ])
    """
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And({$p: type([])}, [])
      )
    ])
    """

    When get answers of typeql analyze
    """
    match
     $r sub friendship, relates new-role;
    """
    Then analyzed query pipeline structure is:
    """
    Pipeline([
      Match(
        [Sub($r, friendship), Relates($r, new-role)]
      )
    ])
    """
    # Rolename introduces an intermediate variable.
    Then analyzed query pipeline annotations are:
    """
    Pipeline([
      Match(
        And({$_: type([]), $r: type([])}, [])
      )
    ])
    """

    Given transaction closes

    # Errors
    Given connection open read transaction for database: typedb
    Then typeql analyze; parsing fails
    """
    match
     This isnt valid TypeQL;
    """

    Then typeql analyze; fails with a message containing: "Type-inference was unable to find compatible types for the pair of variables 'x' & 'p' across a constraint"
    """
    match
     $p sub! person; $x isa! $p;
    """
    Given transaction closes


#  Scenario: Driver processes query errors correctly
#    Given connection open schema transaction for database: typedb
#    Then typeql schema query; fails
#      """
#      """
#    Then typeql schema query; fails
#      """
#
#      """
#    Then typeql read query; fails with a message containing: "Error analysing query"
#      """
#      match $r label non-existing;
#      """
#    Then typeql schema query; fails with a message containing: "Query parsing failed"
#      """
#      define entity entity;
#      """
#    Then typeql schema query; fails with a message containing: "Failed to execute define query"
#      """
#      define attribute name owns name;
#      """
#
#  Scenario: Driver can concurrently process read queries without interruptions
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define
#      entity person0;
#      entity person1;
#      entity person2;
#      entity person3;
#      entity person4;
#      entity person5;
#      entity person6;
#      entity person7;
#      entity person8;
#      entity person9;
#      """
#    When concurrently get answers of typeql read query 10 times
#      """
#      match entity $p;
#      """
#    Then concurrently process 1 row from answers
#    Then concurrently process 1 row from answers
#    Then concurrently process 3 rows from answers
#    When get answers of typeql read query
#      """
#      match entity $p;
#      """
#    Then answer size is: 10
#    Then concurrently process 5 rows from answers
#    Then concurrently process 1 row from answers; fails
#
#
#  Scenario: Driver's concurrent processing of read queries answers is not interrupted by schema queries if answers are prefetched
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define
#      entity person0;
#      entity person1;
#      entity person2;
#      entity person3;
#      entity person4;
#      entity person5;
#      entity person6;
#      entity person7;
#      entity person8;
#      entity person9;
#      """
#    When concurrently get answers of typeql read query 10 times
#      """
#      match entity $p;
#      """
#    Then concurrently process 1 row from answers
#    Then concurrently process 1 row from answers
#    Then concurrently process 3 rows from answers
#    When typeql schema query
#      """
#      define entity person10;
#      """
#    Then concurrently process 1 rows from answers
#    Then concurrently process 3 rows from answers
#    Then concurrently process 1 rows from answers
#    Then concurrently process 1 row from answers; fails
#
#
#  Scenario: Driver's concurrent processing of read queries answers is interrupted by schema queries if answers are not prefetched
#    Given connection open schema transaction for database: typedb
#    Given typeql schema query
#      """
#      define
#      entity person0;
#      entity person1;
#      entity person2;
#      entity person3;
#      entity person4;
#      entity person5;
#      entity person6;
#      entity person7;
#      entity person8;
#      entity person9;
#      """
#    When concurrently get answers of typeql read query 10 times
#      """
#      match entity $p;
#      """
#    Then concurrently process 1 row from answers
#    Then concurrently process 1 row from answers
#    Then concurrently process 3 rows from answers
#    When typeql schema query
#      """
#      define entity person10;
#      """
#    # TODO: Uncomment this when we can set prefetch sizes to 0
##    Then concurrently process 1 rows from answers; fails
#
#
##  TODO: Repeat two tests above for:
##  read results + write query (not) interrupting them
##  write results + schema query (not) interrupting them
##  write results + write query (not) interrupting them
##  Consider adding tests for commit, rollback, and close doing the same!
