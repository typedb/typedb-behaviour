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
  # SERVER ROUTING #
  ##################

  Scenario: Driver discovers all replicas even when connecting to single server
    Given connection closes
    When connection opens to single server with default authentication
    Then connection is open: true
    Then connection has 3 replicas
    Then connection primary replica exists


  @ignore-typedb-http-driver
  Scenario Outline: Driver discovers all replicas with <routing> server routing mode
    When set operation server routing to: <routing>
    Then connection has 3 replicas
    Then connection primary replica exists
    Examples:
      | routing                 |
      | auto                    |
      | server(127.0.0.1:11729) |
      | server(127.0.0.1:21729) |
      | server(127.0.0.1:31729) |

  ##################
  # DRIVER OPTIONS #
  ##################

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
