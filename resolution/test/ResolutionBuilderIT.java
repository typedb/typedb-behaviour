package grakn.verification.resolution.test;

import grakn.client.GraknClient;
import grakn.client.answer.ConceptMap;
import grakn.verification.resolution.kbtest.ResolutionBuilder;
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
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeoutException;

import static grakn.verification.resolution.common.Utils.getStatements;
import static grakn.verification.resolution.common.Utils.loadGqlFile;
import static org.junit.Assert.assertEquals;

public class ResolutionBuilderIT {

//      Case 1
//    String inferenceQuery = "match $ar isa area, has name $ar-name; $cont isa continent, has name $cont-name; $lh(location-hierarchy_superior: $cont, location-hierarchy_subordinate: $ar) isa location-hierarchy; get;";

//    getStatements(Graql.parsePatternList(
////                    From the initial answer:
//                    "$transaction has currency $currency;\n" +
//                    "$transaction has transaction-id 0;\n" +
//                    "$currency \"GBP\";\n" +
//                    "$transaction isa transaction;\n" +
//
////                    From the explained answers:
//                    "$country has currency $currency;\n" +
//                    "$country isa country;\n" +
//                    "$country has country-name \"UK\";\n" +
//                    "$currency \"GBP\";\n" +
//
//                    "$lh (location-hierarchy_superior: $country, location-hierarchy_subordinate: $city) isa location-hierarchy;\n" +
//                    "$country isa country;\n" +
//                    "$city has city-name \"London\";\n" +
//                    "$country has country-name \"UK\";\n" +
//                    "$city isa city;\n" +
//                    "$lh has hierarchy-id 0;\n" +
//
//                    "$city has city-name \"London\";\n" +
//                    "$transaction has transaction-id 0;\n" +
//                    "$l1 (locates_located: $transaction, locates_location: $city) isa locates;\n" +
//                    "$l1 has location-id 0;\n" +
//                    "$city isa city;\n" +
//                    "$transaction isa transaction;\n" +
//
//                    "$country isa country;\n" +
//                    "$locates (locates_located: $transaction, locates_location: $country) isa locates;\n" +
//                    "$transaction has transaction-id 0;\n" +
//                    "$country has country-name \"UK\";\n" +
//                    "$transaction isa transaction;\n" +
//
////                            new
//                    "$a0 (instance: $country) isa isa-property, has type-label \"country\";" +
//                    "$b0 (instance: $transaction) isa isa-property, has type-label \"transaction\";" +
//                    "$c0 (owner: $country) isa has-attribute-property, has currency $currency;" +
//
//                    "$d0 (rel: $locates, roleplayer: $transaction) isa relation-property, has role-label \"locates_located\";" +
//                    "$d1 (rel: $locates, roleplayer: $country) isa relation-property, has role-label \"locates_location\";" +
//                    "$d2 (instance: $locates) isa isa-property, has type-label \"locates\";" +
//
//                    "$e0 (owner: $transaction) isa has-attribute-property, has currency $currency;" +
//
//                    "$_ (\n" +
//                    "    body: $a0,\n" +
//                    "    body: $b0,\n" +
//                    "    body: $c0,\n" +
//                    "    body: $d0,\n" +
//                    "    body: $d1,\n" +
//                    "    body: $d2,\n" +
//                    "    head: $e0\n" +
//                    ") isa inference, \n" +
//                    "has rule-label \"transaction-currency-is-that-of-the-country\";" +
////                            new above
//
//                    "$f0 (instance: $city) isa isa-property, has type-label \"city\";" +
//                    "$g0 (instance: $country) isa isa-property, has type-label \"country\";" +
//
//                    "$h0 (rel: $lh, roleplayer: $city) isa relation-property, has role-label \"location-hierarchy_subordinate\";" +
//                    "$h1 (rel: $lh, roleplayer: $country) isa relation-property, has role-label \"location-hierarchy_superior\";" +
//                    "$h2 (instance: $lh) isa isa-property, has type-label \"location-hierarchy\";" +
//
//                    "$i0 (rel: $l1, roleplayer: $transaction) isa relation-property, has role-label \"locates_located\";" +
//                    "$i1 (rel: $l1, roleplayer: $city) isa relation-property, has role-label \"locates_location\";" +
//                    "$i2 (instance: $l1) isa isa-property, has type-label \"locates\";" +
//
//                    "$j0 (rel: $k1, roleplayer: $transaction) isa relation-property, has role-label \"locates_located\";" +
//                    "$j1 (rel: $k1, roleplayer: $country) isa relation-property, has role-label \"locates_location\";" +
//                    "$j2 (instance: $k1) isa isa-property, has type-label \"locates\";" +  //TODO isa property is a problem if there's no variable
//
//                    "$_ (\n" +
//                    "    where: $country,\n" +
//                    "    where: $city,\n" +
//                    "    where: $lh,\n" +
//                    "    where: $l1,\n" +
//                    "    where: $transaction,\n" +
//                    "    there: $country,\n" +
//                    "    there: $locates,\n" +
//                    "    there: $transaction\n" +
//                    ") isa applied-rule, \n" +
//                    "has rule-label \"locates-is-transitive\";\n"
//    ));

//    private static Set<Statement> expectedResolutionStatements = getStatements(Graql.parsePatternList(
//            "$c has is-liable $l;" +
//
//            // Rule 1
//            "$c isa company, has name \"the-company\";" +
////            "$c isa company, has name $1234;" +
////            "$1234 \"the-company\";" +
////            "$x id V1234" + // Removed
//            "$x isa company, has company-id 0;" +
////            "$c has is-liable true;" +
//            "$l true;" +
//
//            "$a0 (instance: $l) isa isa-property, has type-label \"is-liable\";" + //TODO Attributes can't be related to in an isa-property
//            "$b0 (instance: $c) isa isa-property, has type-label \"company\";" +
//            "$c0 (instance: $1234) isa isa-property, has type-label \"name\";" +
//
//
//            // Rule 2
//            "$c isa company;"
//
//    ));

