# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeDB HTTP Endpoint

  Background: Open connection, create database
    Given typedb starts
    Given connection is open: false
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection has database: typedb

  ###########
  # GENERAL #
  ###########

  Scenario: Health check works for both authenticated and non-authenticated connection
    Then connection is healthy: true
    When connection closes
    Then connection is open: false
    Then connection is healthy: true


  Scenario: Version and distribution are returned from version
    Then get endpoint(/v1/version) contains field: distribution
    Then get endpoint(/v1/version) contains field: version
    When connection closes
    Then connection is open: false
    Then get endpoint(/v1/version) contains field: distribution
    Then get endpoint(/v1/version) contains field: version


  Scenario: Root endpoints redirect to version endpoint
    Then get endpoint(/v1) redirects to: /v1/version
    Then get endpoint(/) redirects to: /v1/version
    When connection closes
    Then connection is open: false
    Then get endpoint(/v1) redirects to: /v1/version
    Then get endpoint(/) redirects to: /v1/version

  ##################
  # AUTHENTICATION #
  ##################

  Scenario: Authentication is invalidated after the authentication token TTL
    Then connection create database: typedb2
    When wait authentication token expiration
    Then connection create database: typedb3; fails with a message containing: "Invalid token"

    When connection opens with default authentication
    Then connection create database: typedb3

  Scenario: Database methods are not available without authentication
    When connection closes
    Then connection is open: false

    Then connection create database: typedb; fails with a message containing: "Missing token"
    Then connection get all databases; fails with a message containing: "Missing token"
    Then connection get database: typedb; fails with a message containing: "Missing token"
    Then connection delete database: typedb; fails with a message containing: "Missing token"

    Then with a wrong token, connection create database: typedb; fails with a message containing: "Invalid token"
    Then with a wrong token, connection get all databases; fails with a message containing: "Invalid token"
    Then with a wrong token, connection get database: typedb; fails with a message containing: "Invalid token"
    Then with a wrong token, connection delete database: typedb; fails with a message containing: "Invalid token"


  Scenario: User methods are not available without authentication
    When connection closes
    Then connection is open: false
    Then create user with username 'user', password 'password'; fails with a message containing: "Missing token"
    Then get all users; fails with a message containing: "Missing token"
    Then get user: user; fails with a message containing: "Missing token"
    Then get user(user) update password to 'password'; fails with a message containing: "Missing token"
    Then delete user: user2; fails with a message containing: "Missing token"

    Then with a wrong token, create user with username 'user', password 'password'; fails with a message containing: "Invalid token"
    Then with a wrong token, get all users; fails with a message containing: "Invalid token"
    Then with a wrong token, get user: user; fails with a message containing: "Invalid token"
    Then with a wrong token, get user(user) update password to 'password'; fails with a message containing: "Invalid token"
    Then with a wrong token, delete user: user2; fails with a message containing: "Invalid token"


  Scenario: Transaction methods are not available without authentication
    When connection closes
    Then connection is open: false
    Then connection open schema transaction for database: typedb; fails with a message containing: "Missing token"
    Then connection open write transaction for database: typedb; fails with a message containing: "Missing token"
    Then connection open read transaction for database: typedb; fails with a message containing: "Missing token"
    Then transaction closes; fails with a message containing: "Missing token"
    Then transaction commits; fails with a message containing: "Missing token"
    Then transaction rollbacks; fails with a message containing: "Missing token"
    Then typeql schema query; fails with a message containing: "Missing token"
      """
      define entity person;
      """
    Then typeql write query; fails with a message containing: "Missing token"
      """
      insert $p isa person;
      """
    Then typeql read query; fails with a message containing: "Missing token"
      """
      match entity $x;
      """

    Then with a wrong token, connection open schema transaction for database: typedb; fails with a message containing: "Invalid token"
    Then with a wrong token, connection open write transaction for database: typedb; fails with a message containing: "Invalid token"
    Then with a wrong token, connection open read transaction for database: typedb; fails with a message containing: "Invalid token"
    Then with a wrong token, transaction closes; fails with a message containing: "Invalid token"
    Then with a wrong token, transaction commits; fails with a message containing: "Invalid token"
    Then with a wrong token, transaction rollbacks; fails with a message containing: "Invalid token"
    Then with a wrong token, typeql schema query; fails with a message containing: "Invalid token"
      """
      define entity person;
      """
    Then with a wrong token, typeql write query; fails with a message containing: "Invalid token"
      """
      insert $p isa person;
      """
    Then with a wrong token, typeql read query; fails with a message containing: "Invalid token"
      """
      match entity $x;
      """


  Scenario: Query methods are not available without authentication
    When connection closes
    Then connection is open: false

    Then one-shot query with schema transaction for database typedb: typeql schema query; fails with a message containing: "Missing token"
      """
      define entity person;
      """
    Then one-shot query with write transaction for database typedb: typeql write query; fails with a message containing: "Missing token"
      """
      insert $p isa person;
      """
    Then one-shot query with read transaction for database typedb: typeql read query; fails with a message containing: "Missing token"
      """
      match entity $x;
      """

    Then with a wrong token, one-shot query with schema transaction for database typedb: typeql schema query; fails with a message containing: "Invalid token"
      """
      define entity person;
      """
    Then with a wrong token, one-shot query with write transaction for database typedb: typeql write query; fails with a message containing: "Invalid token"
      """
      insert $p isa person;
      """
    Then with a wrong token, one-shot query with read transaction for database typedb: typeql read query; fails with a message containing: "Invalid token"
      """
      match entity $x;
      """

  #################################
  # CONCEPT ROW ANSWERS STRUCTURE #
  #################################

  Scenario: Transaction read row queries return all concepts correctly
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity person, plays parentship:parent, owns name;
        attribute name value string;
        relation parentship, relates parent;
      """
    Given typeql write query
      """
      insert
        $p isa person, has name 'John';
        $pp isa parentship, links ($p);
      """
    Given transaction commits

    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $entity isa $entity-type, has $attribute-type $attribute;
        $relation isa $relation-type, links ($entity);
        $relation-type relates $role-type;
        let $value = $attribute;
      """
    Then answer size is: 1
    Then answer type is: concept rows
    Then answer type is not: concept documents
    Then answer contains document:
    """
    {
      "data": {
        "entity": {
            "kind": "entity",
            "iid": "0x1e00000000000000000000",
            "type": {
                "kind": "entityType",
                "label": "person"
            }
        },
        "role-type": {
            "kind": "roleType",
            "label": "parentship:parent"
        },
        "relation": {
            "kind": "relation",
            "iid": "0x1f00000000000000000000",
            "type": {
                "kind": "relationType",
                "label": "parentship"
            }
        },
        "relation-type": {
            "kind": "relationType",
            "label": "parentship"
        },
        "attribute-type": {
            "kind": "attributeType",
            "label": "name",
            "valueType": "string"
        },
        "entity-type": {
            "kind": "entityType",
            "label": "person"
        },
        "value": {
            "kind": "value",
            "value": "John",
            "valueType": "string"
        },
        "attribute": {
            "kind": "attribute",
            "value": "John",
            "valueType": "string",
            "type": {
                "kind": "attributeType",
                "label": "name",
                "valueType": "string"
            }
        }
      },
      "involvedBranches": [0]
    }
    """

  Scenario: One-shot read row queries return all concepts correctly
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define
        entity person, plays parentship:parent, owns name;
        attribute name value string;
        relation parentship, relates parent;
      """
    Given one-shot query with commit with write transaction for database typedb: typeql write query
      """
      insert
        $p isa person, has name 'John';
        $pp isa parentship, links ($p);
      """

    When set query option include_instance_types to: true
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match
        $entity isa $entity-type, has $attribute-type $attribute;
        $relation isa $relation-type, links ($entity);
        $relation-type relates $role-type;
        let $value = $attribute;
      """
    Then answer size is: 1
    Then answer type is: concept rows
    Then answer type is not: concept documents
    Then answer contains document:
    """
    {
      "data": {
        "entity": {
            "kind": "entity",
            "iid": "0x1e00000000000000000000",
            "type": {
                "kind": "entityType",
                "label": "person"
            }
        },
        "role-type": {
            "kind": "roleType",
            "label": "parentship:parent"
        },
        "relation": {
            "kind": "relation",
            "iid": "0x1f00000000000000000000",
            "type": {
                "kind": "relationType",
                "label": "parentship"
            }
        },
        "relation-type": {
            "kind": "relationType",
            "label": "parentship"
        },
        "attribute-type": {
            "kind": "attributeType",
            "label": "name",
            "valueType": "string"
        },
        "entity-type": {
            "kind": "entityType",
            "label": "person"
        },
        "value": {
            "kind": "value",
            "value": "John",
            "valueType": "string"
        },
        "attribute": {
            "kind": "attribute",
            "value": "John",
            "valueType": "string",
            "type": {
                "kind": "attributeType",
                "label": "name",
                "valueType": "string"
            }
        }
      },
      "involvedBranches": [0]
    }
    """

  ###########################
  # ONE-SHOT QUERIES COMMON #
  ###########################

  Scenario: One-shot query method processes ok query answers correctly
    When one-shot query with schema transaction for database typedb: get answers of typeql schema query
      """
      define entity person;
      """
    Then answer type is: ok
    Then answer type is not: concept rows
    Then answer type is not: concept documents
    Then answer unwraps as ok


  Scenario: One-shot query method processes concept row query answers correctly
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define entity person owns name @key; attribute name, value string;
      """
    When one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define attribute age, value integer;
      """
    When one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $p isa person;
      """
    Then answer type is: concept rows
    Then answer type is not: ok
    Then answer type is not: concept documents
    Then answer size is: 0

    When one-shot query with commit with write transaction for database typedb: get answers of typeql write query
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

    When one-shot query with read transaction for database typedb: get answers of typeql read query
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


  Scenario: One-shot query method processes concept document query answers from read queries correctly
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define
      entity person owns id @key, owns name @card(0..);
      entity empty-person;
      entity nameless-person, owns name;
      attribute id, value integer;
      attribute name, value string;
      """
    When one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When one-shot query with commit with write transaction for database typedb: typeql write query
    """
    insert
    $z isa person, has id 1;
    $y isa person, has id 2, has name "Yan";
    $x isa person, has id 3, has name "Xena", has name "Warrior Princess";
    $e isa empty-person;
    $n isa nameless-person;
    """
    When one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When one-shot query with read transaction for database typedb: get answers of typeql read query
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


  Scenario: One-shot queries can be run with configurable transaction options
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define
        entity person owns id, owns name;
        attribute id value integer;
        attribute name value string;
      """

    # Set a very small transaction timeout with a high chance of failure for big queries
    When set transaction option transaction_timeout_millis to: 1
    Then one-shot query with write transaction for database typedb: typeql read query; fails with a message containing: "transaction timeout"
      """
      match
        { entity $type; } or { attribute $type; };
        { entity $type2; } or { attribute $type2; };
        { entity $type3; } or { attribute $type3; };
      insert
        $p isa person, has id 1, has name "John";
      """

    When set transaction option transaction_timeout_millis to: 10000
    Then one-shot query with write transaction for database typedb: typeql read query
      """
      match
        { entity $type; } or { attribute $type; };
        { entity $type2; } or { attribute $type2; };
        { entity $type3; } or { attribute $type3; };
      insert
        $p isa person, has id 1, has name "John";
      """

  ###############################
  # QUERY OPTIONS: TRANSACTIONS #
  ###############################

  Scenario: Transaction-based write and read queries can be limited by answer count limit
    # Does not affect
    Given set query option answer_count_limit to: 1
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity many; entity two; entity one; entity new;
      """
    Given typeql write query
      """
      insert
        $m1 isa many; $m2 isa many; $m3 isa many; $m4 isa many;
        $t1 isa two; $t2 isa two;
        $o isa one;
      """
    Given transaction commits

    When set query option answer_count_limit to: 2
    Then transaction is open: false
    When connection open read transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql read query
      """
      match $x isa one;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match $x isa two;
      """
    Then answer size is: 2
    When get answers of typeql read query
      """
      match $x isa many;
      """
    Then answer size is: 2
    When transaction closes

    When set query option answer_count_limit to: 5
    Then transaction is open: false
    When connection open read transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql read query
      """
      match $x isa one;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match $x isa two;
      """
    Then answer size is: 2
    When get answers of typeql read query
      """
      match $x isa many;
      """
    Then answer size is: 4
    When transaction closes

    When set query option answer_count_limit to: 1
    Then transaction is open: false
    When connection open read transaction for database: typedb
    Then transaction is open: true
    When get answers of typeql read query
      """
      match $x isa one;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match $x isa two;
      """
    Then answer size is: 1
    When get answers of typeql read query
      """
      match $x isa many;
      """
    Then answer size is: 1
    When transaction closes

  ###################################
  # QUERY OPTIONS: ONE-SHOT QUERIES #
  ###################################

  Scenario: One-shot write and read queries can be limited by answer count limit
    # Does not affect
    Given set query option answer_count_limit to: 1
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define entity many; entity two; entity one; entity new;
      """
    Given one-shot query with commit with write transaction for database typedb: typeql write query
      """
      insert
        $m1 isa many; $m2 isa many; $m3 isa many; $m4 isa many;
        $t1 isa two; $t2 isa two;
        $o isa one;
      """

    When set query option answer_count_limit to: 2
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa one;
      """
    Then answer size is: 1
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa two;
      """
    Then answer size is: 2
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa many;
      """
    Then answer size is: 2

    When set query option answer_count_limit to: 5
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa one;
      """
    Then answer size is: 1
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa two;
      """
    Then answer size is: 2
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa many;
      """
    Then answer size is: 4

    When set query option answer_count_limit to: 1
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa one;
      """
    Then answer size is: 1
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa two;
      """
    Then answer size is: 1
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match $x isa many;
      """
    Then answer size is: 1


  Scenario: One-shot read rows queries can include and exclude instance types
    # Does not affect
    Given set query option include_instance_types to: false
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define
        entity person, owns name, plays friendship:friend;
        relation friendship, relates friend;
        attribute name value string;
      """
    Given one-shot query with commit with write transaction for database typedb: typeql write query
      """
      insert
        $p isa person, has name "John";
        $f isa friendship, links ($p);
      """

    When set query option include_instance_types to: true
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
      """
      match
        $e isa person;
        $a isa name;
        $r isa friendship;
      """
    Then answer size is: 1
    Then answer get row(0) get variable(e) try get label is not none
    Then answer get row(0) get variable(e) get type get label: person
    Then answer get row(0) get variable(a) try get label is not none
    Then answer get row(0) get variable(a) get type get label: name
    Then answer get row(0) get variable(r) try get label is not none
    Then answer get row(0) get variable(r) get type get label: friendship

    When set query option include_instance_types to: false
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
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


  Scenario: One-shot write rows queries can include and exclude instance types
    # Does not affect
    Given set query option include_instance_types to: false
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define
        entity person, owns name, plays friendship:friend;
        relation friendship, relates friend;
        attribute name value string;
      """

    When set query option include_instance_types to: true
    Then one-shot query with write transaction for database typedb: get answers of typeql write query
      """
      insert
        $e isa person, has name $a;
        $a isa name "John";
        $r isa friendship, links ($e);
      """
    Then answer size is: 1
    Then answer get row(0) get variable(e) try get label is not none
    Then answer get row(0) get variable(e) get type get label: person
    Then answer get row(0) get variable(a) try get label is not none
    Then answer get row(0) get variable(a) get type get label: name
    Then answer get row(0) get variable(r) try get label is not none
    Then answer get row(0) get variable(r) get type get label: friendship

    When set query option include_instance_types to: false
    Then one-shot query with write transaction for database typedb: get answers of typeql write query
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


  Scenario: One-shot read document queries are not controlled by the include_instance_types option
    # Does not affect
    Given set query option include_instance_types to: false
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define
        entity person, owns name; attribute name value string;
      """
    Given one-shot query with commit with write transaction for database typedb: typeql write query
      """
      insert $p isa person, has name "John";
      """

    When set query option include_instance_types to: true
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
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

    When set query option include_instance_types to: false
    Then one-shot query with read transaction for database typedb: get answers of typeql read query
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


  Scenario: One-shot write documents queries are not controlled by the include_instance_types option
    # Does not affect
    Given set query option include_instance_types to: false
    Given one-shot query with commit with schema transaction for database typedb: typeql schema query
      """
      define
        entity person, owns name;
        attribute name value string;
      """

    When set query option include_instance_types to: true
    Then one-shot query with write transaction for database typedb: get answers of typeql write query
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

    When set query option include_instance_types to: false
    Then one-shot query with write transaction for database typedb: get answers of typeql write query
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
