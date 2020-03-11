/*
 * GRAKN.AI - THE KNOWLEDGE GRAPH
 * Copyright (C) 2019 Grakn Labs Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

package grakn.verification.tools.operator.test;

import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import grakn.verification.tools.operator.Operator;
import grakn.verification.tools.operator.Operators;
import grakn.verification.tools.operator.TypeContext;
import graql.lang.Graql;
import graql.lang.pattern.Pattern;
import graql.lang.property.IdProperty;
import graql.lang.property.IsaProperty;
import graql.lang.property.NeqProperty;
import graql.lang.property.ValueProperty;
import graql.lang.property.VarProperty;
import graql.lang.statement.Variable;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.junit.Test;

import static graql.lang.Graql.and;
import static graql.lang.Graql.var;
import static junit.framework.TestCase.assertTrue;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotEquals;

public class OperatorTest {

    private static TypeContext ctx = new MockTypeContext();

    @Test
    public void computeIdentity(){
        Pattern input = and(var().isa("thing"));
        assertEquals(input, Operators.identity().apply(input,null).iterator().next());
    }

    @Test
    public void whenGeneraliseTypeOfASingleStatement_weDecrementTheLabel(){
        Pattern input = and(var("x").isa("subEntity"));
        Pattern expectedOutput = and(var("x").isa("baseEntity"));

        Pattern output = Iterables.getOnlyElement(
                Operators.typeGeneralise().apply(input, ctx).collect(Collectors.toSet())
                );
        assertEquals(expectedOutput, output);

        Pattern secondOutput = Iterables.getOnlyElement(
                Operators.typeGeneralise().apply(output, ctx).collect(Collectors.toSet())
        );
        assertEquals(
                and(var("x").isa("entity")),
                secondOutput);

        Pattern thirdOutput = Iterables.getOnlyElement(
                Operators.typeGeneralise().apply(secondOutput, ctx).collect(Collectors.toSet())
        );
        assertEquals(
                and(var("x").isa(var("xtype"))),
                thirdOutput
        );
    }

    @Test
    public void whenApplyingGeneraliseTypeOperator_weDecrementLabelsOneByOne(){
        Pattern input = and(
                var("r").rel(var("x")).rel(var("y")).isa("subRelation"),
                var("x").isa("subEntity"),
                var("y").isa("subEntity")
                );
        Set<Pattern> expectedOutput = Sets.newHashSet(
                and(
                        var("r").rel(var("x")).rel(var("y")).isa("subRelation"),
                        var("x").isa("baseEntity"),
                        var("y").isa("subEntity")),
                and(
                        var("r").rel(var("x")).rel(var("y")).isa("subRelation"),
                        var("x").isa("subEntity"),
                        var("y").isa("baseEntity")),
                and(
                        var("r").rel(var("x")).rel(var("y")).isa("baseRelation"),
                        var("x").isa("subEntity"),
                        var("y").isa("subEntity"))
        );

        Set<Pattern> output = Operators.typeGeneralise().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenApplyingGeneraliseTypeOperatorToStatementWithVariableType_weRemoveBareIsaStatements(){
        Pattern input = and(
                var("r")
                        .rel(var("rx"), var("x"))
                        .isa(var("rtype")),
                var("x").isa("subEntity")
        );
        Set<Pattern> expectedOutput = Sets.newHashSet(
                and(
                        var("r")
                                .rel(var("rx"), var("x"))
                                .isa(var("rtype")),
                        var("x").isa("baseEntity")
                )
        );
        Set<Pattern> output = Operators.typeGeneralise().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenApplyingTypeGenOperatorMultipleTimes_patternsConvergeToEmpty(){
        Pattern input = and(
                var("r").rel(var("x")).rel(var("y")).isa("subRelation"),
                var("x").isa("subEntity")
        );
        testOperatorConvergence(input, Lists.newArrayList(Operators.typeGeneralise()));
    }

    @Test
    public void whenGeneralisingRoleOfASingleRPStatement_weDecrementTheLabel(){
        Pattern input = and(var("r").rel("baseRole", var("x")));
        Pattern expectedOutput = and(var("r").rel("role", var("x")));

        Pattern output = Iterables.getOnlyElement(
                Operators.roleGeneralise().apply(input, ctx).collect(Collectors.toSet())
        );
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenGeneralisingRoles_weRemoveStrayStatementsIfRPIsRemoved(){
        Pattern input = and(
                var("r").rel(var("rx"), var("x")).rel(var("ry"), var("y")),
                var("x").isa("someType"),
                var("y").isa("someType")
        );
        Set<Pattern> expectedOutput = Sets.newHashSet(
                and(
                        var("r").rel(var("rx"), var("x")),
                        var("x").isa("someType")),
                and(
                        var("r").rel(var("ry"), var("y")),
                        var("y").isa("someType"))
        );
        Set<Pattern> output = Operators.roleGeneralise().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenApplyingGeneraliseRoleOperator_weDecrementLabelsOneByOne(){
        Pattern input = and(
                var("r")
                        .rel("baseRole", var("x"))
                        .rel("subRole", var("y"))
                        .rel("role", var("z")),
                var("x").isa("subEntity"),
                var("y").isa("subEntity")
        );
        Set<Pattern> expectedOutput = Sets.newHashSet(
                and(
                        var("r")
                                .rel("baseRole", var("x"))
                                .rel("subRole", var("y"))
                                .rel(var("zrole"), var("z")),
                        var("x").isa("subEntity"),
                        var("y").isa("subEntity")),
                and(
                        var("r")
                                .rel("baseRole", var("x"))
                                .rel("baseRole", var("y"))
                                .rel("role", var("z")),
                        var("x").isa("subEntity"),
                        var("y").isa("subEntity")),
                and(
                        var("r")
                                .rel("role", var("x"))
                                .rel("subRole", var("y"))
                                .rel("role", var("z")),
                        var("x").isa("subEntity"),
                        var("y").isa("subEntity"))
        );

        Set<Pattern> output = Operators.roleGeneralise().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenApplyingRoleGenOperatorMultipleTimes_patternsConvergeToEmpty(){
        Pattern input = and(
                var("r")
                        .rel("baseRole", var("x"))
                        .rel("subRole", var("y"))
                        .rel("role", var("z")),
                var("x").isa("subEntity"),
                var("y").isa("subEntity")
        );
        testOperatorConvergence(input, Lists.newArrayList(Operators.roleGeneralise()));
    }

    @Test
    public void whenApplyingRemoveSubOperatorOnASingleSubPattern_patternWithNoSubsIsReturned(){
        Pattern singleStatementInput = and(var("x").isa("subEntity").id("V123"));

        Pattern multiStatementInput = and(
                var("x").isa("subEntity"),
                var("x").id("V123")
        );
        Set<Pattern> expectedOutput = Sets.newHashSet(and(var("x").isa("subEntity")));

        Set<Pattern> output = Operators.removeSubstitution().apply(singleStatementInput, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);

        output = Operators.removeSubstitution().apply(multiStatementInput, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenRemovingSubFromPatternWithNoSub_weDoNoop(){
        Pattern input = and(var("x").isa("subEntity"));
        Set<Pattern> output = Operators.removeSubstitution().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(Sets.newHashSet(input), output);
    }

    @Test
    public void whenApplyingRemoveSubOperator_weGenerateCartesianProductOfPossibleSubConfigurations(){
        Pattern input = and(
                var("r").rel(var("x")).rel(var("y")),
                var("x").id("V123"),
                var("y").id("V456"),
                var("z").id("V789")
        );

        Set<Pattern> expectedOutput = Sets.newHashSet(
                and(
                        var("r").rel(var("x")).rel(var("y")),
                        var("x").id("V123")),
                and(
                        var("r").rel(var("x")).rel(var("y")),
                        var("y").id("V456")),
                and(
                        var("r").rel(var("x")).rel(var("y")),
                        var("z").id("V789")),
                and(
                        var("r").rel(var("x")).rel(var("y")),
                        var("x").id("V123"),
                        var("y").id("V456")),
                and(
                        var("r").rel(var("x")).rel(var("y")),
                        var("x").id("V123"),
                        var("z").id("V789")),
                and(
                        var("r").rel(var("x")).rel(var("y")),
                        var("y").id("V456"),
                        var("z").id("V789")),
                and(
                        var("r").rel(var("x")).rel(var("y")))
        );

        Set<Pattern> output = Operators.removeSubstitution().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenApplyingRemoveSubOperatorToPatternWithNoSubs_weDoNoop(){
        Pattern input = and(
                var("r").rel(var("x")).rel(var("y")),
                var("x").isa("subEntity"),
                var("y").isa("subEntity")
        );
        Set<Pattern> output = Operators.removeSubstitution().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(Sets.newHashSet(input), output);
    }

    @Test
    public void whenApplyingRemoveRoleplayerOperator_weGenerateCartesianProductOfPossibleRPConfigurations(){
        Pattern input = and(
                var("r").rel(var("x")).rel(var("y")).rel(var("z")).isa("baseRelation")
        );

        Set<Pattern> expectedOutput = Sets.newHashSet(
                and(var("r").isa("baseRelation")),
                and(var("r").rel(var("x")).rel(var("y")).isa("baseRelation")),
                and(var("r").rel(var("x")).rel(var("z")).isa("baseRelation")),
                and(var("r").rel(var("y")).rel(var("z")).isa("baseRelation")),
                and(var("r").rel(var("x")).isa("baseRelation")),
                and(var("r").rel(var("y")).isa("baseRelation")),
                and(var("r").rel(var("z")).isa("baseRelation"))
        );

        Set<Pattern> output = Operators.removeRoleplayer().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenApplyingRemoveRoleplayerOperator_weRemoveStrayStatements(){
        Pattern input = and(
                var("r").rel(var("rx"), var("x")).rel(var("ry"), var("y")),
                var("x").isa("someType"),
                var("y").isa("someType")
        );
        Set<Pattern> expectedOutput = Sets.newHashSet(
                and(
                        var("r").rel(var("rx"), var("x")),
                        var("x").isa("someType")),
                and(
                        var("r").rel(var("ry"), var("y")),
                        var("y").isa("someType"))
        );
        Set<Pattern> output = Operators.removeRoleplayer().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenApplyingRemoveRoleplayerOperatorToPatternWithNoRPs_weDoNoop(){
        Pattern input = and(var("x").isa("subEntity"));
        Set<Pattern> output = Operators.removeRoleplayer().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(Sets.newHashSet(input), output);
    }

    @Test
    public void whenApplyingGeneraliseAttributeOperator_weExtendTheValueRange(){
        Pattern input = and(var("x").has("someAttribute", Graql.var().eq(1500)));

        Set<Pattern> expectedOutput = Sets.newHashSet(
                and(var("x").has("someAttribute", Graql.var().lt(4500.0).gt(-1500.0)))
        );

        Set<Pattern> output = Stream.of(input)
                .flatMap(p -> Operators.generaliseAttribute().apply(p, ctx))
                .flatMap(p -> Operators.generaliseAttribute().apply(p, ctx))
                .flatMap(p -> Operators.generaliseAttribute().apply(p, ctx))
                .collect(Collectors.toSet());
        assertEquals(expectedOutput, output);

        input = and(
                var("x").has("someAttribute", Graql.var().gt(16)),
                var("x").has("someAttribute", Graql.var().lt(64))
        );

        expectedOutput = Sets.newHashSet(
                and(
                        var("x").has("someAttribute", var().gt(8.0)),
                        var("x").has("someAttribute", var().lt(64))),
                and(
                        var("x").has("someAttribute", var().gt(16)),
                        var("x").has("someAttribute", var().lt(96.0))),
                and(
                        var("x").has("someAttribute", var().gt(8.0)),
                        var("x").has("someAttribute", var().lt(96.0)))
        );

        output = Operators.generaliseAttribute().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(expectedOutput, output);
    }

    @Test
    public void whenApplyingDifferentOperatorsConsecutively_weConvergeToEmptyPattern(){
        Pattern input = and(
                var("r")
                        .rel("subRole", var("x"))
                        .rel("subRole", var("y"))
                        .rel("subRole", var("z")),
                var("x").isa("subEntity"),
                var("x").id("V123"),
                var("y").isa("subEntity"),
                var("y").id("V456"),
                var("z").isa("subEntity"),
                var("z").id("V789")
        );

        testOperatorConvergence(input, Lists.newArrayList(
                Operators.removeSubstitution(),
                Operators.typeGeneralise(),
                Operators.roleGeneralise(),
                Operators.typeGeneralise(),
                Operators.roleGeneralise())
        );
    }

    @Test
    public void whenApplyingVariableFuzzyingOperator_weFuzzAllVariables(){
        Pattern input = and(
                var("r")
                        .rel("subRole", var("x"))
                        .rel("subRole", var("y"))
                        .rel("subRole", var("z")),
                var("x").isa("subEntity"),
                var("x").id("V123"),
                var("y").isa("subEntity"),
                var("y").id("V456"),
                var("z").isa("subEntity"),
                var("z").id("V789")
        );
        Set<Pattern> outputs = Operators.fuzzVariables().apply(input, ctx).collect(Collectors.toSet());
        assertEquals(input.variables().size(), outputs.size());
        outputs.forEach(output -> assertNotEquals(input, output));

        outputs.forEach(output -> Operators.fuzzVariables().apply(output, ctx)
                .forEach(output2 -> assertNotEquals(output, output2)));
    }

    @Test
    public void whenApplyingVariableFuzzyingOperatorToPatternWithBinaryProperties_weFuzzAllVariables(){
        Pattern input = and(
                var("r").has("someAttribute", Graql.var("v")),
                var("r").isa(Graql.var("type")),
                Graql.var("v").neq(Graql.var("v2")),
                Graql.var("type").not(Graql.var("type2").var())
        );
        Set<Pattern> outputs = Operators.fuzzVariables().apply(input, ctx).collect(Collectors.toSet());
        outputs.forEach(output -> {
            assertNotEquals(input, output);
            assertFalse(Sets.difference(input.variables(), output.variables()).isEmpty());
        });
    }

    @Test
    public void whenApplyingVariableFuzzyingOperator_atLeastOneIdIsFuzzed(){
        List<String> inputIds = Lists.newArrayList("V123", "V456");
        Pattern input = and(
                var("x").id(inputIds.get(0)),
                var("y").id(inputIds.get(1))
        );
        Set<Pattern> output = Operators.fuzzIds().apply(input, ctx).collect(Collectors.toSet());
        Set<Pattern> output2 = output.stream().flatMap(p -> Operators.fuzzIds().apply(p, ctx)).collect(Collectors.toSet());
        Stream.concat(output.stream(), output2.stream()).forEach(o -> assertTrue(
                o.statements().stream()
                        .flatMap(s -> s.properties().stream())
                        .filter(p -> p instanceof IdProperty)
                        .map(IdProperty.class::cast)
                        .map(IdProperty::id)
                        .anyMatch(id -> !inputIds.contains(id))
        ));
        assertNotEquals(Sets.newHashSet(input), output);
        assertNotEquals(output, output2);
    }

    private <T extends VarProperty> T getProperty(Pattern src, Class<T> type){
        return src.statements().stream()
                .map(s -> s.getProperty(type))
                .filter(Optional::isPresent)
                .map(Optional::get)
                .findFirst().orElse(null);
    }
    
    private void testOperatorConvergence(Pattern input, List<Operator> ops) {
        Set<Pattern> output = Sets.newHashSet(input);
        while (!output.isEmpty()){
            Stream<Pattern> pstream = output.stream();
            for(Operator op : ops){
                pstream = pstream.flatMap(p -> op.apply(p, ctx));
            }
            output = pstream.collect(Collectors.toSet());
        }
        assertTrue(true);
    }
}
