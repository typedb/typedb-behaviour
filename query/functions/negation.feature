# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# TODO: Port to 3.0

#noinspection CucumberUndefinedStep
Feature: Negation Resolution

  Background: Set up database
    Given typedb starts
    Given connection opens with default authentication
    Given reasoning schema
      """
      define

      person sub entity,
        owns name,
        owns age,
        plays friendship:friend,
        plays employment:employee;

      company sub entity,
        owns name,
        plays employment:employer;

      place sub entity,
        owns name,
        plays location-hierarchy:subordinate,
        plays location-hierarchy:superior;

      friendship sub relation,
        relates friend;

      employment sub relation,
        relates employee,
        relates employer;

      location-hierarchy sub relation,
        relates subordinate,
        relates superior;

      name sub attribute, value string;
      age sub attribute, value long;
      """
    # each scenario specialises the schema further


  ##############################
  # MATCHING INFERRED CONCEPTS #
  ##############################

  Scenario: negation of a transitive function is resolvable
    Given reasoning schema
      """
      define

      area sub place;
      city sub place;
      country sub place;
      continent sub place;

      rule location-hierarchy-transitivity: when {
          (superior: $a, subordinate: $b) isa location-hierarchy;
          (superior: $b, subordinate: $c) isa location-hierarchy;
      } then {
          (superior: $a, subordinate: $c) isa location-hierarchy;
      };
      """
    Given reasoning data
    """
      insert
      $ar isa area, has name "King's Cross";
      $cit isa city, has name "London";
      $cntry isa country, has name "UK";
      $cont isa continent, has name "Europe";
      (superior: $cont, subordinate: $cntry) isa location-hierarchy;
      (superior: $cntry, subordinate: $cit) isa location-hierarchy;
      (superior: $cit, subordinate: $ar) isa location-hierarchy;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $continent isa continent;
        $area isa area;

      """
    Then verify answer size is: 1
    Given reasoning query
      """
      match
        $continent isa continent;
        $area isa area;
        not {(superior: $continent, subordinate: $area) isa location-hierarchy;};

      """
    Then verify answer size is: 0
    Then verify answers are sound
    Then verify answers are complete


  #####################
  # NEGATION IN RULES #
  #####################


  Scenario: when negating a conjunction, all the conjuction statements must be met for the negation to be met
    Given reasoning schema
      """
      define
      country sub entity, owns name, plays company-country:country;
      company plays company-country:company, plays non-uk:not-in-uk;
      company-country sub relation,
        relates company,
        relates country;
      non-uk sub relation,
        relates not-in-uk;
      rule non-uk-rule: when {
        $x isa company;
        not {
          (country: $y, company: $x) isa company-country;
          $y has name 'UK';
        };
      } then {
        (not-in-uk: $x) isa non-uk;
      };
      """
    Given reasoning data
    """
      insert
      $a isa company, has name "a";
      $b isa company, has name "b";
      $c isa company, has name "c";
      $d isa company, has name "d";

      $e isa country, has name 'UK';
      $f isa country, has name 'France';

      (country: $e, company: $a) isa company-country;
      (country: $e, company: $b) isa company-country;
      (country: $f, company: $c) isa company-country;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match $x isa company;
      """
    Then verify answer size is: 4
    Given reasoning query
      """
      match
        $x isa company;
        not { (not-in-uk: $x) isa non-uk; };

      """
    # Should exclude both the company in France and the company with no country
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
        $x isa company;
        (country: $y, company: $x) isa company-country;
        $y has name "UK";
      get $x;
      """
    Then verify answer set is equivalent for query
      """
      match
        $x isa company;
        { $x has name "a"; } or { $x has name "b"; };

      """


  Scenario: when nesting multiple negations and conjunctions, they are correctly resolved
    Given reasoning schema
      """
      define
      country sub entity, owns name, plays company-country:country;
      company plays company-country:company, plays non-uk:not-in-uk;
      company-country sub relation,
        relates company,
        relates country;
      non-uk sub relation,
        relates not-in-uk;
      rule non-uk-rule: when {
        $x isa company;
        not {
          (country: $y, company: $x) isa company-country;
          $y has name 'UK';
        };
      } then {
        (not-in-uk: $x) isa non-uk;
      };
      """
    Given reasoning data
      """
      insert
      $a isa company, has name "a";
      $b isa company, has name "b";
      $c isa company, has name "c";
      $d isa company, has name "d";

      $e isa country, has name 'UK';
      $f isa country, has name 'France';

      (country: $e, company: $a) isa company-country;
      (country: $e, company: $b) isa company-country;
      (country: $f, company: $c) isa company-country;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
        $x isa company;
        not {
          (not-in-uk: $x) isa non-uk;
          not {
            $x has name "c";
          };
        };

      """
    Then verify answer size is: 3
    Then verify answer set is equivalent for query
      """
      match
        $x isa company;
        not { $x has name "d"; };

      """


  # TODO: krishnan: This is still highly relevant for functions. We might be able to simplify the test though.
  Scenario: when evaluating negation blocks, global subgoals are not updated

  The test highlights a potential issue with eagerly updating global subgoals when branching out to determine whether
  negation conditions are met. When checking negation satisfiability, we are interested in a first answer that can
  prove us wrong - we are not exhaustively exploring all answer options.

  Consequently, if we use the same subgoals as for the main loop, we can end up with a query which answers weren't
  fully consumed but that was marked as visited.

  As a result, if it happens that a negated query has multiple answers and is visited more than a single time
  - because of the admissibility check, answers might be missed.

    Given reasoning schema
      """
      define

      session sub entity,
          plays reported-fault:parent-session,
          plays unanswered-question:parent-session,
          plays logged-question:parent-session,
          plays diagnosis:parent-session;

      fault sub entity,
          plays reported-fault:relevant-fault,
          plays fault-identification:identified-fault,
          plays diagnosis:diagnosed-fault;

      question sub entity,
          owns response,
          plays fault-identification:identifying-question,
          plays logged-question:question-logged,
          plays unanswered-question:question-not-answered;

      response sub attribute, value string;

      reported-fault sub relation,
          relates relevant-fault,
          relates parent-session;

      logged-question sub relation,
          relates question-logged,
          relates parent-session;

      unanswered-question sub relation,
          relates question-not-answered,
          relates parent-session;

      fault-identification sub relation,
          relates identifying-question,
          relates identified-fault;

      diagnosis sub relation,
          relates diagnosed-fault,
          relates parent-session;

      rule no-response-means-unanswered-question: when {
          $ques isa question;
          (question-logged: $ques, parent-session: $ts) isa logged-question;
          not {
              $ques has response $r;
          };
      } then {
          (question-not-answered: $ques, parent-session: $ts) isa unanswered-question;
      };

      rule determined-fault: when {
          (relevant-fault: $flt, parent-session: $ts) isa reported-fault;
          not {
              (question-not-answered: $ques, parent-session: $ts) isa unanswered-question;
              ($flt, $ques) isa fault-identification;
          };
      } then {
          (diagnosed-fault: $flt, parent-session: $ts) isa diagnosis;
      };
      """
    Given reasoning data
    """
      insert
      $sesh isa session;
      $q1 isa question;
      $q2 isa question;
      $f1 isa fault;
      $f2 isa fault;
      (relevant-fault: $f1, parent-session: $sesh) isa reported-fault;
      (relevant-fault: $f2, parent-session: $sesh) isa reported-fault;

      (question-logged: $q1, parent-session: $sesh) isa logged-question;
      (question-logged: $q2, parent-session: $sesh) isa logged-question;

      (identified-fault: $f1, identifying-question: $q1) isa fault-identification;
      (identified-fault: $f2, identifying-question: $q2) isa fault-identification;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match (diagnosed-fault: $flt, parent-session: $ts) isa diagnosis;
      """
    Then verify answer size is: 0
    Then verify answers are consistent across 5 executions
    Then verify answers are sound
    Then verify answers are complete


  # TODO: Re-enable once fixed (Completeness found missing answer)
  @ignore
  Scenario: a rule can use negation to exclude things that have any transitive relations to a specific concept
    Given reasoning schema
      """
      define

      indexable sub entity,
          owns index;

      traversable sub indexable,
          plays link:from,
          plays link:to,
          plays reachable:from,
          plays reachable:to,
          plays unreachable:from,
          plays unreachable:to;

      node sub traversable;

      link sub relation, relates from, relates to;
      reachable sub relation, relates from, relates to;
      unreachable sub relation, relates from, relates to;

      index sub attribute, value string;

      rule reachability-transitivityA: when {
          (from: $x, to: $y) isa link;
      } then {
          (from: $x, to: $y) isa reachable;
      };

      rule reachability-transitivityB: when {
          (from: $x, to: $z) isa link;
          (from: $z, to: $y) isa reachable;
      } then {
          (from: $x, to: $y) isa reachable;
      };

      rule unreachability-rule: when {
          $x isa node;
          $y isa node;
          not {(from: $x, to: $y) isa reachable;};
      } then {
          (from: $x, to: $y) isa unreachable;
      };
      """
    Given reasoning data
    """
      insert

      $aa isa node, has index "aa";
      $bb isa node, has index "bb";
      $cc isa node, has index "cc";
      $dd isa node, has index "dd";
      $ee isa node, has index "ee";
      $ff isa node, has index "ff";
      $gg isa node, has index "gg";
      $hh isa node, has index "hh";

      (from: $aa, to: $bb) isa link;
      (from: $bb, to: $cc) isa link;
      (from: $cc, to: $cc) isa link;
      (from: $cc, to: $dd) isa link;
      (from: $ee, to: $ff) isa link;
      (from: $ff, to: $gg) isa link;
      """
    Given verifier is initialised
    Given reasoning query
    """
      match
        (from: $x, to: $y) isa unreachable;
        $x has index "aa";

      """
    # aa is not linked to itself. ee, ff, gg are linked to each other, but not to aa. hh is not linked to anything
    Then verify answer size is: 5
    Then verify answers are sound
    Then verify answers are complete
    Then verify answer set is equivalent for query
      """
      match
        $x has index "aa"; $y isa node;
        { $y has index "aa"; } or { $y has index "ee"; } or { $y has index "ff"; } or
        { $y has index "gg"; } or { $y has index "hh"; };

      """


  Scenario: Negated concept considers all rules & retrievables
    Derived from issue #6500
    Given reasoning schema
      """
      define

      place plays passage:from,
            plays passage:to,
            plays reachable:from,
            plays reachable:to;

      passage sub relation,
          relates from,
          relates to;

      reachable sub relation,
          relates from,
          relates to;

      rule location-hierarchy-transitivity: when {
          (superior: $a, subordinate: $b) isa location-hierarchy;
          (superior: $b, subordinate: $c) isa location-hierarchy;
      } then {
          (superior: $a, subordinate: $c) isa location-hierarchy;
      };

      rule reachable-rule:
          when {
              $from isa place;
              $to isa place;
              $common-superior isa place;
              (superior: $common-superior, subordinate: $from) isa location-hierarchy;
              (from: $common-superior, to: $to) isa passage;
              not {$common-superior is $to;};
              not {(superior: $to, subordinate: $from) isa location-hierarchy;};
          } then {
              (from: $from, to: $to) isa reachable;
          };
      """
    Given reasoning data
      """
      insert
      $forest isa place, has name "forest";
      $cabin isa place, has name "cabin";
      $common-room isa place, has name "common room";
      $fridge isa place, has name "fridge";

      (superior: $forest, subordinate: $cabin) isa location-hierarchy;
      (superior: $cabin, subordinate: $common-room) isa location-hierarchy;
      (superior: $common-room, subordinate: $fridge) isa location-hierarchy;
      (from: $forest, to: $common-room) isa passage;
      """
    Given verifier is initialised
    Given reasoning query
      """
      match
      $from isa place, has name $from-name;
      $to isa place, has name $to-name;
      (from: $from, to: $to) isa reachable;
      get $from-name, $to-name;
      """
    Then verify answer size is: 2
    Then verify answers are sound
    Then verify answers are complete
