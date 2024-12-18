# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Basic Function Execution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity person, owns name, owns ref @key;
      attribute ref value integer;
      attribute name value string;
      """
    Given transaction commits


  Scenario: when matching all possible pairs from n concepts, the answer size is the square of n
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      fun people_pairs_with($who: person) -> { person } :
      match
        $who isa person;
        $friend isa person;
      return { $friend };
      """
    Given transaction commits
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
      $a isa person, has ref 0, has name "Abigail";
      $b isa person, has ref 1, has name "Bernadette";
      $c isa person, has ref 2, has name "Cliff";
      $d isa person, has ref 3, has name "Damien";
      $e isa person, has ref 4, has name "Eustace";
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
       $x isa person, has name "Abigail";
       let $friend in people_pairs_with($x);
      """
    Then answer size is: 5
    Given get answers of typeql read query
      """
      match
       $x isa person;
       let $friend in people_pairs_with($x);
      """
    Then answer size is: 25


  # TODO: Do we want to keep this? Taken from value-predicate
  Scenario: attribute comparison can be used to classify concept pairs as predecessors and successors of each other
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity post,
          plays reply-of:original,
          plays reply-of:reply,
          plays message-succession:predecessor,
          plays message-succession:successor,
          owns creation-date;

      relation reply-of,
          relates original,
          relates reply;

      relation message-succession,
          relates predecessor,
          relates successor;

      attribute creation-date, value datetime;

      fun message-successor-pairs() -> { post, post }:
        match
          (original:$p, reply:$s) isa reply-of;
          $s has creation-date $d1;
          $d1 < $d2;
          (original:$p, reply:$r) isa reply-of;
          $r has creation-date $d2;
        return {$s, $r};
      """
    Given transaction commits

    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert

      $x isa post, has creation-date 2020-07-01;
      $x1 isa post, has creation-date 2020-07-02;
      $x2 isa post, has creation-date 2020-07-03;
      $x3 isa post, has creation-date 2020-07-04;
      $x4 isa post, has creation-date 2020-07-05;
      $x5 isa post, has creation-date 2020-07-06;

      (original:$x, reply:$x1) isa reply-of;
      (original:$x, reply:$x2) isa reply-of;
      (original:$x, reply:$x3) isa reply-of;
      (original:$x, reply:$x4) isa reply-of;
      (original:$x, reply:$x5) isa reply-of;
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match let $x1, $x2 in message-successor-pairs();
      """
    # the (n-1)th triangle number, where n is the number of replies to the first post
    Then answer size is: 10

  Scenario: Functions can return streams of instances or values.
    Given connection open schema transaction for database: typedb
    Given typeql write query
    """
    insert
    $p1 isa person, has ref 0, has name "Alice";
    $p2 isa person, has ref 1, has name "Bob";
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun all_persons() -> { person } :
    match
      $p isa person;
    return { $p };

    fun name_values() -> { string } :
    match
      $p isa person, has name $name_attr;
      let $name_value = $name_attr;
    return { $name_value };
    """
    Given transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match let $p in all_persons();
    """
    Then uniquely identify answer concepts
      | p         |
      | key:ref:0 |
      | key:ref:1 |
    When get answers of typeql read query
    """
    match let $name in name_values();
    """
    Then uniquely identify answer concepts
      | name               |
      | value:string:Alice |
      | value:string:Bob   |
    Given transaction closes


  Scenario: Functions can return streams of tuples of instances.
    Given connection open schema transaction for database: typedb
    Given typeql write query
    """
    insert
    $p1 isa person, has ref 0, has name "Alice";
    $p2 isa person, has ref 1, has name "Bob";
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun name_owners() -> { person, string } :
    match
      $p isa person, has name $name_attr;
      let $name_value = $name_attr;
    return { $p, $name_value };
    """
    Given transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match let $person, $name in name_owners();
    """
    Then uniquely identify answer concepts
      | person    | name               |
      | key:ref:0 | value:string:Alice |
      | key:ref:1 | value:string:Bob   |
    Given transaction closes

  Scenario: Functions can accept arguments
    Given connection open schema transaction for database: typedb
    Given typeql write query
    """
    insert
    $p1 isa person, has ref 0, has name "Alice";
    $p2 isa person, has ref 1, has name "Bob";
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun persons_of_name_attribute($name: name) -> { person } :
    match
      $p isa person, has name $name;
    return { $p };

    fun persons_of_name_value($name: string) -> { person } :
    match
      $p isa person, has name == $name;
    return { $p };
    """
    Given transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
     $name isa name "Bob";
     let $person in persons_of_name_attribute($name);
    """
    Then uniquely identify answer concepts
      | person    | name          |
      | key:ref:1 | attr:name:Bob |

    When get answers of typeql read query
    """
    match
     let $name = "Bob";
     let $person in persons_of_name_value($name);
    """
    Then uniquely identify answer concepts
      | person    | name             |
      | key:ref:1 | value:string:Bob |
    Given transaction closes


  Scenario: Functions can return single instances.
    Given connection open schema transaction for database: typedb
    Given typeql write query
    """
    insert
    $p1 isa person, has ref 0, has name "Alice";
    $p2 isa person, has ref 1, has name "Bob";
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
    """
    define
    fun person_of_name($name: name) -> person:
    match
      $p isa person, has name $name;
    return first $p;

    fun name_value_of_person($p: person) -> string:
    match
      $p isa person, has name $name_attr;
      let $name_value = $name_attr;
    return first $name_value;

    """
    Given transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match
      $name isa name "Bob";
      let $person = person_of_name($name);
    """
    Then uniquely identify answer concepts
      | person    | name            |
      | key:ref:1 | attr:name:Bob   |

    When get answers of typeql read query
    """
    match
      $person isa person;
      let $name = name_value_of_person($person);
    """
    Then uniquely identify answer concepts
      | person    | name               |
      | key:ref:0 | value:string:Alice |
      | key:ref:1 | value:string:Bob   |
    Given transaction closes


  Scenario: A function can return a value derived from an expression
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      fun add($x: integer, $y: integer) -> { integer }:
      match
        let $z = $x + $y;
      return { $z };
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match let $z in add(2, 3);
      """
    # the (n-1)th triangle number, where n is the number of replies to the first post
    Then uniquely identify answer concepts
      | z            |
      | value:integer:5 |


  Scenario: A function can return a tuple of values derived from a reduce operation
    Given connection open schema transaction for database: typedb
    Given typeql write query
    """
    insert
    $p1 isa person, has ref 1, has name "Alice";
    $p2 isa person, has ref 2, has name "Bob";
    """
    Given transaction commits

    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      fun ref_sum_and_sum_squares() -> integer, integer :
      match
        $ref isa ref;
        let $ref_2 = $ref * $ref;
      return sum($ref), sum($ref_2);
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match let $sum, $squares in ref_sum_and_sum_squares();
      """
    # the (n-1)th triangle number, where n is the number of replies to the first post
    Then uniquely identify answer concepts
      | sum          | squares      |
      | value:integer:3 | value:integer:5 |

