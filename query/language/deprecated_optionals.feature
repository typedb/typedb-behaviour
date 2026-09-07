# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: TypeQL tests ensuring old behaviour is not broken during the transition to new optional validation.

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
      entity person,
        plays friendship:friend,
        owns name @key,
        owns email @card(0..),
        owns age @card(0..),
        owns ref @key;
      relation friendship,
        relates friend @card(0..),
        owns ref @key;
      attribute name @independent, value string;
      attribute email @independent, value string;
      attribute ref @independent, value integer;
      attribute age @independent, value integer;
      """
    Given transaction commits


  ###########
  # DELETES #
  ###########
  Scenario: an optional binding is deleted
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has email "jane@doe.com", has ref 1;
    """
    When get answers of typeql write query
    """
    match $p isa person, has name $name; try { $p has email $email; };
    delete try { $email; };
    """
    Then uniquely identify answer concepts
      | p             | name           |
      | key:name:John | attr:name:John |
      | key:name:Jane | attr:name:Jane |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person, has email $email;
    """
    Then answer size is: 0


  Scenario: a has edge depending on an optional binding is deleted
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has email "jane@doe.com", has ref 1;
    """
    When get answers of typeql write query
    """
    match $p isa person, has name $name; try { $p has email $email; };
    delete try { has $email of $p; };
    """
    Then uniquely identify answer concepts
      | p             | name           | email                   |
      | key:name:John | attr:name:John | none                    |
      | key:name:Jane | attr:name:Jane | attr:email:jane@doe.com |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person, has email $email;
    """
    Then answer size is: 0


  Scenario: multiple edges in a single try block are only deleted when all optional variables are bound
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has email "jane@doe.com", has ref 1;
      $alice isa person, has name "Alice", has age 33, has ref 2;
      $bob isa person, has name "Bob", has email "bob@ross.com", has age 22, has ref 3;
    """
    When get answers of typeql write query
    """
    match
      $p isa person;
      try { $p has email $email; };
      try { $p has age $age; };
    delete try { has $email of $p; has $age of $p; };
    """
    Then uniquely identify answer concepts
      | p              | email                   | age         |
      | key:name:John  | none                    | none        |
      | key:name:Jane  | attr:email:jane@doe.com | none        |
      | key:name:Alice | none                    | attr:age:33 |
      | key:name:Bob   | attr:email:bob@ross.com | attr:age:22 |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person, has email $email;
    """
    Then uniquely identify answer concepts
      | p              | email                   |
      | key:name:Jane  | attr:email:jane@doe.com |
    Then get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then uniquely identify answer concepts
      | p              | age         |
      | key:name:Alice | attr:age:33 |


  Scenario: an optional relation is deleted
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has ref 1;
      friendship (friend: $john, friend: $jane), has ref 0;
      $eve isa person, has name "Eve", has ref 2;
    """
    When get answers of typeql write query
    """
    match $p isa person, has name $name; try { $f isa friendship, links ($p); };
    delete try { $f; };
    """
    Then uniquely identify answer concepts
      | p             | name           |
      | key:name:John | attr:name:John |
      | key:name:Jane | attr:name:Jane |
      | key:name:Eve  | attr:name:Eve  |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person; $f isa friendship, links ($p);
    """
    Then answer size is: 0


  Scenario: a links edge depending on an optional binding is deleted
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has ref 1;
      friendship (friend: $john, friend: $jane), has ref 0;
      $eve isa person, has name "Eve", has ref 2;
    """
    When get answers of typeql write query
    """
    match $p isa person, has name $name; try { $f isa friendship, links ($p); };
    delete try { links ($p) of $f; };
    """
    Then uniquely identify answer concepts
      | p             | name           | f         |
      | key:name:John | attr:name:John | key:ref:0 |
      | key:name:Jane | attr:name:Jane | key:ref:0 |
      | key:name:Eve  | attr:name:Eve  | none      |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person; $f isa friendship, links ($p);
    """
    Then answer size is: 0


  Scenario: In a delete stage, using an optional variable outside a try block errors.
    Given connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "A write stage uses the optional variable 'name' outside a 'try' block."
    """
    match
      $john isa person; try { $john has name $name; };
    delete
      has $name of $john;
    """


  Scenario: nested try blocks in delete are disallowed
    Given connection open write transaction for database: typedb
    Given typeql write query; parsing fails
    """
    match $p isa person; try { $p has email $email, has age $age; };
    delete try { has $email of $p; try { has $age of $p; }; };
    """

  #########
  # GIVEN #
  #########

  Scenario: Optional variables may be omitted, required ones may not, undeclared variables are flagged.
    Given connection open read transaction for database: typedb
    When set query given rows
      | x               |
      | value:integer:5 |
    When get answers of typeql read query with given rows
      """
      given $x: integer, $y: integer?;
      match
       let $p = $x * 2;
       try { let $q = $x + $y; };
      """
    Then uniquely identify answer concepts
      | x               | p                |
      | value:integer:5 | value:integer:10 |

    When set query given rows
      | x               |
      | value:integer:5 |
    Then typeql read query with given rows; fails with a message containing: "The given rows are missing the required variable 'y'"
      """
      given $x: integer, $y: integer;
      match
       let $p = $x * 2;
       let $q = $x + $y;
      """

    When set query given rows
      | x               | z               |
      | value:integer:5 | value:integer:6 |
    Then typeql read query with given rows; fails with a message containing: "The variable 'z' was not declared in the query"
      """
      given $x: integer, $y: integer?;
      match
        let $p = $x;
       try { let $q = $x + $y; };
      """


  Scenario: Given row entries can be optional
    # Undeclared None fail at runtime
    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    undefine @key from person owns name;
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given set query given rows
      | ref               | name               |
      | value:integer:110 | value:string:James |
      | value:integer:111 | none               |
    Then typeql write query with given rows; fails with a message containing: "The given value at row '1' and column '1' was None, but the variable was not declared optional"
        """
        given $ref: integer, $name: string;
        insert $p isa person, has ref == $ref, has name == $name;
        """

    # Declared None, used outside try
    Given connection open write transaction for database: typedb
    Given set query given rows
      | ref               | name               |
      | value:integer:110 | value:string:James |
      | value:integer:111 | none               |
    Then typeql write query with given rows; fails with a message containing: "A write stage uses the optional variable 'name' outside a 'try' block"
        """
        given $ref: integer, $name: string?;
        insert $p isa person, has ref == $ref, has name == $name;
        """

    # normal
    Given connection open write transaction for database: typedb
    Given set query given rows
      | ref               | name               |
      | value:integer:110 | value:string:James |
      | value:integer:111 | none               |
    When get answers of typeql write query with given rows
        """
        given $ref: integer, $name: string?;
        insert
          $p isa person, has ref == $ref;
          try { $p has name == $name; };
        """
    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
        """
        match $p isa person, has name "James";
        """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:110 |
    When get answers of typeql read query
        """
        match $p isa person; not { $p has name $name; };
        """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:111 |


  Scenario: The order of variables in the given rows does not matter, omitted ones are treated as optional, undeclared ones are flagged.
    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    undefine @key from person owns name;
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given set query given rows
      | name               | ref               |
      | value:string:James | value:integer:110 |
    When get answers of typeql write query with given rows
        """
        given $ref: integer, $name: string?;
        insert
          $p isa person, has ref == $ref;
          try { $p has name == $name; };
        """
    Given set query given rows
      | ref               |
      | value:integer:111 |
    When get answers of typeql write query with given rows
        """
        given $ref: integer, $name: string?;
        insert
          $p isa person, has ref == $ref;
          try { $p has name == $name; };
        """

    Then transaction commits

    Given connection open read transaction for database: typedb
    When get answers of typeql read query
        """
        match $p isa person, has name "James";
        """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:110 |
    When get answers of typeql read query
        """
        match $p isa person; not { $p has name $name; };
        """
    Then uniquely identify answer concepts
      | p           |
      | key:ref:111 |


  ###########
  # INSERTS #
  ###########
  Scenario: a has edge depending on an optional binding can be inserted
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has ref 1, has age 33;
      friendship (friend: $john, friend: $jane), has ref 0;
    """
    When get answers of typeql write query
    """
    match
      friendship ($p, $q);
      $p isa person; try { $p has age $age; };
    insert try { $q has $age; };
    """
    Then uniquely identify answer concepts
      | p             | q             |
      | key:name:John | key:name:Jane |
      | key:name:Jane | key:name:John |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then answer size is: 2


  Scenario: a relation linking an optional player is inserted
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has ref 1, has email "jane@doe.com";
    """
    When get answers of typeql write query
    """
    match
      $p isa person;
      try { $q isa person, has email $_; not { $q is $p; }; };
    insert
      try { $f isa friendship, links (friend: $p, friend: $q), has ref 0; };
    """
    Then uniquely identify answer concepts
      | p         | q         | f         |
      | key:ref:0 | key:ref:1 | key:ref:0 |
      | key:ref:1 | none      | none      |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $f isa friendship;
    """
    Then answer size is: 1


  Scenario: a try insert is only executed if all optional inputs are bound
    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    undefine @key from person owns name;
    """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $jane isa person, has ref 1, has name "Jane", has age 33;
      $john isa person, has ref 2, has name "John";
      $anon isa person, has ref 3, has age 45;
    """
    When get answers of typeql write query
    """
    match
      $p isa person;
      try { $p has age $age; };
      try { $p has name $name; };
    insert try { $q isa person, has ref 0; $q has $age, has $name; };
    """
    Then uniquely identify answer concepts
      | p         | q         | age         | name           |
      | key:ref:1 | key:ref:0 | attr:age:33 | attr:name:Jane |
      | key:ref:2 | none      | none        | attr:name:John |
      | key:ref:3 | none      | attr:age:45 | none           |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then answer size is: 3


  Scenario: In an insert stage, using an optional variable outside a try block errors.
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has ref 0, has name "John";
    """
    Then typeql write query; fails with a message containing: "A write stage uses the optional variable 'age' outside a 'try' block."
    """
    match
      $p isa person;
      try { $p has age $age; };
    insert
      $q isa person, has ref 1, has name "Jane", has $age;
    """


  Scenario: nested try blocks in delete are disallowed
    Given connection open write transaction for database: typedb
    Given typeql write query; fails
    """
    match $p isa person; try { $p has name $name, has age $age; };
    insert $q isa person; try { $q has $name; try { $q has $age; }; };
    """


  Scenario: Values of attributes inserted in parent blocks are available in try blocks
    Given connection open write transaction for database: typedb
    When get answers of typeql write query
    """
    insert
     $thirty-two isa ref 32; # Wrong type just to complicate things.
     $john isa person, has name "John", has ref 0;
     try { $john has age == $thirty-two; };
    """
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then uniquely identify answer concepts
      | p             | age         |
      | key:name:John | attr:age:32 |


  ########
  # PUTS #
  ########
  Scenario: a has edge depending on an optional binding can be inserted (put)
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      attribute ref value integer;
      relation friendship,
        relates friend @card(0..),
        owns ref @key;
      person
        plays friendship:friend,
        owns ref @key;
      entity also-person
        plays friendship:friend,
        owns age,
        owns ref @key;
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has ref 1, has age 33;
      friendship (friend: $john, friend: $jane), has ref 0;
    """
    When get answers of typeql write query
    """
    match
      $p isa person, has ref $ref; try { $p has age $age; };
    put $q isa also-person, has $ref; try { $q has $age; };
    """
    Then uniquely identify answer concepts
      | p         | q         | age         |
      | key:ref:0 | key:ref:0 | none        |
      | key:ref:1 | key:ref:1 | attr:age:33 |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then answer size is: 1


  Scenario: a relation linking an optional player is inserted
    Given connection open schema transaction for database: typedb
    When typeql schema query
      """
      define
      attribute ref value integer;
      relation friendship,
        relates friend @card(0..),
        owns ref @key;
      person
        plays friendship:friend,
        owns ref @key;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has ref 1, has email "jane@doe.com";
    """
    When get answers of typeql write query
    """
    match
      $p isa person;
      try { $q isa person, has email $_; not { $q is $p; }; };
    put
      try { $f isa friendship, links (friend: $p, friend: $q), has ref 0; };
    """
    Then uniquely identify answer concepts
      | p         | q         | f    |
      | key:ref:0 | key:ref:1 | none |
      | key:ref:1 | none      | none |
    When get answers of typeql write query
    """
    match
      $p isa person, has ref $ref;
      try { $q isa person, has email $_; not { $q is $p; }; };
    put
      $f isa friendship, links(friend: $p), has $ref;
      try { $f links (friend: $q); };
    """
    Then uniquely identify answer concepts
      | p         | q         | f         |
      | key:ref:0 | key:ref:1 | key:ref:0 |
      | key:ref:1 | none      | key:ref:1 |
    Then transaction commits

    Then connection open read transaction for database: typedb
    Then get answers of typeql read query
    """
    match $f isa friendship;
    """
    Then answer size is: 2


  Scenario: In a put stage, using an optional variable outside a try block errors.
    Given connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "A write stage uses the optional variable 'age' outside a 'try' block."
    """
    match
      $p isa person;
      try { $p has age $age; };
    put
      $q isa person, has name "Jane", has $age;
    """


  Scenario: nested try blocks in put are disallowed
    Given connection open write transaction for database: typedb
    Given typeql write query; fails
    """
    match $p isa person; try { $p has name $name, has age $age; };
    put $q isa person; try { $q has $name; try { $q has $age; }; };
    """

  ###########
  # UPDATES #
  ###########


  Scenario: a has edge depending on an optional binding can be updated
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has ref 1, has age 33;
    """
    When get answers of typeql write query
    """
    match
      $p isa person;
      try {
        $p has age $age;
        let $new-age-val = $age + 1;
      };
    update try { $p has age == $new-age-val; };
    """
    Then uniquely identify answer concepts
      | p             | age           | new-age-val      |
      | key:name:John | none          | none             |
      | key:name:Jane | attr:age:33   | value:integer:34 |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $p isa person, has age $age;
    """
    Then answer size is: 1
    Then get answers of typeql read query
    """
    match $p isa person, has age 33;
    """
    Then answer size is: 0
    Then get answers of typeql read query
    """
    match $p isa person, has age 34;
    """
    Then answer size is: 1


  Scenario: a relation linking an optional player is updated
    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $john isa person, has name "John", has ref 0;
      $jane isa person, has name "Jane", has ref 1;
      $f isa friendship, links ($john), has ref 0;
    """
    When get answers of typeql write query
    """
    match
      $p isa person; $q isa person; not { $p is $q; };
      try { $f links ($p); };
    update
      try { $f links (friend: $q); };
    """
    Then uniquely identify answer concepts
      | p         | q         | f         |
      | key:ref:0 | key:ref:1 | key:ref:0 |
      | key:ref:1 | key:ref:0 | none      |
    Then transaction commits
    Then connection open write transaction for database: typedb
    Then get answers of typeql read query
    """
    match $f isa friendship, links($q);
    """
    Then uniquely identify answer concepts
      | q         | f         |
      | key:ref:1 | key:ref:0 |


  Scenario: a try update is only executed if all optional inputs are bound
    Given connection open schema transaction for database: typedb
    When typeql schema query
    """
    undefine @key from person owns name;
    """
    When typeql schema query
      """
      define
      entity also-person
        owns name,
        owns age,
        owns ref @key;
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
    """
    insert
      $jane isa person, has ref 0, has name "Jane", has age 33;
      $john isa person, has ref 1, has name "John";
      $anon isa person, has ref 2, has age 45;
    """
    When get answers of typeql write query
    """
    match
      $p isa person, has ref $ref;
      try { $p has age $age; };
      try { $p has name $name; };
    insert $q isa also-person, has $ref;
    update try { $q has $age, has $name; };
    """
    Then uniquely identify answer concepts
      | p         | q         | age         | name           |
      | key:ref:0 | key:ref:0 | attr:age:33 | attr:name:Jane |
      | key:ref:1 | key:ref:1 | none        | attr:name:John |
      | key:ref:2 | key:ref:2 | attr:age:45 | none           |
    Then transaction commits

    Then connection open read transaction for database: typedb
    Then get answers of typeql read query
    """
    match $q isa also-person, has age $age;
    """
    Then uniquely identify answer concepts
      | q         | age         |
      | key:ref:0 | attr:age:33 |
    Then get answers of typeql read query
    """
    match $q isa also-person, has name $name;
    """
    Then uniquely identify answer concepts
      | q         | name           |
      | key:ref:0 | attr:name:Jane |


  Scenario: In an update stage, using an optional variable outside a try block errors.
    Given connection open write transaction for database: typedb
    Then typeql write query; fails with a message containing: "A write stage uses the optional variable 'age' outside a 'try' block."
    """
    match
      $john isa person, has name "John";
      $other isa person; try { $other has age $age; };
    update
      $john has $age;
    """


  Scenario: nested try blocks in insert are disallowed
    Given connection open write transaction for database: typedb
    Given typeql write query; fails
    """
    match $p isa person; try { $p has name $name, has age $age; };
    update try { $p has $name; try { $p has $age; }; };
    """
