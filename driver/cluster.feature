# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required cluster-specific functionalities of TypeDB drivers. The files in this package
# can be used to test any client application which aims to support all the operations presented in this file for the
# complete user experience. The following steps are suitable and strongly recommended for both CORE and CLOUD drivers.

# NOTE: It's hard to cover many cluster-specific features in behavior tests, so pay more attention to more flexible
# integration testing.

#noinspection CucumberUndefinedStep
Feature: Driver Cluster

  Background: Open connection, create driver, create database
    Given typedb starts
    Given connection is open: false
    Given connection opens with default authentication
    Given connection is open: true
    Given connection has 0 databases
    Given connection create database: typedb
    Given connection has database: typedb

  #######################
  # ADDRESS TRANSLATION #
  #######################

  Scenario: Driver can work with connection with address translation
    Given connection closes
    Given connection is open: false
    When connection opens with default address translation with default authentication
    Then connection is open: true

    Then connection has 1 user
    When create user with username 'user', password 'password'
    Then connection has 2 users

    Then connection has 1 database
    When connection create database: second
    Then connection has 2 databases

    When connection open schema transaction for database: typedb
    When typeql schema query
    """
    define
      entity person @abstract, owns name;
      attribute name, value string;
    """
    Then transaction commits
    Then connection get database(typedb) has schema:
    """
    define
      entity person @abstract, owns name;
      attribute name, value string;
    """

    When connection open read transaction for database: typedb
    When get answers of typeql read query
    """
    match entity $p;
    """
    Then answer size is: 1

