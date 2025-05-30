# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required migration functionality of TypeDB drivers. The files in this package
# can be used to test any client application which aims to support all the operations presented in this file for the
# complete user experience. The following steps are suitable and strongly recommended for both CORE and CLOUD drivers.
# NOTE: for complete guarantees, all the drivers are also expected to cover the `connection` package.

#noinspection CucumberUndefinedStep
Feature: Driver Migration

  Background: Open connection, create driver, create database
    Given typedb starts
    Given connection is open: false
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection has database: typedb

  ##########
  # EXPORT #
  ##########

  Scenario: Exported database's schema is the same as the one from database schema interface
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define
        entity website, owns name @card(1), owns address @regex("\b((https?:\/\/)?([a-zA-Z0-9\-]+\.)?typedb\.com(\/[^\s]*)?)\b");
        entity content @abstract, owns id @card(1);
        entity page @abstract, sub content, owns name @card(0..), owns bio @card(1), plays posting:page @card(0..), plays following:page;
        entity profile sub page, owns name @card(1..3), owns profile-id @key, plays content-engagement:author, plays following:follower;
        entity group sub page, owns name @card(1), owns group-id @key;
        entity post @abstract, sub content, owns post-id @key, owns post-text, owns creation-timestamp @card(1), plays posting:post @card(1), plays commenting:parent, plays reaction:parent;
        entity text-post sub post;
        entity image-post sub post, owns post-image;
        entity comment sub content, owns comment-id @key, owns comment-text, owns creation-timestamp, plays commenting:comment, plays commenting:parent, plays reaction:parent;

        relation interaction @abstract, relates subject @card(1), relates content @card(1);
        relation content-engagement @abstract, sub interaction, relates author as subject;
        relation posting, sub content-engagement, relates page as content, relates post @card(1);
        relation commenting, sub content-engagement, relates parent as content, relates comment @card(1);
        relation reaction, sub content-engagement, relates parent as content, owns emoji @card(0..10) @values("like", "love", "funny", "surprise", "sad", "angry"), owns creation-timestamp @card(1);
        relation following, relates follower @card(1), relates page @card(1);

        attribute address @independent, value string @regex("\b((https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,})(\/[^\s]*)?\b");
        attribute name, value string;
        attribute id @abstract;
        attribute post-id sub id, value integer;
        attribute profile-id sub id, value string;
        attribute group-id sub id, value string;
        attribute comment-id sub id, value decimal;
        attribute creation-timestamp, value datetime;
        attribute is-deleted, value boolean;
        attribute emoji, value string @values("like", "love", "funny", "surprise", "sad", "angry", "test");
        attribute post-image, value string;
        attribute payload @abstract, value string;
        attribute text-payload @abstract, sub payload;
        attribute image-payload @abstract, sub payload;
        attribute bio sub text-payload;
        attribute comment-text sub text-payload;
        attribute post-text sub text-payload;

        fun count_likes($content: content) -> integer:
          match
            $like isa emoji "like";
            let $count = count_emojis($content, $like);
          return first $count;

        fun count_emojis($content: content, $emoji: emoji) -> integer:
          match
            $reaction isa reaction, links ($content), has $emoji;
            return count($reaction);
      """
  Given transaction commits
  Then connection get database(typedb) has schema:
      """
      define
        entity website, owns name @card(1), owns address @regex("\b((https?:\/\/)?([a-zA-Z0-9\-]+\.)?typedb\.com(\/[^\s]*)?)\b");
        entity content @abstract, owns id @card(1);
        entity page @abstract, sub content, owns name @card(0..), owns bio @card(1), plays posting:page @card(0..), plays following:page;
        entity profile sub page, owns name @card(1..3), owns profile-id @key, plays content-engagement:author, plays following:follower;
        entity group sub page, owns name @card(1), owns group-id @key;
        entity post @abstract, sub content, owns post-id @key, owns post-text, owns creation-timestamp @card(1), plays posting:post @card(1), plays commenting:parent, plays reaction:parent;
        entity text-post sub post;
        entity image-post sub post, owns post-image;
        entity comment sub content, owns comment-id @key, owns comment-text, owns creation-timestamp, plays commenting:comment, plays commenting:parent, plays reaction:parent;

        relation interaction @abstract, relates subject @card(1), relates content @card(1);
        relation content-engagement @abstract, sub interaction, relates author as subject;
        relation posting, sub content-engagement, relates page as content, relates post @card(1);
        relation commenting, sub content-engagement, relates parent as content, relates comment @card(1);
        relation reaction, sub content-engagement, relates parent as content, owns emoji @card(0..10) @values("like", "love", "funny", "surprise", "sad", "angry"), owns creation-timestamp @card(1);
        relation following, relates follower @card(1), relates page @card(1);

        attribute address @independent, value string @regex("\b((https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,})(\/[^\s]*)?\b");
        attribute name, value string;
        attribute id @abstract;
        attribute post-id sub id, value integer;
        attribute profile-id sub id, value string;
        attribute group-id sub id, value string;
        attribute comment-id sub id, value decimal;
        attribute creation-timestamp, value datetime;
        attribute is-deleted, value boolean;
        attribute emoji, value string @values("like", "love", "funny", "surprise", "sad", "angry", "test");
        attribute post-image, value string;
        attribute payload @abstract, value string;
        attribute text-payload @abstract, sub payload;
        attribute image-payload @abstract, sub payload;
        attribute bio sub text-payload;
        attribute comment-text sub text-payload;
        attribute post-text sub text-payload;

        fun count_likes($content: content) -> integer:
          match
            $like isa emoji "like";
            let $count = count_emojis($content, $like);
          return first $count;

        fun count_loves($content: content) -> integer:
          match
            $love isa emoji "love";
            let $count = count_emojis($content, $love);
          return first $count;

        fun count_emojis($content: content, $emoji: emoji) -> integer:
          match
            $reaction isa reaction, links ($content), has $emoji;
            return count($reaction);
      """
    Given connection open write transaction for database: typedb
    Given typeql write query
      """
      insert
        $now isa creation-timestamp 2025-05-30T14:00:00;
        $a isa address "http://www.googel.com/steal-passwords";

        $w isa website, has name "TypeDB Site", has address "https://typedb.com/features";
        $w2 isa website, has name "TypeDB Documentation", has address "https://typedb.com/docs/home/";
        $p isa profile, has name "John Doe", has profile-id "john-doe-001", has bio "Tech enthusiast and database expert.";
        $p2 isa profile, has name "Bob Marley", has profile-id "bob-marley-001", has bio "Just a man.";
        $p3 isa profile, has name "Alice Cooper", has profile-id "alice-cooper-001", has bio "Just Alice.";
        $p4 isa profile, has name "Alice Cooper", has profile-id "alice-cooper-002", has bio "Another Alice.";
        $p5 isa profile, has name "John Dunk", has name "John Doe", has profile-id "john-dunk-001", has bio "Tech enthusiast and database expert.";
        $p6 isa profile, has name "John Dunk", has name "Alice Cooper", has name "Bob Marley", has profile-id "john-dunk-112", has bio "Tech enthusiast and database expert!";
        $g isa group, has name "Testing TypeDB with my friends", has group-id "how-to-typedb-part-100000", has bio "We love testing!";
        $g2 isa group, has name "John Dunk", has group-id "john-dunk-001", has bio "John Dunk's personal group.";
        $g3 isa group, has name "Alice Cooper", has group-id "alice-cooper-002", has bio "We love Alice Cooper!";
        $g4 isa group, has name "Alice Cooper", has group-id "alice-cooper-003", has bio "We love Alice Cooper!";
        $c isa comment, has comment-id 101.5dec, has comment-text "Great post!", has creation-timestamp 2025-05-29T17:30:05;
        $c2 isa comment, has comment-id 53.445dec, has comment-text "OMG", has creation-timestamp 2025-04-23T03:30:05;
        $c3 isa comment, has comment-id 111.111dec, has comment-text "like", has creation-timestamp 2025-04-25T07:22:32;
        $c4 isa comment, has comment-id 111.112dec, has comment-text "like", has creation-timestamp 2025-04-25T07:23:03;

        (follower: $p2, page: $p) isa following;
        (follower: $p, page: $p2) isa following;
        (follower: $p, page: $g) isa following;
        (follower: $p, page: $g4) isa following;
        (follower: $p6, page: $g2) isa following;
        (follower: $p6, page: $g3) isa following;
        (follower: $p6, page: $g4) isa following;
        (follower: $p3, page: $g4) isa following;

        $tp isa text-post, has post-id 1001, has post-text "Hello from TypeDB!", has creation-timestamp 2020-03-02T00:00:00;
        (author: $p, page: $p, post: $tp) isa posting;
        (author: $p, comment: $c, parent: $tp) isa commenting;
        (author: $p6, comment: $c2, parent: $tp) isa commenting;
        (parent: $tp, author: $p6) isa reaction, has emoji "funny", has creation-timestamp 2025-05-05T05:05:05;

        $ip isa image-post, has post-id 1002, has post-text "Look at this diagram!", has post-image "https://typedb.com/img/schema.png", has creation-timestamp 2025-05-30T07:30:05;
        (parent: $ip, author: $p) isa reaction, has emoji "like", has creation-timestamp $now;
        (parent: $ip, author: $p) isa reaction, has emoji "love", has creation-timestamp $now;
        (parent: $ip, author: $p2) isa reaction, has emoji "like", has creation-timestamp 2025-03-03T00:00:00;
        (parent: $ip, author: $p3) isa reaction, has emoji "surprise", has creation-timestamp 2025-03-03T13:03:03;
        (author: $p2, page: $p, post: $ip) isa posting;
        (author: $p, comment: $c3, parent: $ip) isa commenting;
        (author: $p2, comment: $c4, parent: $c3) isa commenting;
      """
    Given transaction commits
#
#    Given file(schema.tql) does not exist
#    Given file(data.typedb) does not exist
#    When database export to schema file(schema.tql), data file(data.typedb)
#    Then file(schema.tql) exists
#    Then file(data.typedb) exists
#    Then file(schema.tql) is not empty
#    Then file(data.typedb) is not empty
#    Then file(schema.tql) contains:
#    """
#    define
#      entity person @abstract, owns age @card(1..1);
#      entity real-person sub person;
#      entity not-real-person @abstract, sub person;
#      attribute age, value integer @range(0..150);
#      relation friendship, relates friend;
#      relation best-friendship sub friendship, relates best-friend as friend;
#
#      fun age($person: person) -> age:
#        match
#          $person has $age;
#          $age isa age;
#        return first $age;
#    """
#
#    When connection open read transaction for database: typedb
#    Then connection get database(typedb) has schema:
#    """
#    define
#      entity person @abstract, owns age @card(1..1);
#      entity real-person sub person;
#      entity not-real-person @abstract, sub person;
#      attribute age, value integer @range(0..150);
#      relation friendship, relates friend;
#      relation best-friendship sub friendship, relates best-friend as friend;
#
#      fun age($person: person) -> age:
#        match
#          $person has $age;
#          $age isa age;
#        return first $age;
#    """

# TODO: Cover errors

  ##########
  # IMPORT #
  ##########

  # TODO: Cover everything
