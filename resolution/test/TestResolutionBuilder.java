package grakn.verification.resolution.test;

import grakn.verification.resolution.kbtest.ResolutionBuilder;
import graql.lang.Graql;
import graql.lang.statement.Statement;
import org.junit.Test;

import java.util.HashSet;
import java.util.Set;

import static com.google.common.collect.Iterables.getOnlyElement;
import static grakn.verification.resolution.common.Utils.getStatements;
import static grakn.verification.resolution.kbtest.ResolutionBuilder.statementToProperties;
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
    public void testStatementToPropertiesForVariableAttributeOwnership() {
        Statement statement = getOnlyElement(Graql.parsePattern("$transaction has currency $currency;").statements());

        Statement expectedPropsStatement = getOnlyElement(Graql.parsePattern("$a0 (owner: $transaction) isa has-attribute-property, has currency $currency;").statements());

        Statement propsStatement = getOnlyElement(statementToProperties(statement, 'a').values());

        assertEquals(expectedPropsStatement, propsStatement);
    }

    @Test
    public void testStatementToPropertiesForAttributeOwnership() {
        Statement statement = getOnlyElement(Graql.parsePattern("$transaction has currency \"GBP\";").statements());

        Statement expectedPropsStatement = getOnlyElement(Graql.parsePattern("$a0 (owner: $transaction) isa has-attribute-property, has currency \"GBP\";").statements());

        Statement propsStatement = getOnlyElement(statementToProperties(statement, 'a').values());

        assertEquals(expectedPropsStatement, propsStatement);
    }

    @Test
    public void testStatementToPropertiesForRelation() {
        Statement statement = getOnlyElement(Graql.parsePattern("$locates (locates_located: $transaction, locates_location: $country);").statements());

        Set<Statement> expectedPropsStatements = getStatements(Graql.parsePatternList("" +
                "$a0 (rel: $locates, roleplayer: $transaction) isa relation-property, has role-label \"locates_located\";" +
                "$a1 (rel: $locates, roleplayer: $country) isa relation-property, has role-label \"locates_location\";"
        ));

        Set<Statement> propsStatements = new HashSet<>(statementToProperties(statement, 'a').values());

        assertEquals(expectedPropsStatements, propsStatements);
    }

    @Test
    public void testStatementToPropertiesForIsa() {
        Statement statement = getOnlyElement(Graql.parsePattern("$transaction isa transaction;").statements());
        Statement propStatement = getOnlyElement(statementToProperties(statement, 'a').values());
        Statement expectedPropStatement = getOnlyElement(Graql.parsePattern("$a0 (instance: $transaction) isa isa-property, has type-label \"transaction\";").statements());
        assertEquals(expectedPropStatement, propStatement);
    }

    @Test
    public void testStatementsForRuleApplication() {

        Set<Statement> whenStatements = getStatements(Graql.parsePatternList("" +
                "$country isa country; " +
                "$transaction isa transaction;" +
                "$country has currency $currency; " +
                "$locates (locates_located: $transaction, locates_location: $country) isa locates; "
        ));

        Set<Statement> thenStatements = getStatements(Graql.parsePatternList("" +
                "$transaction has currency $currency; "
        ));

        Set<Statement> expectedStatements = getStatements(Graql.parsePatternList("" +
                "$a0 (instance: $country) isa isa-property, has type-label \"country\";" +
                "$b0 (instance: $transaction) isa isa-property, has type-label \"transaction\";" + //TODO When inserted, the supertype labels should be owned too
                // TODO Should we also have an isa-property for $currency?
                "$c0 (owner: $country) isa has-attribute-property, has currency $currency;" +

                "$d0 (rel: $locates, roleplayer: $transaction) isa relation-property, has role-label \"locates_located\";" + //TODO When inserted, the role supertype labels should be owned too
                "$d1 (rel: $locates, roleplayer: $country) isa relation-property, has role-label \"locates_location\";" +
                "$d2 (instance: $locates) isa isa-property, has type-label \"locates\";" +

                "$e0 (owner: $transaction) isa has-attribute-property, has currency $currency;" +

                "$_ (\n" +
                "    body: $a0,\n" +
                "    body: $b0,\n" +
                "    body: $c0,\n" +
                "    body: $d0,\n" +
                "    body: $d1,\n" +
                "    body: $d2,\n" +
                "    head: $e0\n" +
                ") isa inference, \n" +
                "has rule-label \"transaction-currency-is-that-of-the-country\";"));  //TODO can be split into conjunction

        Set<Statement> appliedRuleStatements;

        appliedRuleStatements = new ResolutionBuilder().inferenceStatements(whenStatements, thenStatements, "transaction-currency-is-that-of-the-country");
        assertEquals(expectedStatements, appliedRuleStatements);
    }
}
