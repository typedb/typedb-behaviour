# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#noinspection CucumberUndefinedStep
Feature: Effects a function signature have on the caller

  Background: Set up database
    # TODO


  Scenario: Functions whose return do not match the signature error
    # TODO: stream/single mismatch, count category mismatch


  Scenario: Functions which do not return the specified type fail type-inference
    # TODO:


  Scenario: Functions arguments which are inconsistent with the body fail type-inference
    # TODO:


  Scenario: Function calls which do not match the arguments in the signature error
    # TODO: Count, category mismatch


  Scenario: If the assignment of the return of the function calls do not match the signature, it is an error
    # TODO: Stream/single mismatch, count, category mismatch


  Scenario: Function calls with argument types inconsistent with the signature fail type-inference
    # TODO:


  Scenario: Function calls with assigned variable types inconsistent with the signature fail type-inference
    # TODO

