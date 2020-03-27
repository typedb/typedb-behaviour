package grakn.verification.resolution.test;

import grakn.client.GraknClient;
import grakn.client.answer.ConceptMap;
import grakn.verification.resolution.resolve.QueryBuilder;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;
import graql.lang.statement.Statement;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeoutException;

import static grakn.verification.resolution.common.Utils.getStatements;
import static grakn.verification.resolution.common.Utils.loadGqlFile;
import static org.junit.Assert.assertEquals;

public class QueryBuilderIT {

    private static final String GRAKN_URI = "localhost:48555";
    private static final String GRAKN_KEYSPACE = "case4";
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

    @Before
    public void before() {
        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {
            try {
                Path schemaPath = Paths.get("resolution", "test", "cases", "case4", "schema.gql").toAbsolutePath();
                Path dataPath = Paths.get("resolution", "test", "cases", "case4", "data.gql").toAbsolutePath();
                // Load a schema incl. rules
                loadGqlFile(session, schemaPath);
                // Load data
                loadGqlFile(session, dataPath);
            } catch (IOException e) {
                e.printStackTrace();
                System.exit(1);
            }
        }
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
                "$_ (body: $x0, head: $x1) isa inference, has rule-label \"company-is-liable\";\n"
        ));

        GraqlGet inferenceQuery = Graql.parse("match $c has is-liable $l; get;");

        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {
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