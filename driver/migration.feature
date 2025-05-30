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
        entity content @abstract, owns id @key;
        entity page @abstract, sub content @card(0..1000), owns name @card(0..), owns bio @card(1), plays posting:page @card(0..), plays following:page;
        entity profile sub page, owns name @card(0..3), owns profile-id;
        entity post @abstract, sub content, owns post-id, owns post-text, owns creation-timestamp @card(1), plays posting:post @card(1), plays commenting:parent @card(1), plays reaction:parent @card(1);
        entity text-post sub post;
        entity image-post sub post, owns post-image;
        entity comment sub content, owns comment-id, owns comment-text, owns creation-timestamp, owns tag, plays commenting:comment, plays commenting:parent, plays reaction:parent;

        relation interaction @abstract, relates subject @card(1), relates content @card(1);
        relation content-engagement @abstract, sub interaction, relates author as subject;
        relation posting, sub content-engagement, relates page as content, relates post;
        relation commenting, sub content-engagement, relates parent as content, relates comment;
        relation reaction, sub content-engagement, relates parent as content, owns emoji("like", "love", "funny", "surprise", "sad", "angry"), owns creation-timestamp;

        attribute address, value string @regex("\b((https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,})(\/[^\s]*)?\b");
        attribute content, value string;
        attribute name, value string;
        attribute bio, value string;
        attribute id @abstract;
        attribute post-id sub id, value integer;
        attribute profile-id sub id, value string;
        attribute creation-timestamp, value datetime;
        attribute is-deleted, value boolean;
        attribute emoji, value string @values("like", "love", "funny", "surprise", "sad", "angry", "test");
        attribute post-image, value string;

        fun age($person: person) -> age:
          match
            $person has $age;
            $age isa age;
          return first $age;
      """
#    Given typeql write query
#      """
#      insert
#        # TODO
#      """
#    Given transaction commits
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
