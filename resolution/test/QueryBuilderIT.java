package grakn.verification.resolution.test;

import grakn.client.GraknClient;
import grakn.client.answer.ConceptMap;
import grakn.verification.resolution.resolve.QueryBuilder;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;
import graql.lang.statement.Statement;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeoutException;

import static grakn.verification.resolution.common.Utils.getStatements;
import static grakn.verification.resolution.test.GraknForTest.loadTestCase;
import static org.junit.Assert.assertEquals;

public class QueryBuilderIT {

    private static final String GRAKN_URI = "localhost:48555";
    private static final String GRAKN_KEYSPACE = "query_builder_it";
    private static GraknForTest graknForTest;
    private static GraknClient graknClient;

    @BeforeClass
    public static void beforeClass() throws InterruptedException, IOException, TimeoutException {
        Path graknArchive = Paths.get("external", "graknlabs_grakn_core", "grakn-core-all-linux.tar.gz");
        graknForTest = new GraknForTest(graknArchive);
        graknForTest.start();
        graknClient = new GraknClient(GRAKN_URI);
    }

    @AfterClass
    public static void afterClass() throws InterruptedException, IOException, TimeoutException {
        graknForTest.stop();
    }

    @After
    public void after() {
        graknClient.keyspaces().delete(GRAKN_KEYSPACE);
    }

    @Test
    public void testMatchGetQueryIsCorrect() {
        Set<Statement> expectedResolutionStatements = getStatements(Graql.parsePatternList("" +
                "$c has is-liable $l;\n" +
                "$c has company-id 0;\n" +
                "$l true;\n" +
                "$1585311102487185 == \"the-company\";\n" +
                "$c has name $1585311102487185;\n" +
                "$1585311102487159 \"the-company\";\n" +
                "$x0 (owner: $c) isa has-attribute-property, has name $1585311102487185;\n" +
                "$x1 (owner: $c) isa has-attribute-property, has is-liable $l;\n" +
                "$_ (body: $x0, head: $x1) isa resolution, has rule-label \"company-is-liable\";\n"
        ));

        GraqlGet inferenceQuery = Graql.parse("match $c has is-liable $l; get;");

        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {

            loadTestCase(session, "case4");

            QueryBuilder qb = new QueryBuilder();
            try (GraknClient.Transaction tx = session.transaction().read()) {
                List<GraqlGet> kbCompleteQueries = qb.buildMatchGet(tx, inferenceQuery);
                GraqlGet kbCompleteQuery = kbCompleteQueries.get(0);
                Set<Statement> statements = kbCompleteQuery.match().getPatterns().statements();

                assertEquals(expectedResolutionStatements, statements);
            }
        }
    }

    @Test
    public void testMatchGetQueryIsCorrect_case5() {

        Set<Statement> expectedResolutionStatements = getStatements(Graql.parsePatternList("" +
                "$c has name $n;\n" +
                "$c has company-id 0;\n" +
                "$n \"the-company\";\n" +
                "$c has name $sub1;\n" +
                "$sub1 == \"the-company\";\n" +
                "$c isa company;\n" +
                "$x0 (instance: $c) isa isa-property, has type-label \"company\";\n" +
                "$x1 (owner: $c) isa has-attribute-property, has name $sub1;\n" +
                "$_ (body: $x0, head: $x1) isa resolution, has rule-label \"company-has-name\";\n"
        ));

        GraqlGet inferenceQuery = Graql.parse("match $com has name $n; get;");

        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {

            loadTestCase(session, "case5");

            QueryBuilder qb = new QueryBuilder();
            try (GraknClient.Transaction tx = session.transaction().read()) {
                List<GraqlGet> kbCompleteQueries = qb.buildMatchGet(tx, inferenceQuery);
                GraqlGet kbCompleteQuery = kbCompleteQueries.get(0);
                Set<Statement> statements = kbCompleteQuery.match().getPatterns().statements();

                assertEquals(expectedResolutionStatements, statements);
            }
        }
    }

    @Test
    public void testKeysStatementsAreGeneratedCorrectly() {
        GraqlGet inferenceQuery = Graql.parse("match $transaction isa transaction, has currency $currency; get;");

        Set<Statement> keyStatements;

        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {

            loadTestCase(session, "case2");

            try (GraknClient.Transaction tx = session.transaction().read()) {
                ConceptMap answer = tx.execute(inferenceQuery).get(0);
                keyStatements = QueryBuilder.generateKeyStatements(answer.map());
            }
        }

        Set<Statement> expectedStatements = getStatements(Graql.parsePatternList(
                "$transaction has transaction-id 0;\n" +
                        "$currency \"GBP\";\n"
        ));

        assertEquals(expectedStatements, keyStatements);
    }
}