package grakn.verification.resolution.test;

import grakn.client.GraknClient;
import grakn.client.answer.ConceptMap;
import grakn.verification.resolution.kbtest.ResolutionBuilder;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;
import graql.lang.statement.Statement;
import org.junit.Test;

import java.util.Set;

import static grakn.verification.resolution.common.Utils.getStatements;
import static org.junit.Assert.assertEquals;

public class TestResolutionBuilder {

    @Test
    public void testKeysStatementsAreGeneratedCorrectly() {
        String graknHostUri = "localhost:48555";
        String graknKeyspace = "case2";

        GraqlGet inferenceQuery = Graql.parse("match $transaction isa transaction, has currency $currency; get;");

        GraknClient grakn = new GraknClient(graknHostUri);

        Set<Statement> keyStatements;

        try (GraknClient.Session session = grakn.session(graknKeyspace)) {
            try (GraknClient.Transaction tx = session.transaction().read()) {
                //            try {
//                // Load a schema incl. rules
//                loadGqlFile(session, SCHEMA_PATH_2);
//                // Load data
//                loadGqlFile(session, DATA_PATH_2);
//            } catch (IOException e) {
//                e.printStackTrace();
//                System.exit(1);
//            }
                ConceptMap answer = tx.execute(inferenceQuery).get(0);

                keyStatements = ResolutionBuilder.generateKeyStatements(answer.map());
            }
        }

        Set<Statement> expectedStatements = getStatements(Graql.parsePatternList(
                "$transaction has transaction-id 0;\n" +
                "$currency \"GBP\";\n"
        ));

        assertEquals(expectedStatements, keyStatements);
    }

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
}
