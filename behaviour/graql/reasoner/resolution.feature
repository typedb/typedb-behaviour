# Constraints
#  Only scenarios where there is only one possible resolution path can be tested in this way

# TODO: these tests should be implemented somewhere, but probably not in a file called 'resolution.feature'
Feature: Graql Reasoner Resolution

  Background: Initialise a session and transaction for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_resolution |
    Given transaction is initialised

  Scenario: `isa` matches inferred relations

  Scenario: `isa` matches inferred roleplayers in relation instances

  Scenario: `isa` matches inferred types that are subtypes of the thing's defined type

  Scenario: `isa` matches inferred types that are unrelated to the thing's defined type
