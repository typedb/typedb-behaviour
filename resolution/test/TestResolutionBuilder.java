package grakn.verification.resolution.test;

import grakn.verification.resolution.kbtest.ResolutionBuilder;
import graql.lang.Graql;
import graql.lang.statement.Statement;
import graql.lang.statement.Variable;
import org.junit.Test;

import java.util.LinkedHashSet;
import java.util.Set;

import static grakn.verification.resolution.common.Utils.getStatements;
import static org.junit.Assert.assertEquals;

public class TestResolutionBuilder {

    @Test
    public void testIdStatementsAreRemovedCorrectly() {
        Set<Statement> statementsWithIds = getStatements(Graql.parsePatternList(
                "$transaction has currency $currency;\n" +
                        "$transaction id V86232;\n" +
                        "$currency id V36912;\n" +
                        "$transaction isa transaction;\n"
        ));

        Set<Statement> expectedStatements = getStatements(Graql.parsePatternList(
                "$transaction has currency $currency;\n" +
                        "$transaction isa transaction;\n"
        ));

        Set<Statement> statementsWithoutIds = ResolutionBuilder.removeIdStatements(statementsWithIds);

        assertEquals(expectedStatements, statementsWithoutIds);
    }

    @Test
    public void testStatementsForRuleApplication() {
        Set<Statement> expectedStatements = getStatements(Graql.parsePatternList("$_ (\n" +
                "                       where: $transaction,\n" +
                "                       where: $country,\n" +
                "                       where: $locates,\n" +
                "                       where: $currency,\n" +
                "                       there: $currency,\n" +
                "                       there: $transaction\n" +
                "                   ) isa applied-rule, \n" +
                "                   has rule-label \"transaction-currency-is-that-of-the-country\";"));  //TODO can be split into conjunction

        Set<Statement> appliedRuleStatements;

        LinkedHashSet<Variable> whenVars = new LinkedHashSet<Variable>() {
            {
                add(new Variable("transaction"));
                add(new Variable("country"));
                add(new Variable("locates"));
                add(new Variable("currency"));
            }
        };

        LinkedHashSet<Variable> thenVars = new LinkedHashSet<Variable>() {
            {
                add(new Variable("currency"));
                add(new Variable("transaction"));
            }
        };

        appliedRuleStatements = ResolutionBuilder.appliedRuleStatement(whenVars, thenVars, "transaction-currency-is-that-of-the-country");
        assertEquals(expectedStatements, appliedRuleStatements);
    }
}
