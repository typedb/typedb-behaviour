package grakn.verification.resolution.test;

import grakn.client.GraknClient;
import grakn.client.answer.ConceptMap;
import grakn.verification.resolution.complete.Completer;
import grakn.verification.resolution.complete.SchemaManager;
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

public class TestCompleter {

    static Set<Statement> expectedResolutionStatements = getStatements(Graql.parsePatternList(
//                    From the initial answer:
            "$transaction has currency $currency;\n" +
                    "$transaction has transaction-id 0;\n" +
                    "$currency \"GBP\";\n" +
                    "$transaction isa transaction;\n" +

//                    From the explained answers:
                    "$country has currency $currency;\n" +
                    "$country isa country;\n" +
                    "$country has country-name \"UK\";\n" +
                    "$currency \"GBP\";\n" +

                    "$lh (location-hierarchy_superior: $country, location-hierarchy_subordinate: $city) isa location-hierarchy;\n" +
                    "$country isa country;\n" +
                    "$city has city-name \"London\";\n" +
                    "$country has country-name \"UK\";\n" +
                    "$city isa city;\n" +
                    "$lh has hierarchy-id 0;\n" +

                    "$city has city-name \"London\";\n" +
                    "$transaction has transaction-id 0;\n" +
                    "$l1 (locates_located: $transaction, locates_location: $city) isa locates;\n" +
                    "$l1 has location-id 0;\n" +
                    "$city isa city;\n" +
                    "$transaction isa transaction;\n" +

                    "$country isa country;\n" +
                    "$locates (locates_located: $transaction, locates_location: $country) isa locates;\n" +
                    "$transaction has transaction-id 0;\n" +
                    "$country has country-name \"UK\";\n" +
                    "$transaction isa transaction;\n" +

                    "$_ (\n" +
                    "    where: $country,\n" +
                    "    where: $locates,\n" +
                    "    where: $transaction,\n" +
                    "    where: $currency,\n" +
                    "    there: $currency,\n" +
                    "    there: $transaction\n" +
                    ") isa applied-rule, \n" +
                    "has rule-label \"transaction-currency-is-that-of-the-country\";" +

                    "$_ (\n" +
                    "    where: $country,\n" +
                    "    where: $city,\n" +
                    "    where: $lh,\n" +
                    "    where: $l1,\n" +
                    "    where: $transaction,\n" +
                    "    there: $country,\n" +
                    "    there: $locates,\n" +
                    "    there: $transaction\n" +
                    ") isa applied-rule, \n" +
                    "has rule-label \"locates-is-transitive\";\n"
    ));

    private static final String TEST_CASE = "case1";
    private static final String GRAKN_URI = "localhost:48555";
    private static final String GRAKN_KEYSPACE = TEST_CASE;
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
                Path schemaPath = Paths.get("resolution", "test", "cases", TEST_CASE, "schema.gql").toAbsolutePath();
                Path dataPath = Paths.get("resolution", "test", "cases", TEST_CASE, "data.gql").toAbsolutePath();
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

//    @Test
//    public void testValidResolutionHasExactlyOneAnswer() {
//
//        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {
//
//            try (GraknClient.Transaction tx = session.transaction().read()) {
//                List<ConceptMap> answers = tx.execute(Graql.match(expectedResolutionStatements).get());
//
//                assertEquals(answers.size(), 1);
//            }
//        }
//    }

    @Test
    public void testCompletionInferredTheCorrectNumberOfConcepts() {
        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {
            Completer completer = new Completer(session);
            try (GraknClient.Transaction tx = session.transaction().write()) {
                completer.loadRules(tx, SchemaManager.getAllRules(tx));
            }

            SchemaManager.undefineAllRules(session);
            SchemaManager.addResolutionSchema(session);
            SchemaManager.connectResolutionSchema(session);
            completer.complete();

            try (GraknClient.Transaction tx = session.transaction().read()) {

                GraqlGet inferredAnswersQuery = Graql.match(Graql.var("lh").isa("location-hierarchy")).get();
                List<ConceptMap> inferredAnswers = tx.execute(inferredAnswersQuery);
                assertEquals(6, inferredAnswers.size());

                GraqlGet resolutionsQuery = Graql.match(Graql.var("res").isa("resolution")).get();
                List<ConceptMap> resolutionAnswers = tx.execute(resolutionsQuery);
                assertEquals(4, resolutionAnswers.size());
            }
        }
    }
}