    private static Set<Statement> expectedResolutionStatements = getStatements(Graql.parsePatternList("" +
            "$c has is-liable $l;\n" +
            "$l true; $c0 (owner: $c) isa has-attribute-property, has name $1585307066008185;\n" +
            "$c has company-id 0;\n" +
            "$1585307066008185 == \"the-company\";\n" +
            "$d0 (owner: $c) isa has-attribute-property, has is-liable $l;\n" +
            "$_ (body: $c0, head: $d0) isa inference, has rule-label \"company-is-liable\";\n" +
            "$c has name $1585307066008185;\n" +
            "$1585307066008159 \"the-company\";\n"
    ));

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
                Path schemaPath = Paths.get("resolution", "cases", "case4", "schema.gql").toAbsolutePath();
                Path dataPath = Paths.get("resolution", "cases", "case4", "data.gql").toAbsolutePath();
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
    public void testQueryIsCorrect() {
//        GraqlGet inferenceQuery = Graql.parse("match $transaction isa transaction, has currency $currency; get;");
//        GraqlGet inferenceQuery = Graql.parse("match $s(sibling: $p, sibling: $p1) isa siblingship; $p1 != $p; get;");
        GraqlGet inferenceQuery = Graql.parse("match $c has is-liable $l; get;");

        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {
            ResolutionBuilder qb = new ResolutionBuilder();
            try (GraknClient.Transaction tx = session.transaction().read()) {
                List<GraqlGet> kbCompleteQueries = qb.build(tx, inferenceQuery);
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
                keyStatements = ResolutionBuilder.generateKeyStatements(answer.map());
            }
        }

        Set<Statement> expectedStatements = getStatements(Graql.parsePatternList(
                "$transaction has transaction-id 0;\n" +
                        "$currency \"GBP\";\n"
        ));

        assertEquals(expectedStatements, keyStatements);
    }
}