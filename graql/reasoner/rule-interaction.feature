#
# Copyright (C) 2020 Grakn Labs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

#noinspection CucumberUndefinedStep
Feature: Rule Interaction Resolution

  Background: Set up databases for resolution testing

    Given connection has been opened
    Given connection delete all databases
    Given connection open sessions for databases:
      | materialised |
      | reasoned     |
    Given materialised database is named: materialised
    Given reasoned database is named: reasoned
    Given for each session, graql define
      """
      define

      person sub entity,
      plays team:leader,
      plays team:member,
      plays employment:employee,
      owns name;

      employment sub relation,
      relates employee;

      team sub relation,
      relates leader,
      relates member;

      name sub attribute, value string;
      """


  ###########################
  # RULE INTERACTIONS BELOW #
  ###########################


  #  NOTE: There is a currently known bug in core 1.8.3 that makes this test fail (issue #5891)
  #  We will hope this is fixed by 2.0 as a result of mor robust alpha equivalence definition
Scenario: when rules are similar but different the reasoner knows to distinguish the rules
  Given for each session, graql define
    """
    define

    person
    plays lesson:teacher,
    plays lesson:student,
    owns tag;

    lesson sub relation,
    relates teacher,
    relates student;

    tag sub attribute, value string;

    rule tag-teacher-leaders:
    when {
      $x isa person;
      $y isa person;
      (student: $x, teacher: $y) isa lesson;
      (member: $x, member: $y, leader: $y) isa teams;
    } then {
      $y has tag "P";
    }

    rule tag-teacher-members:
    when {
      $x isa person;
      $y isa person;
      (student: $x, teacher: $y) isa lesson;
      (member: $x, member: $y, leader: $x) isa teams;
    } then {
      $y has tag "P";
    }
    """
  Given for each session, graql insert
    """
    insert

    $bob isa person, has name "bob";
    $alice isa person, has name "alice";
    $charlie isa person, has name "charlie";
    $dennis isa person, has name "dennis";

    (attendee: $bob, speaker: $alice) isa conference;
    (member: $alice, member: $bob, host: $alice) isa party;

    (attendee: $charlie, speaker: $dennis) isa conference;
    (member: $charlie, member: $dennis, host: $charlie) isa party;
    """
  When materialised database is completed
      """
      match $x isa person, has name $n, has tag "P"; get;
      """
  Then all answers are correct in reasoned database
  Then answer size in reasoned database is: 2
  Then materialised and reasoned databases are the same size

