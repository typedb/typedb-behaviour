# Constraints
#  Only scenarios where there is only one possible resolution path can be tested in this way

Feature: Graql Reasoner Attribute Attachment

  Background: Initialise a session and transaction for each scenario
    Given connection has been opened
    Given connection delete all keyspaces
    Given connection open sessions for keyspaces:
      | test_attribute_attachment |
    Given transaction is initialised
    Given the integrity is validated
    Given graql define
      """
      define

      genericEntity sub entity,
          plays someRole,
          plays otherRole,
          has reattachable-resource-string,
          has unrelated-reattachable-string,
          has subResource,
          has resource-long,
          has derived-resource-boolean;

      anotherEntity sub entity,
          has resource-long,
          has derived-resource-boolean;

      yetAnotherEntity sub entity,
          has derived-resource-string;

      relation0 sub relation,
          relates someRole,
          relates otherRole,
          has reattachable-resource-string;

      derivable-resource-string sub attribute, value string;
      reattachable-resource-string sub derivable-resource-string, value string;
      derived-resource-string sub derivable-resource-string, value string;
      resource-long sub attribute, value long;
      derived-resource-boolean sub attribute, value boolean;
      subResource sub reattachable-resource-string;
      unrelated-reattachable-string sub attribute, value string;

      transferResourceToEntity sub rule,
      when {
          $x isa genericEntity, has reattachable-resource-string $r1;
          $y isa genericEntity;
      },
      then {
          $y has reattachable-resource-string $r1;
      };

      transferResourceToRelation sub rule,
      when {
          $x isa genericEntity, has reattachable-resource-string $y;
          $z isa relation0;
      },
      then {
          $z has reattachable-resource-string $y;
      };

      attachResourceValueToResourceOfDifferentSubtype sub rule,
      when {
          $x isa genericEntity, has reattachable-resource-string $r1;
      },
      then {
          $x has subResource $r1;
      };

      attachResourceValueToResourceOfUnrelatedType sub rule,
      when {
          $x isa genericEntity, has reattachable-resource-string $r1;
      },
      then {
          $x has unrelated-reattachable-string $r1;
      };

      setResourceFlagBasedOnOtherResourceValue sub rule,
      when {
          $x isa anotherEntity, has resource-long > 0;
      },
      then {
          $x has derived-resource-boolean true;
      };

      attachResourceToEntity sub rule,
      when {
          $x isa yetAnotherEntity;
      },
      then {
          $x has derived-resource-string 'value';
      };

      attachUnattachedResourceToEntity sub rule,
      when {
          $x isa derived-resource-string;
          $x == 'unattached';
          $y isa yetAnotherEntity;
      },
      then {
          $y has derived-resource-string 'unattached';
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert

      $geX isa genericEntity, has reattachable-resource-string "value";
      $geY isa genericEntity;
      (someRole:$geX, otherRole:$geX) isa relation0;

      $se isa anotherEntity, has resource-long 1;
      $aeX isa yetAnotherEntity;
      $aeY isa yetAnotherEntity;

      $r "unattached" isa derived-resource-string;
      """


  Scenario: when using a non-persisted value type, no duplicates are created
    Given get answers of graql query
      """
      match $x isa genericEntity; get;
      """
    Given answer size is: 2
    When get answers of graql query
      """
      match $x isa genericEntity, has reattachable-resource-string $y; get;
      """
    # two attributes for each entity
    Then answer size is: 4
    When get answers of graql query
      """
      match $x isa reattachable-resource-string; get;
      """
    # one base attribute, one sub
    Then answer size is: 2


  Scenario: reusing attributes, quering for generic ownership
    Given get answers of graql query
      """
      match $x isa genericEntity; get;
      """
    Given answer size is: 2
    When get answers of graql query
      """
      match $x isa genericEntity, has attribute $y; get;
      """
    # three attributes for each entity
    Then answer size is: 6


  Scenario: reusing attributes, using existing attribute to create sub-attribute
    Given get answers of graql query
      """
      match $x isa genericEntity; get;
      """
    Given answer size is: 2
    When get answers of graql query
      """
      match $x isa genericEntity, has subResource $y; get;
      """
    Then answer size is: 2
    When get answers of graql query
      """
      match $x isa subResource; get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match $x isa reattachable-resource-string; $y isa subResource; get;
      """
    # 2 RRS instances - one base, one sub hence two answers
    Then answer size is: 2


  Scenario: reusing attributes, using existing attribute to create unrelated attribute
    Given get answers of graql query
      """
      match $x isa genericEntity; get;
      """
    Given answer size is: 2
    When get answers of graql query
      """
      match $x isa genericEntity, has unrelated-reattachable-string $y; get;
      """
    Then answer size is: 2
    When get answers of graql query
      """
      match $x isa unrelated-reattachable-string; get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match $x isa reattachable-resource-string; $y isa unrelated-reattachable-string; get;
      """
    # 2 RRS instances - one base, one sub hence two answers
    Then answer size is: 2


  Scenario: when reasoning with attributes, results are complete
    When get answers of graql query
      """
      match $x has reattachable-resource-string $y; get;
      """
    Then answer size is: 5


  Scenario: reusing attributes, attaching existing attribute to a relation
    Given get answers of graql query
      """
      match $x isa genericEntity; get;
      """
    Given answer size is: 2
    When get answers of graql query
      """
      match $x isa genericEntity, has reattachable-resource-string $y; $z isa relation0; get;
      """
    Then answer size is: 4
    When get answers of graql query
      """
      match $x isa relation0, has reattachable-resource-string $y; get;
      """
    Then answer size is: 1


  Scenario: reusing attributes, deriving attribute from another attribute with conditional value
    When get answers of graql query
      """
      match $x has derived-resource-boolean $r; get;
      """
    Then answer size is: 1


  Scenario: deriving an attribute with a specific value
    When get answers of graql query
      """
      match $x has derived-resource-string 'value'; get;
      """
    Then answer size is: 2
    When get answers of graql query
      """
      match $x has derived-resource-string $r; get;
      """
    Then answer size is: 4
    When get answers of graql query
      """
      match $x has derived-resource-string 'value'; get;
      """
    Then answer size is: 2


  Scenario: reusing attributes: attaching a stray attribute to an entity doesn't throw errors
    When get answers of graql query
      """
      match $x isa yetAnotherEntity, has derived-resource-string 'unattached'; get;
      """
    Then answer size is: 2
