# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# These tests are dedicated to test the required cluster functionality of TypeDB drivers.
# NOTE: This file should be run only against cluster deployments with 3 replicas.

#noinspection CucumberUndefinedStep
Feature: Driver Cluster

  Background: Open connection, verify cluster setup
    Given typedb starts
    Given connection opens with default authentication
    Given connection is open: true

  ###########
  # REPLICA #
  ###########

  Scenario: Driver can discover replicas in a cluster
    Then connection has 3 replicas
    Then connection primary replica exists
    Then connection get replica(127.0.0.1:11729) exists
    Then connection get replica(127.0.0.1:21729) exists
    Then connection get replica(127.0.0.1:31729) exists


  Scenario: Driver can query replica terms
    Then connection has 3 replicas
    Then connection get replica(127.0.0.1:11729) has term
    Then connection get replica(127.0.0.1:21729) has term
    Then connection get replica(127.0.0.1:31729) has term


  Scenario: Driver can inspect replica roles
    Then connection has 3 replicas
    Then connection replicas have roles:
      | primary   |
      | secondary |
      | secondary |

  ##################
  # DRIVER OPTIONS #
  ##################

  @ignore-typedb-http-driver
  Scenario: Driver discovers all replicas even when connecting to single server
    When connection closes
    When connection opens to single server with default authentication
    Then connection is open: true
    Then connection has 3 replicas
    Then connection primary replica exists


  # TODO: Test that primary_failover_retries actually works by simulating failover
  @ignore-typedb-http-driver
  Scenario: Driver can configure failover retries
    When connection closes
    When set driver option primary_failover_retries to: 5
    When connection opens with default authentication
    Then connection is open: true


  # TODO: Test that replica_discovery_attempts actually works by limiting discovery
  @ignore-typedb-http-driver
  Scenario: Driver can configure replica discovery attempts
    When connection closes
    When set driver option replica_discovery_attempts to: 10
    When connection opens with default authentication
    Then connection is open: true
    Then connection has 3 replicas

  #######################
  # CONSISTENCY - READS #
  #######################

  @ignore-typedb-http-driver
  Scenario Outline: Driver can open read transaction with <consistency> consistency
    Given connection create database: typedb
    Given connection open schema transaction for database: typedb
    Given typeql schema query
      """
      define entity person;
      """
    Given transaction commits
    When set transaction option read_consistency_level to: <consistency>
    When connection open read transaction for database: typedb
    Then transaction is open: true
    Then transaction has type: read
    When get answers of typeql read query
      """
      match entity $x;
      """
    Then answer size is: 1
    When transaction closes
    Examples:
      | consistency              |
      | strong                   |
      | eventual                 |
      | replica(127.0.0.1:21729) |
      | replica(127.0.0.1:11729) |

  ########################
  # CONSISTENCY - WRITES #
  ########################

  @ignore-typedb-http-driver
  Scenario Outline: Driver schema and write transactions succeed regardless of consistency option (<consistency>)
    Given connection create database: typedb
    When set transaction option read_consistency_level to: <consistency>
    When connection open schema transaction for database: typedb
    Then transaction is open: true
    Then transaction has type: schema
    Then typeql schema query
      """
      define entity person;
      """
    When transaction commits
    When connection open write transaction for database: typedb
    Then transaction is open: true
    Then transaction has type: write
    Then typeql write query
      """
      insert $p isa person;
      """
    When transaction commits
    When connection open read transaction for database: typedb
    When get answers of typeql read query
      """
      match $x isa person;
      """
    Then answer size is: 1
    Examples:
      | consistency              |
      | strong                   |
      | eventual                 |
      | replica(127.0.0.1:21729) |
      | replica(127.0.0.1:11729) |

  ###################################
  # DATABASE CONSISTENCY OPERATIONS #
  ###################################

  @ignore-typedb-http-driver
  Scenario Outline: Database operations work with <consistency> consistency
    When set database operation consistency to: <consistency>
    Given connection has 0 databases
    When connection create database: consistency-test-db
    Then connection has 1 database
    When connection create database: typedb
    Then connection has 2 databases
    Then connection has databases:
      | consistency-test-db |
      | typedb              |
    Then connection has database: consistency-test-db
    When connection delete database: consistency-test-db
    Then connection has 1 database
    When connection delete database: typedb
    Then connection has 0 databases
    Examples:
      | consistency              |
      | strong                   |
      | eventual                 |
      | replica(127.0.0.1:21729) |
      | replica(127.0.0.1:11729) |
