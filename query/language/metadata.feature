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
    When get answers of typeql read query
      """
      match $t label person;
      fetch { "doc": get_doc($t) };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "doc": "This represents a person"
      }
      """


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
    When get answers of typeql read query
      """
      match $t label name;
      fetch { "doc": get_doc($t) };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "doc": "This represents a name"
      }
      """


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
    When get answers of typeql read query
      """
      match
        $t label marriage;
        $r label marriage:spouse;
      fetch {
        "relation_doc": get_doc($t),
        "role_doc": get_doc($r)
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "relation_doc": "This represents a marriage",
        "role_doc": "This role is played by a spouse"
      }
      """


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
    When get answers of typeql read query
      """
      match let $struct_name = "location";
      fetch {
        "struct_doc": get_struct_doc($struct_name),
        "field_doc": get_struct_field_doc($struct_name, "latitude"),
        "field_doc_2": get_struct_field_doc($struct_name, "longitude")
      }
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "struct_doc": "geographic coordinates",
        "field_doc": "north-south",
        "field_doc_2": "east-west"
      }
      """


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
    When get answers of typeql read query
      """
      match let $f = "get_random_number";
      fetch { "doc": get_fun_doc($f) };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "doc": "chosen by a fair dice roll"
      }
      """


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
    When get answers of typeql read query
      """
      match $rhs label <rhs>;
      fetch { "doc": get_<constraint>_doc(person, $rhs) };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "doc": "lorem ipsum"
      }
      """
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
    When get answers of typeql read query
      """
      match
        $t label person;
        let $f = "get_random_number";
      fetch {
        "doc": get_doc($t),
        "func_doc": get_fun_doc($f)
      };
      """
    Then answer size is: 1
    Then answer contains document:
      """
      {
        "doc": "",
        "func_doc": ""
      }
      """


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
  # TODO: structs
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
    When get answers of typeql read query
      """
      match
        let $key, $value in get_all_meta(person);
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:repr  | value:string:person |
      | value:string:table | value:string:PERSON |


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


  Scenario: get_all_meta returns all metadata for an entity type
    When typeql schema query
      """
      define entity person @meta("key1", "val1") @meta("key2", "val2");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_all_meta(person);
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |


  Scenario: get_all_meta returns all metadata for an attribute type
    When typeql schema query
      """
      define attribute name @meta("key1", "val1") @meta("key2", "val2"), value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_all_meta(name);
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |


  Scenario: get_all_meta returns all metadata for a relation type
    When typeql schema query
      """
      define relation marriage @meta("key1", "val1") @meta("key2", "val2"), relates spouse;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_all_meta(marriage);
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |


  Scenario: get_all_meta returns all metadata for a role type
    When typeql schema query
      """
      define relation marriage, relates spouse @meta("key1", "val1") @meta("key2", "val2");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_all_meta(marriage:spouse);
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |


  Scenario: get_all_meta returns all metadata for a function
    When typeql schema query
      """
      define
        fun get_random_number() -> integer
          @meta("key1", "val1")
          @meta("key2", "val2"):
        match
          let $rand = 4;
        return first $rand;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_fun_all_meta("get_random_number");
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |


  Scenario Outline: get_<constraint>_all_meta returns all metadata for a <constraint>
    When typeql schema query
      """
      define
        relation person, <constraint> <arg> @meta("key1", "val1") @meta("key2", "val2");
        person relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_<constraint>_all_meta(person, <rhs>);
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |
  Examples:
    | constraint | arg        | rhs            |
    | owns       | id         | id             |
    | plays      | base:arole | base:arole     |
    | relates    | newrole    | person:newrole |
    | sub        | base       | base           |


  Scenario: get_all_meta results in zero rows if no @meta are defined for an entity type
    When typeql schema query
      """
      define entity person;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_all_meta(person);
      """
    Then answer size is: 0


  Scenario: get_all_meta results in zero rows if no @meta are defined for an attribute type
    When typeql schema query
      """
      define attribute name value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_all_meta(name);
      """
    Then answer size is: 0


  Scenario: get_all_meta results in zero rows if no @meta are defined for a relation type
    When typeql schema query
      """
      define relation marriage, relates spouse;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_all_meta(marriage);
      """
    Then answer size is: 0


  Scenario: get_all_meta results in zero rows if no @meta are defined for a role type
    When typeql schema query
      """
      define relation marriage, relates spouse;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_all_meta(marriage:spouse);
      """
    Then answer size is: 0


  Scenario: get_fun_all_meta results in zero rows if no @meta are defined for a function
    When typeql schema query
      """
      define
        fun get_random_number() -> integer:
        match
          let $rand = 4;
        return first $rand;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_fun_all_meta("get_random_number");
      """
    Then answer size is: 0


  Scenario Outline: get_<constraint>_all_meta results in zero rows if no @meta are defined for the <constraint>
    When typeql schema query
      """
      define
        relation person, <constraint> <arg>;
        person relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_<constraint>_all_meta(person, <rhs>);
      """
    Then answer size is: 0
  Examples:
    | constraint | arg        | rhs            |
    | owns       | id         | id             |
    | plays      | base:arole | base:arole     |
    | relates    | newrole    | person:newrole |
    | sub        | base       | base           |


  ##############
  # FAIL CASES #
  ##############

  Scenario: get_fun_doc fails if the function does not exist
    Then typeql read query; fails
      """
      match let $doc = get_fun_doc("non_existing_function");
      """


  Scenario: get_fun_meta fails if the function does not exist
    Then typeql read query; fails
      """
      match let $meta = get_fun_meta("non_existing_function");
      """


  Scenario: get_fun_all_meta fails if the function does not exist
    Then typeql read query; fails
      """
      match let $key, $value in get_fun_all_meta("non_existing_function");
      """


  Scenario Outline: get_<constraint>_doc returns no answers if the <constraint> is not defined
    When typeql schema query
      """
      define
        relation person, relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $doc = get_<constraint>_doc(person, <rhs>);
      """
    Then answer size is: 0
  Examples:
    | constraint | rhs        |
    | owns       | id         |
    | plays      | base:arole |
    | relates    | base:arole |
    | sub        | base       |


  Scenario Outline: get_<constraint>_meta returns no answers if the <constraint> is not defined
    When typeql schema query
      """
      define
        relation person, relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $meta = get_<constraint>_meta("key", person, <rhs>);
      """
    Then answer size is: 0
  Examples:
    | constraint | rhs        |
    | owns       | id         |
    | plays      | base:arole |
    | relates    | base:arole |
    | sub        | base       |


  Scenario Outline: get_<constraint>_all_meta returns no answers if the <constraint> is not defined
    When typeql schema query
      """
      define
        relation person, relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_<constraint>_all_meta(person, <rhs>);
      """
    Then answer size is: 0
  Examples:
    | constraint | rhs        |
    | owns       | id         |
    | plays      | base:arole |
    | relates    | base:arole |
    | sub        | base       |


  Scenario Outline: get_<constraint>_doc returns no answers if the argument kinds don't match the constraint
    When typeql schema query
      """
      define
        entity company;
        relation person, relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $doc = get_<constraint>_doc(<lhs>, <rhs>);
      """
    Then answer size is: 0
  Examples:
    | constraint | lhs        | rhs        |
    | owns       | base:arole | id         |
    | owns       | id         | id         |
    | owns       | id         | person     |
    | owns       | person     | base:arole |
    | owns       | person     | company    |
    | owns       | person     | person     |
    | plays      | base:arole | base:arole |
    | plays      | id         | base:arole |
    | plays      | person     | company    |
    | plays      | person     | id         |
    | plays      | person     | person     |
    | relates    | base:arole | base:arole |
    | relates    | company    | base:arole |
    | relates    | id         | base:arole |
    | relates    | person     | company    |
    | relates    | person     | id         |
    | relates    | person     | person     |
    | sub        | company    | person     |
    | sub        | person     | id         |
    | sub        | person     | base:arole |


  Scenario Outline: get_<constraint>_meta returns no answers if the argument kinds don't match the constraint
    When typeql schema query
      """
      define
        entity company;
        relation person, relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $meta = get_<constraint>_meta("key", <lhs>, <rhs>);
      """
    Then answer size is: 0
  Examples:
    | constraint | lhs        | rhs        |
    | owns       | base:arole | id         |
    | owns       | id         | id         |
    | owns       | id         | person     |
    | owns       | person     | base:arole |
    | owns       | person     | company    |
    | owns       | person     | person     |
    | plays      | base:arole | base:arole |
    | plays      | id         | base:arole |
    | plays      | person     | company    |
    | plays      | person     | id         |
    | plays      | person     | person     |
    | relates    | base:arole | base:arole |
    | relates    | company    | base:arole |
    | relates    | id         | base:arole |
    | relates    | person     | company    |
    | relates    | person     | id         |
    | relates    | person     | person     |
    | sub        | company    | person     |
    | sub        | person     | id         |
    | sub        | person     | base:arole |


  Scenario Outline: get_<constraint>_all_meta returns no answers if the argument kinds don't match the constraint
    When typeql schema query
      """
      define
        entity company;
        relation person, relates dummy; # a relation must relate at least one role
        relation base, relates arole;
        attribute id value string;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_<constraint>_all_meta(<lhs>, <rhs>);
      """
    Then answer size is: 0
  Examples:
    | constraint | lhs        | rhs        |
    | owns       | base:arole | id         |
    | owns       | id         | id         |
    | owns       | id         | person     |
    | owns       | person     | base:arole |
    | owns       | person     | company    |
    | owns       | person     | person     |
    | plays      | base:arole | base:arole |
    | plays      | id         | base:arole |
    | plays      | person     | company    |
    | plays      | person     | id         |
    | plays      | person     | person     |
    | relates    | base:arole | base:arole |
    | relates    | company    | base:arole |
    | relates    | id         | base:arole |
    | relates    | person     | company    |
    | relates    | person     | id         |
    | relates    | person     | person     |
    | sub        | company    | person     |
    | sub        | person     | id         |
    | sub        | person     | base:arole |


  @ignore
  # TODO: structs
  Scenario: get_struct_all_meta returns all metadata for a struct type
    When typeql schema query
      """
      define struct location @meta("key1", "val1") @meta("key2", "val2"):
        latitude value double;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_struct_all_meta("location");
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |


  @ignore
  # TODO: structs
  Scenario: get_struct_field_all_meta returns all metadata for a struct field
    When typeql schema query
      """
      define struct location:
        latitude value double @meta("key1", "val1") @meta("key2", "val2");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_struct_field_all_meta("location", "latitude");
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |


  @ignore
  # TODO: structs
  Scenario: get_struct_all_meta results in zero rows if no @meta are defined for a struct type
    When typeql schema query
      """
      define struct location:
        latitude value double;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_struct_all_meta("location");
      """
    Then answer size is: 0


  @ignore
  # TODO: structs
  Scenario: get_struct_field_all_meta results in zero rows if no @meta are defined for a struct field
    When typeql schema query
      """
      define struct location:
        latitude value double;
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match let $key, $value in get_struct_field_all_meta("location", "latitude");
      """
    Then answer size is: 0


  #############
  # VARIABLES #
  #############

  Scenario: get_doc works with a type variable
    When typeql schema query
      """
      define entity person @doc("This represents a person");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $ty label person;
        let $doc = get_doc($ty);
      """
    Then uniquely identify answer concepts
      | doc                                   |
      | value:string:This represents a person |


  Scenario: get_meta works with a type variable
    When typeql schema query
      """
      define entity person @meta("key", "This represents a person");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $ty label person;
        let $metadata = get_meta("key", $ty);
      """
    Then uniquely identify answer concepts
      | metadata                              |
      | value:string:This represents a person |


  Scenario: get_all_meta works with a type variable
    When typeql schema query
      """
      define entity person @meta("key1", "val1") @meta("key2", "val2");
      """
    Then transaction commits
    Then connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match
        $ty label person;
        let $key, $value in get_all_meta($ty);
      """
    Then uniquely identify answer concepts
      | key                | value               |
      | value:string:key1  | value:string:val1   |
      | value:string:key2  | value:string:val2   |


  Scenario: get_fun_doc works with the function name in a variable
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
      match let $fun = "get_random_number"; let $doc = get_fun_doc($fun);
      """
    Then uniquely identify answer concepts
      | doc                                     |
      | value:string:chosen by a fair dice roll |
