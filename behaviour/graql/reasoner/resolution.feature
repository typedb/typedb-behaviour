# Constraints
#  Only scenarios where there is only one possible resolution path can be tested in this way

Feature: Graql Reasoner Resolution

  Background: Initialise a session and transaction for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_resolution |
    Given transaction is initialised

  Scenario: `has` matches inferred attribute ownerships

  Scenario: `isa` matches inferred relations

  Scenario: `isa` matches inferred roleplayers in relation instances

  # TODO: should this be allowed?
  Scenario: `isa $x` matches instances that have `$x` as an inferred supertype (?)
