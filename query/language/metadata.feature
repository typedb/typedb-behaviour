# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL schema metadata

  Background: Open connection and create a simple extensible schema
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection reset database: typedb
    Given connection open schema transaction for database: typedb

  Scenario: entity types can have doc annotations
    When typeql schema query
      """
      define entity person @doc("This represents a person");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $doc = get_doc(person);
      """
    Then uniquely identify answer concepts
      | doc                                   |
      | value:string:This represents a person |


  Scenario: attribute types can have doc annotations
    When typeql schema query
      """
      define
        attribute name @doc("This represents a name"),
          value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $doc = get_doc(name);
      """
    Then uniquely identify answer concepts
      | doc                                 |
      | value:string:This represents a name |


  Scenario: relation and role types can have doc annotations
    When typeql schema query
      """
      define
        relation marriage @doc("This represents a marriage"),
          relates spouse @doc("This role is played by a spouse");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $relation_doc = get_doc(marriage);
        let $role_doc = get_doc(marriage:spouse);
      """
    Then uniquely identify answer concepts
      | relation_doc                            | role_doc                                     |
      | value:string:This represents a marriage | value:string:This role is played by a spouse |


  @ignore
  # TODO: structs; TBD: how do we refer to struct fields (NOT in a value, in the value _type_)
  Scenario: structs can have doc annotations
    When typeql schema query
      """
      define
        struct location @doc("geographic coordinates"):
          latitude value double @doc("north-south"),
          longitude value double @doc("east-west");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $struct_doc = get_struct_doc("location");
        let $field_doc = get_struct_field_doc("location", "latitude");
        let $field_doc_2 = get_struct_field_doc("location", "longitude");
      """
    Then uniquely identify answer concepts
      | struct_doc                          | field_doc                | field_doc_2            |
      | value:string:geographic coordinates | value:string:north-south | value:string:east-west |


  Scenario: functions can have doc annotations
    When typeql schema query
      """
      define
        fun get_random_number() -> integer
          @doc("chosen by a fair dice roll"):
        match
          let $rand = 4;
        return first $rand;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $doc = get_fun_doc("get_random_number");
      """
    Then uniquely identify answer concepts
      | doc                                     |
      | value:string:chosen by a fair dice roll |


  @ignore
  # TODO: settle on the syntax
  Scenario: doc comments on top-level items can be defined
    When typeql schema query
      """
      define
        #! This represents a person
        entity person;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $doc = get_doc(person);
      """
    Then uniquely identify answer concepts
      | doc                                   |
      | value:string:This represents a person |

    When typeql schema query
      """
      define
        #! chosen by a fair dice roll
        fun get_random_number() -> integer:
        match
          let $rand = 4;
        return first $rand;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $doc = get_fun_doc("get_random_number");
      """
    Then uniquely identify answer concepts
      | doc                                     |
      | value:string:chosen by a fair dice roll |
    # TODO also structs


  Scenario Outline: <constraint> can have a doc annotation
    When typeql schema query
      """
      define
        relation person, <constraint> <arg> @doc("lorem ipsum");
        person relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $doc = get_<constraint>_doc(person, <rhs>);
      """
    Then uniquely identify answer concepts
      | doc                      |
      | value:string:lorem ipsum |
  Examples:
    | constraint | arg        | rhs            |
    | owns       | id         | id             |
    | plays      | base:arole | base:arole     |
    | relates    | newrole    | person:newrole |
    | sub        | base       | base           |


  Scenario: retrieving a missing doc annotation returns an empty string
    When typeql schema query
      """
      define
        entity person;

        fun get_random_number() -> integer:
        match
          let $rand = 4;
        return first $rand;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $doc = get_doc(person);
        let $func_doc = get_fun_doc("get_random_number");
      """
    Then uniquely identify answer concepts
      | doc           | func_doc      |
      | value:string: | value:string: |


  ############
  # METADATA #
  ############

  Scenario: entity types can have metadata annotations
    When typeql schema query
      """
      define entity person @meta("key", "This represents a person");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $metadata = get_meta("key", person);
      """
    Then uniquely identify answer concepts
      | metadata                              |
      | value:string:This represents a person |


  Scenario: attribute types can have metadata annotations
    When typeql schema query
      """
      define
        attribute name @meta("key", "This represents a name"),
          value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $metadata = get_meta("key", name);
      """
    Then uniquely identify answer concepts
      | metadata                            |
      | value:string:This represents a name |


  Scenario: relation and role types can have metadata annotations
    When typeql schema query
      """
      define
        relation marriage @meta("key", "This represents a marriage"),
          relates spouse @meta("key", "This role is played by a spouse");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $relation_meta = get_meta("key", marriage);
        let $role_meta = get_meta("key", marriage:spouse);
      """
    Then uniquely identify answer concepts
      | relation_meta                           | role_meta                                    |
      | value:string:This represents a marriage | value:string:This role is played by a spouse |


  @ignore
  # TODO: structs; TBD: are struct value types first class?
  Scenario: structs can have metadata annotations
    When typeql schema query
      """
      define
        struct location @meta("key", "geographic coordinates"):
          latitude value double @meta("key", "north-south"),
          longitude value double @meta("key", "east-west");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $struct_meta = get_struct_meta("key", "location");
        let $field_meta = get_struct_field_meta("key", "location", "latitude");
        let $field_meta_2 = get_struct_field_meta("key", "location", "longitude");
      """
    Then uniquely identify answer concepts
      | struct_meta                         | field_meta               | field_meta_2           |
      | value:string:geographic coordinates | value:string:north-south | value:string:east-west |


  Scenario: functions can have metadata annotations
    When typeql schema query
      """
      define
        fun get_random_number() -> integer
          @meta("key", "chosen by a fair dice roll"):
        match
          let $rand = 4;
        return first $rand;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $metadata = get_fun_meta("key", "get_random_number");
      """
    Then uniquely identify answer concepts
      | metadata                                |
      | value:string:chosen by a fair dice roll |


  Scenario Outline: <constraint> can have metadata annotations
    When typeql schema query
      """
      define
        relation person, <constraint> <arg> @meta("key", "lorem ipsum");
        person relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $metadata = get_<constraint>_meta("key", person, <rhs>);
      """
    Then uniquely identify answer concepts
      | metadata                 |
      | value:string:lorem ipsum |
  Examples:
    | constraint | arg        | rhs            |
    | owns       | id         | id             |
    | plays      | base:arole | base:arole     |
    | relates    | newrole    | person:newrole |
    | sub        | base       | base           |


  Scenario: types can have multiple metadata annotations
    When typeql schema query
      """
      define
        entity person
          @meta("repr", "person")
          @meta("table", "PERSON");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $repr = get_meta("repr", person);
        let $table = get_meta("table", person);
      """
    Then uniquely identify answer concepts
      | repr                | table               |
      | value:string:person | value:string:PERSON |


  Scenario: retrieving a missing metadata annotation returns an empty string
    When typeql schema query
      """
      define entity person;
      """
    Then transaction commits

    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $metadata = get_meta("key", person);
      """
    Then uniquely identify answer concepts
      | metadata      |
      | value:string: |
    Then transaction closes

    Then connection open schema transaction for database: typedb
    When typeql schema query
      """
      define entity person @meta("key", "This represents a person");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        let $metadata = get_meta("key", person);
        let $metadata_other = get_meta("other", person);
      """
    Then uniquely identify answer concepts
      | metadata                              | metadata_other |
      | value:string:This represents a person | value:string:  |

