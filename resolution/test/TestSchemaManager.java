package grakn.verification.resolution.test;

import grakn.client.GraknClient;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.TimeoutException;
import java.util.stream.Collectors;

import static grakn.verification.resolution.common.Utils.loadGqlFile;
import static grakn.verification.resolution.kbcomplete.SchemaManager.addResolutionSchema;
import static grakn.verification.resolution.kbcomplete.SchemaManager.defineThatAllThingsCanBePartOfAClause;
import static org.junit.Assert.assertEquals;

public class TestSchemaManager {

    private static final String GRAKN_URI = "localhost:48555";
    private static final String GRAKN_KEYSPACE = "case2";
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
                Path schemaPath = Paths.get("resolution", "cases", "case2", "schema.gql").toAbsolutePath();
                Path dataPath = Paths.get("resolution", "cases", "case2", "data.gql").toAbsolutePath();
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
    public void testResolutionSchemaRolesPlayedAreCorrect() {

        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {
            try (GraknClient.Transaction tx = session.transaction().write()) {

                addResolutionSchema(session);
                defineThatAllThingsCanBePartOfAClause(tx);

                GraqlGet roleplayersQuery = Graql.match(Graql.var("x").plays("clause-element")).get();

                Set<String> roleplayers = tx.stream(roleplayersQuery).map(r -> r.get("x").asType().label().toString()).collect(Collectors.toSet());

                HashSet<String> expectedRoleplayers = new HashSet<String>() {
                    {
                        add("transaction");
                        add("locates");
                        add("location-hierarchy");
                        add("location");
                        add("country");
                        add("city");
                    }
                };

                assertEquals(expectedRoleplayers, roleplayers);
            }
        }

    }

    @Test
    public void testResolutionSchemaAttributesOwnedAreCorrect() {

        try (GraknClient.Session session = graknClient.session(GRAKN_KEYSPACE)) {
            try (GraknClient.Transaction tx = session.transaction().write()) {

                addResolutionSchema(session);
                defineThatAllThingsCanBePartOfAClause(tx);

                GraqlGet clauseAttributesQuery = Graql.match(Graql.var("x").sub("clause-containment")).get();

                Set<String> attributeTypes = tx.execute(clauseAttributesQuery).get(0).get("x").asRelationType().attributes().map(a -> a.label().toString()).collect(Collectors.toSet());

                HashSet<String> expectedAttributeTypes = new HashSet<String>() {
                    {
                        add("currency");
                        add("location-id");
                        add("transaction-id");
                        add("hierarchy-id");
                        add("country-name");
                        add("city-name");
                    }
                };

                assertEquals(expectedAttributeTypes, attributeTypes);
            }
        }

    }
}
