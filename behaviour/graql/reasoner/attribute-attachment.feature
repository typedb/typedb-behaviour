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

      person sub entity,
          plays leader,
          plays team-member,
          has string-attribute,
          has unrelated-attribute,
          has sub-string-attribute,
          has age,
          has is-old;

      tortoise sub entity,
          has age,
          has is-old;

      soft-drink sub entity,
          has retailer;

      team sub relation,
          relates leader,
          relates team-member,
          has string-attribute;

      string-attribute sub attribute, value string;
      retailer sub attribute, value string;
      age sub attribute, value long;
      is-old sub attribute, value boolean;
      sub-string-attribute sub string-attribute;
      unrelated-attribute sub attribute, value string;
      """
    Given the integrity is validated


  Scenario: when a rule copies an attribute from one entity to another, the existing attribute instance is reused
    Given graql define
      """
      define
      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
    When get answers of graql query
      """
      match $x isa person, has string-attribute $y; get;
      """
    Then answer size is: 2
    When get answers of graql query
      """
      match $x isa string-attribute; get;
      """
    Then answer size is: 1


  Scenario: when multiple rules copy attributes from an entity, they all get resolved
    Given graql define
      """
      define
      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      transfer-attribute-value-to-sub-attribute sub rule,
      when {
        $x isa person, has string-attribute $r1;
      },
      then {
        $x has sub-string-attribute $r1;
      };

      transfer-attribute-value-to-unrelated-attribute sub rule,
      when {
        $x isa person, has string-attribute $r1;
      },
      then {
        $x has unrelated-attribute $r1;
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
    Given get answers of graql query
      """
      match $x isa person; get;
      """
    Given answer size is: 2
    When get answers of graql query
      """
      match $x isa person, has attribute $y; get;
      """
    # three attributes for each entity
    Then answer size is: 6


  Scenario: when a rule copies an attribute value to its sub-attribute, a new attribute concept is inferred
    Given graql define
      """
      define
      transfer-attribute-value-to-sub-attribute sub rule,
      when {
        $x isa person, has string-attribute $r1;
      },
      then {
        $x has sub-string-attribute $r1;
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      """
    When get answers of graql query
      """
      match $x isa person, has sub-string-attribute $y; get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match $x isa sub-string-attribute; get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match $x isa string-attribute; $y isa sub-string-attribute; get;
      """
    # 2 SA instances - one base, one sub hence two answers
    Then answer size is: 2


  Scenario: when a rule copies an attribute value to an unrelated attribute, a new attribute concept is inferred
    Given graql define
      """
      define
      transfer-attribute-value-to-unrelated-attribute sub rule,
      when {
        $x isa person, has string-attribute $r1;
      },
      then {
        $x has unrelated-attribute $r1;
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      """
    When get answers of graql query
      """
      match $x isa person, has unrelated-attribute $y; get;
      """
    Then answer size is: 1
    When get answers of graql query
      """
      match $x isa unrelated-attribute; get;
      """
    Then answer size is: 1


  Scenario: when the same attribute is inferred on an entity and relation, both owners are correctly retrieved
    Given graql define
      """
      define
      transfer-string-attribute-to-other-people sub rule,
      when {
        $x isa person, has string-attribute $r1;
        $y isa person;
      },
      then {
        $y has string-attribute $r1;
      };

      transfer-string-attribute-from-people-to-teams sub rule,
      when {
        $x isa person, has string-attribute $y;
        $z isa team;
      },
      then {
        $z has string-attribute $y;
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $geX isa person, has string-attribute "banana";
      $geY isa person;
      (leader:$geX, team-member:$geX) isa team;
      """
    When get answers of graql query
      """
      match $x has string-attribute $y; get;
      """
    Then answer size is: 3


  # TODO: doesn't it feel like this is in the wrong file?
  Scenario: a rule can infer an attribute ownership based on a value predicate
    Given graql define
      """
      define
      tortoises-become-old-at-age-1-year sub rule,
      when {
        $x isa tortoise, has age > 0;
      },
      then {
        $x has is-old true;
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $se isa tortoise, has age 1;
      """
    When get answers of graql query
      """
      match $x has is-old $r; get;
      """
    Then answer size is: 1


  Scenario: a rule can infer an attribute value that did not previously exist in the graph
    Given graql define
      """
      define
      tesco-sells-all-soft-drinks sub rule,
      when {
        $x isa soft-drink;
      },
      then {
        $x has retailer 'Tesco';
      };

      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer 'Ocado';
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
    When get answers of graql query
      """
      match $x has retailer 'Ocado'; get;
      """
    Then answer size is: 2
    When get answers of graql query
      """
      match $x has retailer $r; get;
      """
    Then answer size is: 4
    When get answers of graql query
      """
      match $x has retailer 'Tesco'; get;
      """
    Then answer size is: 2


  Scenario: a rule can make a thing own an attribute that previously had no edges in the graph
    Given graql define
      """
      define
      if-ocado-exists-it-sells-all-soft-drinks sub rule,
      when {
        $x isa retailer;
        $x == 'Ocado';
        $y isa soft-drink;
      },
      then {
        $y has retailer 'Ocado';
      };
      """
    Given the integrity is validated
    Given graql insert
      """
      insert
      $aeX isa soft-drink;
      $aeY isa soft-drink;
      $r "Ocado" isa retailer;
      """
    When get answers of graql query
      """
      match $x isa soft-drink, has retailer 'Ocado'; get;
      """
    Then answer size is: 2
