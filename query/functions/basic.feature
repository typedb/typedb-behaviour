# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Relation Inference Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb


  Scenario: when matching all possible pairs inferred from n concepts, the answer size is the square of n
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define

      entity person,
      owns name,
      plays friendship:friend;

      relation friendship,
        relates friend;

      attribute name value string;

      fun friends-of($who: person) -> { person } :
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
      $a isa person, has name "Abigail";
      $b isa person, has name "Bernadette";
      $c isa person, has name "Cliff";
      $d isa person, has name "Damien";
      $e isa person, has name "Eustace";
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match
       $x isa person, has name "Abigail";
       $friend in friends-of($x);
      """
    Then answer size is: 5
    Given get answers of typeql read query
      """
      match
       $x isa person;
       $friend in friends-of($x);
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
      match $x1, $x2 in message-successor-pairs();
      """
    # the (n-1)th triangle number, where n is the number of replies to the first post
    Then answer size is: 10


  Scenario: A function can return a value derived from an expression
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
      fun add($x: long, $y: long) -> { long }:
      match
        $z = $x + $y;
      return { $z };
      """
    Given transaction commits

    Given connection open read transaction for database: typedb
    Given get answers of typeql read query
      """
      match $z in add(2, 3);
      """
    # the (n-1)th triangle number, where n is the number of replies to the first post
    Then uniquely identify answer concepts
      | z            |
      | value:long:5 |


